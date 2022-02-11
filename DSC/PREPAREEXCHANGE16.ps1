configuration PREPAREEXCHANGE16
{
   param
   (
        [String]$ExchangeSASUrl,   
        [String]$TimeZone,           
        [String]$NetBiosDomain,
        [System.Management.Automation.PSCredential]$Admincreds
    )

    Import-DscResource -Module xPSDesiredStateConfiguration # Used for xRemoteFile
    Import-DscResource -Module ComputerManagementDsc # Used for TimeZone
    Import-DscResource -Module xStorage # Used by Disk
    Import-DscResource -Module xPendingReboot # Used for Reboots

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        Registry SchUseStrongCrypto
        {
            Key                         = 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319'
            ValueName                   = 'SchUseStrongCrypto'
            ValueType                   = 'Dword'
            ValueData                   =  '1'
            Ensure                      = 'Present'
        }

        Registry SchUseStrongCrypto64
        {
            Key                         = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319'
            ValueName                   = 'SchUseStrongCrypto'
            ValueType                   = 'Dword'
            ValueData                   =  '1'
            Ensure                      = 'Present'
        }

        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        Script DismountISO
        {
      	    SetScript = {
                Dismount-DiskImage "S:\ExchangeInstall\Exchange2016.iso" -ErrorAction 0
            }
            GetScript =  { @{} }
            TestScript = { $false }
        }

        #Exchange Prereqs
        WindowsFeature NET-WCF-HTTP-Activation45
        {
            Ensure = 'Present'
            Name = 'NET-WCF-HTTP-Activation45'
        }

        WindowsFeature NET-Framework-45-Features
        {
            Ensure = 'Present'
            Name = 'NET-Framework-45-Features'
        }

        WindowsFeature Server-Media-Foundation
        {
            Ensure = 'Present'
            Name = 'Server-Media-Foundation'
        }
        
        WindowsFeature RPC-over-HTTP-proxy
        {
            Ensure = 'Present'
            Name = 'RPC-over-HTTP-proxy'
        }
        
        WindowsFeature RSAT-Clustering
        {
            Ensure = 'Present'
            Name = 'RSAT-Clustering'
        }

        WindowsFeature RSAT-Clustering-CmdInterface
        {
            Ensure = 'Present'
            Name = 'RSAT-Clustering-CmdInterface'
        }

        WindowsFeature RSAT-Clustering-Mgmt
        {
            Ensure = 'Present'
            Name = 'RSAT-Clustering-Mgmt'
        }
        
        WindowsFeature RSAT-Clustering-PowerShell
        {
            Ensure = 'Present'
            Name = 'RSAT-Clustering-PowerShell'
        }
        
        WindowsFeature WAS-Process-Model
        {
            Ensure = 'Present'
            Name = 'WAS-Process-Model'
        }
        
        WindowsFeature Web-Asp-Net45
        {
            Ensure = 'Present'
            Name = 'Web-Asp-Net45'
        }
        
        WindowsFeature Web-Basic-Auth
        {
            Ensure = 'Present'
            Name = 'Web-Basic-Auth'
        }
        
        WindowsFeature Web-Client-Auth
        {
            Ensure = 'Present'
            Name = 'Web-Client-Auth'
        }
        
        WindowsFeature Web-Digest-Auth
        {
            Ensure = 'Present'
            Name = 'Web-Digest-Auth'
        }
        
        WindowsFeature Web-Dir-Browsing
        {
            Ensure = 'Present'
            Name = 'Web-Dir-Browsing'
        }
        
        WindowsFeature Web-Dyn-Compression
        {
            Ensure = 'Present'
            Name = 'Web-Dyn-Compression'
        }
        
        WindowsFeature Web-Http-Errors
        {
            Ensure = 'Present'
            Name = 'Web-Http-Errors'
        }
        
        WindowsFeature Web-Http-Logging
        {
            Ensure = 'Present'
            Name = 'Web-Http-Logging'
        }
        
        WindowsFeature Web-Http-Redirect
        {
            Ensure = 'Present'
            Name = 'Web-Http-Redirect'
        }
        
        WindowsFeature Web-Http-Tracing
        {
            Ensure = 'Present'
            Name = 'Web-Http-Tracing'
        }
        
        WindowsFeature Web-ISAPI-Ext
        {
            Ensure = 'Present'
            Name = 'Web-ISAPI-Ext'
        }
        
        WindowsFeature Web-ISAPI-Filter
        {
            Ensure = 'Present'
            Name = 'Web-ISAPI-Filter'
        }
        
        WindowsFeature Web-Lgcy-Mgmt-Console
        {
            Ensure = 'Present'
            Name = 'Web-Lgcy-Mgmt-Console'
        }
        
        WindowsFeature Web-Metabase
        {
            Ensure = 'Present'
            Name = 'Web-Metabase'
        }
        
        WindowsFeature Web-Mgmt-Console
        {
            Ensure = 'Present'
            Name = 'Web-Mgmt-Console'
        }
        
        WindowsFeature Web-Mgmt-Service
        {
            Ensure = 'Present'
            Name = 'Web-Mgmt-Service'
        }
        
        WindowsFeature Web-Net-Ext45
        {
            Ensure = 'Present'
            Name = 'Web-Net-Ext45'
        }
        
        WindowsFeature Web-Request-Monitor
        {
            Ensure = 'Present'
            Name = 'Web-Request-Monitor'
        }
        
        WindowsFeature Web-Server
        {
            Ensure = 'Present'
            Name = 'Web-Server'
        }
        
        WindowsFeature Web-Stat-Compression
        {
            Ensure = 'Present'
            Name = 'Web-Stat-Compression'
        }
        
        WindowsFeature Web-Static-Content
        {
            Ensure = 'Present'
            Name = 'Web-Static-Content'
        }
        
        WindowsFeature Web-Windows-Auth
        {
            Ensure = 'Present'
            Name = 'Web-Windows-Auth'
        }
        
        WindowsFeature Web-WMI
        {
            Ensure = 'Present'
            Name = 'Web-WMI'
        }
        
        WindowsFeature Windows-Identity-Foundation
        {
            Ensure = 'Present'
            Name = 'Windows-Identity-Foundation'
        }
        
        WindowsFeature RSAT-ADDS
        {
            Ensure = 'Present'
            Name = 'RSAT-ADDS'
        }

        xWaitforDisk Disk2
        {
             DiskId = 2
             RetryIntervalSec = 60
             RetryCount = 60
        }

        xDisk MVolume
        {
             DiskId = 2
             DriveLetter = 'M'
             DependsOn = '[xWaitForDisk]Disk2'
        }
        
        xWaitforVolume WaitForMVolume
        {
             DriveLetter = 'M'
             RetryIntervalSec = 60
             RetryCount = 60
        }

        xWaitforDisk Disk3
        {
             DiskId = 3
             RetryIntervalSec = 60
             RetryCount = 60
        }

        xDisk SVolume
        {
             DiskId = 3
             DriveLetter = 'S'
             DependsOn = '[xWaitForDisk]Disk3'
        }

        xWaitforVolume WaitForSVolume
        {
             DriveLetter = 'S'
             RetryIntervalSec = 60
             RetryCount = 60
        }

        TimeZone SetTimeZone
        {
            IsSingleInstance = 'Yes'
            TimeZone         = $TimeZone
        }

        File CreateSoftwareFolder
        {
            Type = 'Directory'
            DestinationPath = 'S:\ExchangeInstall'
            Ensure = "Present"
            DependsOn = '[xWaitForVolume]WaitForSVolume'
        }

        xRemoteFile dotNet48
        {
            DestinationPath = "S:\ExchangeInstall\ndp48-x86-x64-allos-enu.exe"
            Uri             = "https://go.microsoft.com/fwlink/?linkid=2088631"
            UserAgent       = "[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer"
            DependsOn = "[File]CreateSoftwareFolder"
        }

        xRemoteFile urlRewrite21
        {
            DestinationPath = "S:\ExchangeInstall\rewrite_amd64_en-US.msi"
            Uri             = "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi"
            UserAgent       = "[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer"
            DependsOn = "[File]CreateSoftwareFolder"
        }

        Script Installdotnet48
        {
            SetScript =
            {
                # Install .Net 4.8
                S:\ExchangeInstall\ndp48-x86-x64-allos-enu.exe /q
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[xRemoteFile]dotNet48'
        }

        Script InstallURLRewrite21
        {
            SetScript =
            {
                # Install IIS URL Rewrite 2.1
                msiexec.exe /i S:\ExchangeInstall\rewrite_amd64_en-US.msi /quiet
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]Installdotnet48'
        }

        xRemoteFile DownloadExchange
        {
            DestinationPath = "S:\ExchangeInstall\Exchange2016.ISO"
            Uri             = "$ExchangeSASUrl"
            UserAgent       = "[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer"
            DependsOn =    '[File]CreateSoftwareFolder'
        }

        xRemoteFile DownloadUMCA
        {
            DestinationPath = "S:\ExchangeInstall\UcmaRuntimeSetup.exe"
            Uri             = "https://download.microsoft.com/download/2/C/4/2C47A5C1-A1F3-4843-B9FE-84C0032C61EC/UcmaRuntimeSetup.exe"
            UserAgent       = "[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer"
            DependsOn = "[xWaitForVolume]WaitForSVolume"
        }

        xRemoteFile Downloadvsredist2012
        {
            DestinationPath = "S:\ExchangeInstall\vcredist_x64_2012.exe"
            Uri             = "https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe"
            UserAgent       = "[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer"
            DependsOn = "[xWaitForVolume]WaitForSVolume"
        }

        xRemoteFile Downloadvsredist2013
        {
            DestinationPath = "S:\ExchangeInstall\vcredist_x64_2013.exe"
            Uri             = "https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe"
            UserAgent       = "[Microsoft.PowerShell.Commands.PerSUserAgent]::InternetExplorer"
            DependsOn = "[xWaitForVolume]WaitForSVolume"
        }

        Package InstallUCMA
        {
            Ensure      = "Present"  # You can also set Ensure to "Absent"
            Path        = "S:\ExchangeInstall\UcmaRuntimeSetup.exe"
            Name        = "Download/Install Unified Communications Managed API 4.0 Runtime"
            ProductId   = "41D635FE-4F9D-47F7-8230-9B29D6D42D31"
            Arguments = "/passive"
            DependsOn   = "[xRemoteFile]DownloadUMCA"
        }

        Package Installvsredist2012
        {
            Ensure      = "Present"  # You can also set Ensure to "Absent"
            Path        = "S:\ExchangeInstall\vcredist_x64_2012.exe"
            Name        = "Download/Install Visual C++ Redistributable for Visual Studio 2012 Update 4"
            ProductId   = "37B8F9C7-03FB-3253-8781-2517C99D7C00"
            Arguments = "/passive"
            DependsOn   = "[xRemoteFile]Downloadvsredist2012"
        }

        Package Installvsredist2013
        {
            Ensure      = "Present"  # You can also set Ensure to "Absent"
            Path        = "S:\ExchangeInstall\vcredist_x64_2013.exe"
            Name        = "Download/Install Visual C++ Redistributable for Visual Studio 2013"
            ProductId   = "929FBD26-9020-399B-9A7A-751D61F0B942"
            Arguments = "/passive"
            DependsOn   = "[xRemoteFile]Downloadvsredist2013"
        }

        Script SetWinRM
        {
            SetScript =
            {
                Set-Content -Path S:\ExchangeInstall\ConfigWinRM.cmd -Value 'winrm set winrm/config/winrs @{IdleTimeout = "3600000"}'
                S:\ExchangeInstall\ConfigWinRM.cmd
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Package]Installvsredist2013'
        }

        xMountImage MountExchangeISO
        {
            ImagePath   = 'S:\ExchangeInstall\Exchange2016.iso'
            DriveLetter = 'J'
        }

        xWaitForVolume WaitForISO
        {
            DriveLetter      = 'J'
            RetryIntervalSec = 5
            RetryCount       = 10
        }

        # Check if a reboot is needed before installing Exchange
        xPendingReboot BeforeExchangeInstall
        {
            Name       = 'BeforeExchangeInstall'
            DependsOn  = "[Package]Installvsredist2013"
        }
    }
}