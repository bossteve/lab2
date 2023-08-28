configuration ConfigureADNextDC
{
   param
    (
        [Parameter(Mandatory)]
        [String]$DomainName,
        
        [Parameter(Mandatory)]
        [String]$DNSServer,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    )

    Import-DscResource -ModuleName xStorage
    Import-DscResource -ModuleName xNetworking
    Import-DscResource -ModuleName ComputerManagementDSC
    Import-DscResource -ModuleName xActiveDirectory
   #  Import-DscResource -ModuleName xActiveDirectory, xStorage, xNetworking, ComputerManagementDSC

    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
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
        # Additional DCs must use another DC for DNS. 
        #
        xDnsServerAddress DnsServerAddress
        {
            Address        = $DNSServer
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = 'IPv4'    
            DependsOn = "[WindowsFeature]DNS"            
        }
        
        xWaitForADDomain DscForestWait
        {
            DomainName = $DomainName
            DomainUserCredential= $DomainCreds
            RetryCount = $RetryCount
            RetryIntervalSec = $RetryIntervalSec
            DependsOn = @("[WindowsFeature]ADDSInstall", "[xDnsServerAddress]DnsServerAddress", "[PendingReboot]AfterMountingDisk")
        }
        
        xADDomainController NextDC
        {
            DomainName = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath = "F:\NTDS"
            LogPath = "F:\NTDS"
            SysvolPath = "F:\SYSVOL"
            DependsOn = @("[xWaitForADDomain]DscForestWait", "[WindowsFeature]ADDSInstall")
        }
                
        #
        # Force the reboot; the automatic reboot stopped working somewhere in 2019... 
        #
        PendingReboot RebootAfterInstallingAD
        {
            Name = 'RebootAfterInstallingAD'
            DependsOn = "[xADDomainController]NextDC"
        }
    }
}
