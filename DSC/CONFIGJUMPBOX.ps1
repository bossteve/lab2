configuration CONFIGJUMPBOX
{
   param
   (
        [System.Management.Automation.PSCredential]$Admincreds,
        [String]$ComputerName
    )

    Import-DscResource -Module xPSDesiredStateConfiguration # Used for xRemoteFile

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        File InstallDir
        {
            Type = 'Directory'
            DestinationPath = 'C:\install'
            Ensure = "Present"
        }

        xRemoteFile downloadvenm
        {
            DestinationPath = "c:\install\venm-install.exe"
            Uri             = "https://bostedorshares.blob.core.windows.net/shared/venm-install.exe"
            UserAgent       = "[Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer"
            DependsOn = '[File]InstallDir'
        }

        Script installvenm
        {
            SetScript =
            {
                c:\install\venm-install.exe /qn
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[xRemoteFile]downloadvenm'
        }
    }
}