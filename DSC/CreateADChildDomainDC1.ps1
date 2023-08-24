﻿configuration CreateADChildDomainDC1
{
   param
   (
        [Parameter(Mandatory)]
        [String]$ParentDomainName,
 
        [Parameter(Mandatory)]
        [String]$ChildDomainName,

        [Parameter(Mandatory)]
        [String]$DnsForwarder,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,
        
        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    )

    Import-DscResource -ModuleName xActiveDirectory, xStorage, xNetworking, ComputerManagementDSC
    
    [PSCredential]$ParentDomainCreds = New-Object System.Management.Automation.PSCredential ("${ParentDomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    [PSCredential]$ChildDomainCreds = New-Object System.Management.Automation.PSCredential ("${ChildDomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    $Interface = Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Select-Object -First 1
    $InterfaceAlias = $($Interface.Name)

    Node localhost
    {
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }
        
        WindowsFeature DNS
        {
            Ensure = "Present"
            Name = "DNS"
        }
        
        WindowsFeature DnsTools
        {
            Ensure = "Present"
            Name = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]DNS"
        }
        
        Script SetDNSForwarder
        {
            #
            # 
            #
            SetScript =
            {
                $dnsrunning = $false
                $triesleft = $Using:RetryCount
                Write-Verbose -Verbose "Checking if DNS service is running."
                While (-not $dnsrunning -and ($triesleft -gt 0))
                {
                    $triesleft--
                    try
                    {
                        $dnsrunning = (Get-Service -name dns).Status -eq "running"
                    } catch {
                        $dnsrunning = $false
                    }
                    if (-not $dnsrunning)
                    {
                        Write-Verbose -Verbose "Waiting $($Using:RetryIntervalSec) seconds for DNS service to start"
                        Start-Sleep -Seconds $Using:RetryIntervalSec
                    }
                }

                $triesleft = $Using:RetryCount
                Write-Verbose "Checking if DNS is responding to WMI."
                do {
                    #
                    # Get-DNSForwarderList would sometimes hang directly after boot.
                    # So, try something with a reasonable timeout first.
                    #
                    try {
                        Write-Verbose -Verbose "Reading DNS through WMI to see if it responds."
                        $dnsObject = Get-CimInstance -ClassName microsoftdns_server -Namespace root/microsoftdns -OperationTimeoutSec 10
                    } catch {
                        $dnsobject = $false
                        Write-Warning -Verbose "Get-Ciminstance for DNS failed: $_"
                    }
                    if ($dnsObject)
                    {
                        $dnsrunning = $true
                    } else {
                        $dnsrunning = $false
                        Write-Verbose -Verbose "Waiting $($Using:RetryIntervalSec) seconds for WMI starting to respond"
                        Start-Sleep -Seconds $Using:RetryIntervalSec
                    }
                    $triesleft--
                } while (-not $dnsrunning -and ($triesleft -gt 0))

                if (-not $dnsrunning)
                {
                    Write-Warning "DNS service is not running, cannot edit forwarder. Template deployment will fail."
                    # but continue anyway.
                }
                try {
                    Write-Verbose -Verbose "Getting list of DNS forwarders"
                    $forwarderlist = Get-DnsServerForwarder
                    if ($forwarderlist.IPAddress)
                    { 
                        Write-Verbose -Verbose "Removing forwarders"
                        Remove-DnsServerForwarder -IPAddress $forwarderlist.IPAddress -Force
                    } else {
                        Write-Verbose -Verbose "No forwarders found"
                    }
                } catch {
                    Write-Warning -Verbose "Exception running Remove-DNSServerForwarder: $_"
                }
                try {
                    Write-Verbose -Verbose "setting  forwarder to $($using:DNSForwarder)"
                    Set-DnsServerForwarder -IPAddress $using:DNSForwarder
                } catch {
                    Write-Warning -Verbose "Exception running Set-DNSServerForwarder: $_"
                }                 
            }
            GetScript =  { @{} }
            TestScript = { $false }
            DependsOn = "[WindowsFeature]DNSTools"
        }
      
        WindowsFeature ADTools
        {
            Ensure = "Present"
            Name = "RSAT-AD-Tools"
            DependsOn = "[WindowsFeature]DNS"
        }
        
        WindowsFeature GPOTools
        {
            Ensure = "Present"
            Name = "GPMC"
            DependsOn = "[WindowsFeature]DNS"
        }

        WindowsFeature DFSTools
        {
            Ensure = "Present"
            Name = "RSAT-DFS-Mgmt-Con"
            DependsOn = "[WindowsFeature]DNS"
        }       
                
        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name = "AD-Domain-Services"
            DependsOn = "[WindowsFeature]DNS"
        }
        
        #
        # mount disk, reboot if needed.
        #
        xWaitforDisk Disk2
        {
            DiskId = 2
            RetryIntervalSec = $RetryIntervalSec
            RetryCount = $RetryCount
        }
 
        xDisk DiskF
        {
            DiskId = 2
            DriveLetter = 'F'
            DependsOn = '[xWaitforDisk]Disk2'
        }

        PendingReboot AfterMountingDisk
        {
            Name = 'AfterMountingDisk'
            DependsOn = @('[WindowsFeature]ADDSInstall','[xDisk]DiskF')
        }        

        #
        # This is where we expect to resolve the parent domain AND Internet.
        #
        xDnsServerAddress DnsServerAddress
        {
            Address        = $DnsForwarder
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = 'IPv4'
            DependsOn = "[WindowsFeature]DNS"
        }
               
        xWaitForADDomain DscForestWait
        {
            DomainName = $ParentDomainName
            DomainUserCredential= $ParentDomainCreds
            RetryCount = $RetryCount
            RetryIntervalSec = $RetryIntervalSec
            DependsOn = @("[WindowsFeature]ADDSInstall", "[xDnsServerAddress]DnsServerAddress", "[Script]SetDNSForwarder", "[PendingReboot]AfterMountingDisk")
        }      
        
        xADDomain FirstDS
        {
            DomainName = $ChildDomainName
            ParentDomainName = $ParentDomainName
            DomainAdministratorCredential = $ParentDomainCreds
            SafemodeAdministratorPassword = $AdminCreds
            DnsDelegationCredential = $ParentDomainCreds
            DatabasePath = "F:\NTDS"
            LogPath = "F:\NTDS"
            SysvolPath = "F:\SYSVOL"
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }
        
        #
        # Force the reboot; the automatic reboot stopped working somewhere in 2019... 
        #
        PendingReboot RebootAfterInstallingAD
        {
            Name = 'RebootAfterInstallingAD'
            DependsOn = "[xADDomain]FirstDS"
        }
    }
}