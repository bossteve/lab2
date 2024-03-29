﻿configuration FIRSTADFS
{
   param
   (
        [String]$TimeZone,        
        [String]$NetBiosDomain,
        [String]$DomainName,
        [System.Management.Automation.PSCredential]$Admincreds,
        [string]$CertSubjectName,
        [String]$CertPassword,
        [String]$CertURL
    )
    
    Import-DscResource -Module xPSDesiredStateConfiguration # Used for xRemoteFile
    Import-DscResource -Module ComputerManagementDsc # Used for TimeZone

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        WindowsFeature ADFS-Federation
        {
            Ensure = 'Present'
            Name   = 'ADFS-Federation'
        }

        TimeZone SetTimeZone
        {
            IsSingleInstance = 'Yes'
            TimeZone         = $TimeZone
        }

        File Certificates
        {
            Type = 'Directory'
            DestinationPath = 'C:\cert'
            Ensure = "Present"
        }

        Script GetADFSCertificates
        {
            SetScript =
            {
                wget -Uri $using:CertURL -OutFile "c:\cert\cert.pfx"
                $pass = ConvertTo-SecureString $using:CertPassword -AsPlainText -Force
                Import-PfxCertificate -FilePath "c:\cert\cert.pfx" -CertStoreLocation Cert:\LocalMachine\My -Password $using:pass 
                start-sleep 10
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[File]Certificates'
        }

        Script ConfigureADFS
        {
            SetScript =
            {
                Import-Module ADFS

                # Get Service Communication Certificate
                $thumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like "CN=$using:CertSubjectName"}).Thumbprint

                # Get Token Signing Certificate
                $signthumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like "CN=$using:CertSubjectName"}).Thumbprint

                
                Install-AdfsFarm -CertificateThumbprint $thumbprint -FederationServiceName "adfs.$using:DomainName" -GroupServiceAccountIdentifier "$using:NetBiosDomain\FsGmsa$"
                
                Set-ADFSProperties -AutoCertificateRollover $False
                
                # Add Token Signing Certificate
                Add-AdfsCertificate -CertificateType "Token-Signing" -Thumbprint $signthumbprint

                # Set Token Signing Certificate
                Set-AdfsCertificate -IsPrimary -CertificateType "Token-Signing" -Thumbprint $signthumbprint
                
                $firewall = Get-NetFirewallRule "FPS-SMB-In-TCP" -ErrorAction 0
                IF ($firewall -ne $null) {Enable-NetFirewallRule -Name "FPS-SMB-In-TCP"}

                # Enable Test Sign-In
                Set-AdfsProperties -EnableIdPInitiatedSignonPage $true
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $DomainCreds
            DependsOn = '[Script]GetADFSCertificates'
        }
    }
}