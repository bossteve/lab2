configuration PREPAREADEXCHANGE16
{
   param
   (
        [String]$ExchangeOrgName,
        [String]$NetBiosDomain,
        [String]$DC1Name,
        [String]$BaseDN,
        [String]$CertPassword,
        [String]$CertURL,
        [System.Management.Automation.PSCredential]$Admincreds
    )
    Import-DscResource -Module xPSDesiredStateConfiguration # Used for xRemoteFile
    Import-DscResource -Module xStorage # Used by Disk

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
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

        Script PrepareExchange2016AD
        {
            SetScript =
            {
                mkdir s:\cert
                wget -Uri $using:CertURL -OutFile "s:\cert\cert.pfx"
                $pass = ConvertTo-SecureString $using:CertPassword -AsPlainText -Force
                Import-PfxCertificate -FilePath "s:\cert\cert.pfx" -CertStoreLocation Cert:\LocalMachine\My -Password $using:pass

                # Create Exchange AD Deployment
                (Get-ADDomainController -Filter *).Name | Foreach-Object { repadmin /syncall $_ (Get-ADDomain).DistinguishedName /AdeP }

                J:\Setup.exe /PrepareSchema /DomainController:"$using:dc1Name" /IAcceptExchangeServerLicenseTerms
                J:\Setup.exe /PrepareAD /on:"$using:ExchangeOrgName" /DomainController:"$using:dc1Name" /IAcceptExchangeServerLicenseTerms

                (Get-ADDomainController -Filter *).Name | Foreach-Object { repadmin /syncall $_ (Get-ADDomain).DistinguishedName /AdeP }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $DomainCreds
            DependsOn = '[xWaitForVolume]WaitForISO'
        }
    }
}