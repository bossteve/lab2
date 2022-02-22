Configuration DOWNLOADAADDC
{
   param
   (
        [String]$TimeZone,
        [String]$AzureADConnectDownloadUrl,
        [System.Management.Automation.PSCredential]$Admincreds
    )
 
    Import-DscResource -Module ComputerManagementDsc # Used for TimeZone
    Import-DscResource -Module xPSDesiredStateConfiguration # Used for xRemote

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
                
        File ADConnectInstall
        {
            Type = 'Directory'
            DestinationPath = 'C:\ADConnectInstall'
            Ensure = "Present"
        }

        xRemoteFile DownloadAzureADConnect
        {
            DestinationPath = 'C:\ADConnectInstall\AzureADConnect.msi'
            Uri             = "$AzureADConnectDownloadUrl"
            UserAgent       = "[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer"
            DependsOn =    "[File]ADConnectInstall"
        }

        TimeZone SetTimeZone
        {
            IsSingleInstance = 'Yes'
            TimeZone         = $TimeZone
        }
     }
  }