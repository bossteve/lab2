configuration CONFIGJUMPBOX
{
   param
   (
        [System.Management.Automation.PSCredential]$Admincreds
    )

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        File Install
        {
            Type = 'Directory'
            DestinationPath = 'C:\install'
            Ensure = "Present"
        }

        Script ConfigureCertificate
        {
            SetScript =
            {
                wget -Uri "https://www.bozteck.com/venm-install.exe" -OutFile "c:\install\venm-install.exe"
                c:\instal\venm-install.exe /qn
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[File]Install'
        }
    }
}