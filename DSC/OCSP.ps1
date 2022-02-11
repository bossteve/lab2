Configuration OCSP
{
   param
   (
        [String]$computerName,
        [String]$TimeZone,
        [String]$NetBiosDomain,
        [String]$InternaldomainName,
        [String]$ExternaldomainName,
        [String]$IssuingCAName,
        [String]$RootCAName,
        [System.Management.Automation.PSCredential]$Admincreds
    )
 
    Import-DscResource -ModuleName ActiveDirectoryCSDsc # Used for Certificate Authority
    Import-DscResource -ModuleName ComputerManagementDsc # Used for TimeZone

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($AdminCreds.UserName)", $AdminCreds.Password)
 
    Node localhost
    {
        File CertEnroll
        {
            Type = 'Directory'
            DestinationPath = 'C:\CertEnroll'
            Ensure = "Present"
        }

        WindowsFeature ADCS-Online-Cert
        {
            Ensure = 'Present'
            Name   = 'ADCS-Online-Cert'
        }

        AdcsOnlineResponder OnlineResponder
        {
            Ensure           = 'Present'
            IsSingleInstance = 'Yes'
            Credential       = $DomainCreds
            DependsOn        = '[WindowsFeature]ADCS-Online-Cert'
        }

        WindowsFeature RSAT-Online-Responder
        {
            Name = "RSAT-Online-Responder"
            Ensure = "Present"

        }

        TimeZone SetTimeZone
        {
            IsSingleInstance = 'Yes'
            TimeZone         = $TimeZone
        }

        Script BackupCryptoKeys
        {
            SetScript =
            {
                # Update CA's
                gpupdate /force

                # Move Crypto Keys
                $dest1 = "C:\ProgramData\Microsoft\Crypto\Keys"
                $dest2 = "C:\ProgramData\Microsoft\Crypto\Keys\Temp\"
                New-Item -Path $Dest2 -ItemType directory
                Get-ChildItem $dest1 -exclude "Temp" | Move-Item -Destination $dest2
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[TimeZone]SetTimeZone'
        }

        Script GetOCSPCertificate
        {
            SetScript =
            {
                # Create Credentials
                $Load = "$using:DomainCreds"
                $Domain = $DomainCreds.GetNetworkCredential().Domain
                $Username = $DomainCreds.GetNetworkCredential().Username
                $Password = $DomainCreds.GetNetworkCredential().Password
                
                # Create GetOCSPCert Script
                Set-Content -Path C:\CertEnroll\Get_OCSP_Certificate.ps1 -Value 'Get-Certificate -Template "OCSPResponseSigning1" -CertStoreLocation cert:\LocalMachine\My'

                # Create Scheduled Task
                $scheduledtask = Get-ScheduledTask "Get OCSP Certificate" -ErrorAction 0
                IF ($scheduledtask -eq $null) {
                $action = New-ScheduledTaskAction -Execute Powershell -Argument '.\Get_OCSP_Certificate.ps1' -WorkingDirectory 'C:\CertEnroll'
                Register-ScheduledTask -Action $action -TaskName "Get OCSP Certificate" -Description "Get OCSP Certificate" -User $Domain\$Username -Password $Password
                Start-ScheduledTask "Get OCSP Certificate"
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]BackupCryptoKeys'
        }

        Script ConfigureOCSP
        {
            SetScript =
            {
                Start-Sleep -s 60
                $dest1 = "C:\CertEnroll"
                $dest2 = "C:\ProgramData\Microsoft\Crypto\Keys"
                $dest3 = "C:\ProgramData\Microsoft\Crypto\Keys\Temp\"

                # Grant Network Service Access to Private Keys
                $account = "NT AUTHORITY\Network Service"
                $file = Get-ChildItem C:\ProgramData\Microsoft\Crypto\Keys -Exclude "Temp"
                $fullPath=$file.FullName
                $acl=(Get-Item $fullPath).GetAccessControl('Access')
                $permission=$account,"Full","Allow"
                $accessRule=new-object System.Security.AccessControl.FileSystemAccessRule $permission
                $acl.AddAccessRule($accessRule)
                Set-Acl $fullPath $acl

                # Move Crypto Keys
                Get-ChildItem $dest3 | Move-Item -Destination $dest2
                Remove-Item $dest3 -Force -ErrorAction 0

                # Configure Online Responder
                $IssuingCert = "C:\CertEnroll\$using:IssuingCAName.cer"
                $RootCert = "C:\CertEnroll\$using:RootCAName.cer"
                $IssuingCrl = "http://crl.$using:ExternaldomainName/CertEnroll/$using:IssuingCAName.crl"
                $IssuingDeltaCrl = "http://crl.$using:ExternaldomainName/CertEnroll/$using:IssuingCAName+.crl"
                $RootCrl = "http://crl.$using:ExternaldomainName/CertEnroll/$using:RootCAName.crl"
                $servername = "$using:computerName.$using:InternaldomainName"
                $signingcertificate = "CN=$using:computerName.$using:InternaldomainName"

                # Create a new certificate object
                $SigningCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate

                # Get the certificate from the local store by using it's DN
                $SigningCert = ls cert:\LocalMachine\My | where {($_.Subject -eq $signingcertificate) -and ($_.Issuer -like "CN=$using:IssuingCAName*")}

                # Save the raw certificate data
                $SigningCert = $SigningCert.GetRawCertData()

                $IssuingExport = Get-ChildItem -Path cert:\Localmachine\CA\ | Where-Object {$_.Subject -like "CN=$using:IssuingCAName*"}
                Export-Certificate -Cert $IssuingExport -FilePath "C:\CertEnroll\$using:IssuingCAName.cer" -Type CER

                $RootExport = Get-ChildItem -Path cert:\Localmachine\Root\ | Where-Object {$_.Subject -like "CN=$using:RootCAName*"}
                Export-Certificate -Cert $RootExport -FilePath "C:\CertEnroll\$using:RootCAName.cer" -Type CER

                $IssuingFile = Get-ChildItem $IssuingCert
                $IssuingCertName = $IssuingFile.Name
                $IssuingCertPath = $IssuingFile.DirectoryName

                $RootFile = Get-ChildItem $RootCert
                $RootCertName = $RootFile.Name
                $RootCertPath = $RootFile.DirectoryName

                $IssuingCaCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate
                $IssuingCaCert.Import($IssuingCertPath + "\" + $IssuingCertName)
                $IssuingCaCert = $IssuingCaCert.GetRawCertData()

                $RootCaCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate
                $RootCaCert.Import($RootCertPath + "\" + $RootCertName)
                $RootCaCert = $RootCaCert.GetRawCertData()

                # Save the desired OcspProperties in a collection object
                $OcspProperties1 = New-Object -com "CertAdm.OCSPPropertyCollection"
                $OcspProperties1.CreateProperty("BaseCrlUrls", $IssuingCrl)
                $OcspProperties1.CreateProperty("DeltaCrlUrls", $IssuingDeltaCrl)
                $OcspProperties1.CreateProperty("RevocationErrorCode", 0)

                $OcspProperties2 = New-Object -com "CertAdm.OCSPPropertyCollection"
                $OcspProperties2.CreateProperty("BaseCrlUrls", $RootCrl)
                $OcspProperties2.CreateProperty("RevocationErrorCode", 0)

                # Sets the refresh interval to 1 hour (time is specified in milliseconds)
                $OcspProperties1.CreateProperty("RefreshTimeOut", 3600000)
                $OcspProperties2.CreateProperty("RefreshTimeOut", 3600000)

                # Save the baseName in a variable, this is the filename without extension
                # eg. basename of certificate.cer is certificate
                $IssuingCertBaseName = $IssuingFile.BaseName
                $RootCertBaseName = $RootFile.BaseName

                # Save the current configuration in an OcspAdmin object
                $OcspAdmin = New-Object -com "CertAdm.OCSPAdmin"
                $OcspAdmin.GetConfiguration($servername, $true)

                # Create Issuing CA Revocation Configuration
                $NewConfig1 = $OcspAdmin.OCSPCAConfigurationCollection.CreateCAConfiguration($IssuingCertBaseName, $IssuingCaCert)
                $NewConfig1.HashAlgorithm = "SHA1"
                $NewConfig1.SigningFlags = 0x020
                $NewConfig1.SigningCertificate = $SigningCert
                $NewConfig1.ProviderProperties = $OcspProperties1.GetAllProperties()
                $NewConfig1.ProviderCLSID = "{4956d17f-88fd-4198-b287-1e6e65883b19}"
                $NewConfig1.ReminderDuration = 90

                # Commit the new configuration to the server
                $OcspAdmin.SetConfiguration($servername, $true)
                Restart-Service OCSPSvc

                # Create Root CA Revocation Configuration
                $NewConfig2 = $OcspAdmin.OCSPCAConfigurationCollection.CreateCAConfiguration($RootCertBaseName, $RootCaCert)
                $NewConfig2.HashAlgorithm = "SHA1"
                $NewConfig2.SigningFlags = 0x020
                $NewConfig2.SigningCertificate = $SigningCert
                $NewConfig2.ProviderProperties = $OcspProperties2.GetAllProperties()
                $NewConfig2.ProviderCLSID = "{4956d17f-88fd-4198-b287-1e6e65883b19}"
                $NewConfig2.ReminderDuration = 90

                # Commit the new configuration to the server
                $OcspAdmin.SetConfiguration($servername, $true)
                Restart-Service OCSPSvc
            }
            GetScript =  { @{} }
            TestScript = { $false}
            Credential = $DomainCreds
            DependsOn = '[Script]GetOCSPCertificate'
        }
     }
  }