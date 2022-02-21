﻿configuration EXCHANGE1622
{
   param
   (
        [String]$NetBiosDomain,
        [String]$DBName,
        [String]$SetupDC,
        [String]$CertURL,
        [string]$CertSubjectName,
        [securestring]$CertPassword,
        [System.Management.Automation.PSCredential]$Admincreds
    )

    Import-DscResource -Module xStorage # Used by Disk

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
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

        File ExchangeInstall
        {
            Type = 'Directory'
            DestinationPath = 'S:\ExchangeInstall'
            Ensure = "Present"
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

        Script InstallExchange2016
        {
            SetScript =
            {
                $Install = Get-ChildItem -Path S:\ExchangeInstall\DeployExchange.cmd -ErrorAction 0
                IF ($Install -eq $null) {   
                mkdir s:\cert
                wget -Uri $CertURL -OutFile "s:\cert\cert.pfx"
                Import-PfxCertificate -FilePath "s:\cert\cert.pfx" -CertStoreLocation Cert:\LocalMachine\My -Password $CertPassword 
                Set-Content -Path S:\ExchangeInstall\DeployExchange.cmd -Value "J:\Setup.exe /IAcceptExchangeServerLicenseTerms_DiagnosticDataOFF /Mode:Install /Role:Mailbox /DbFilePath:M:\$using:DBName\$using:DBName.edb /LogFolderPath:M:\$using:DBName /MdbName:$using:DBName /dc:$using:SetupDC"
                S:\ExchangeInstall\DeployExchange.cmd
		}
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $DomainCreds
            DependsOn = '[xWaitForVolume]WaitForISO'
        }

    }
}