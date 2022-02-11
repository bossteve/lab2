configuration SENDEMAIL
{
   param
   (
        [String]$ToEmail,
        [String]$FromEmail,
        [String]$IssuingCAServerName,
        [String]$RootCAServerName,
        [String]$IssuingCAName,
        [String]$RootCAName,
        [String]$InternalDomainName,
        [String]$ExchangeServerName,
        [System.Management.Automation.PSCredential]$Admincreds
    )
    Import-DscResource -Module xPSDesiredStateConfiguration # Used for xRemoteFile

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        Script SendCompletionEmail
        {
            SetScript =
            {
                $u = "_"
                $Att1 = "C:\Windows\System32\certsrv\CertEnroll\$using:IssuingCAServerName.$using:InternalDomainName$u$using:IssuingCAName.crt"
                $Att2 = "C:\Windows\System32\certsrv\CertEnroll\$using:RootCAServerName$u$using:RootCAName.crt"          
                
                # Build a command that will be run inside the VM.
                Send-MailMessage -To "$using:ToEmail" -From "$using:FromEmail" -Subject "Certificates" -Body "Attached is the Issuing Certificate Authority that is needed to connect via RDP and securely connect to OWA." -SmtpServer "$using:ExchangeServerName" -Attachments "$Att1"
                Send-MailMessage -To "$using:ToEmail" -From "$using:FromEmail" -Subject "Certificates" -Body "Attached are the Root Certificate Authority that is needed to connect via RDP and securely connect to OWA" -SmtpServer "$using:ExchangeServerName" -Attachments "$Att2"
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $DomainCreds
        }
    }
}