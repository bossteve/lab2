Configuration ROOTCA
{
   param
   (
        [String]$TimeZone,
        [String]$domainName,
        [String]$RootCAHashAlgorithm,
        [String]$RootCAKeyLength,
        [String]$RootCAName,
        [String]$BaseDN,
        [System.Management.Automation.PSCredential]$Admincreds
    )
 
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DscResource -ModuleName ActiveDirectoryCSDsc
    Import-DscResource -ModuleName xPSDesiredStateConfiguration

    [System.Management.Automation.PSCredential ]$Creds = New-Object System.Management.Automation.PSCredential ("$($AdminCreds.UserName)", $AdminCreds.Password)
 
    Node localhost
    {
        # Assemble the Local Admin Credentials
        # Install the ADCS Certificate Authority
        WindowsFeature ADCSCA 
        {
            Name = 'ADCS-Cert-Authority'
            Ensure = 'Present'
        }

        File CertEnroll
        {
            Type = 'Directory'
            DestinationPath = 'C:\CertEnroll'
            Ensure = "Present"
        }

        File MachineConfig
        {
            Type = 'Directory'
            DestinationPath = 'C:\MachineConfig'
            Ensure = "Present"
        }

        # Configure the CA as Standalone Root CA
        ADCSCertificationAuthority CertificateAuthority
        {
            Ensure = 'Present'
	        Credential = $Creds	
            CAType = 'StandaloneRootCA'
            CACommonName = $RootCAName
            CADistinguishedNameSuffix = $Node.CADistinguishedNameSuffix
            ValidityPeriod = 'Years'
            ValidityPeriodUnits = 20
            CryptoProviderName = 'RSA#Microsoft Software Key Storage Provider'
            HashAlgorithmName = $RootCAHashAlgorithm
            KeyLength = $RootCAKeyLength
            IsSingleInstance = 'Yes'
            DependsOn = "[WindowsFeature]ADCSCA"
        }
 
        WindowsFeature RSAT-ADCS 
        { 
            Ensure = 'Present' 
            Name = 'RSAT-ADCS' 
            DependsOn = '[AdcsCertificationAuthority]CertificateAuthority'
        } 

        WindowsFeature RSAT-ADCS-Mgmt 
        { 
            Ensure = 'Present' 
            Name = 'RSAT-ADCS-Mgmt' 
            DependsOn = '[AdcsCertificationAuthority]CertificateAuthority'
        }

        TimeZone SetTimeZone
        {
            IsSingleInstance = 'Yes'
            TimeZone         = $TimeZone
        }

        Script ConfigureRootCA
        {
            SetScript =
            {
                # Remove All Default CDP Locations
                Get-CACrlDistributionPoint | Where-Object {$_.Uri -like 'ldap*'} | Remove-CACrlDistributionPoint -Force
                Get-CACrlDistributionPoint | Where-Object {$_.Uri -like 'http*'} | Remove-CACrlDistributionPoint -Force
                Get-CACrlDistributionPoint | Where-Object {$_.Uri -like 'file*'} | Remove-CACrlDistributionPoint -Force

                # Check for and if not present add LDAP CDP Location
                $LDAPCDPURI = Get-CACrlDistributionPoint | Where-object {$_.uri -like "ldap:///CN=<CATruncatedName><CRLNameSuffix>"+"*"}
                IF ($LDAPCDPURI.uri -eq $null){Add-CACRLDistributionPoint -Uri "ldap:///CN=<CATruncatedName><CRLNameSuffix>,CN=<ServerShortName>,CN=CDP,CN=Public Key Services,CN=Services,<ConfigurationContainer><CDPObjectClass>" -AddToCertificateCDP -AddToCrlCdp -Force}

                # Check for and if not present add HTTP CDP Location
                $HTTPCDPURI = Get-CACrlDistributionPoint | Where-object {$_.uri -like "http://crl"+"*"}
                IF ($HTTPCDPURI.uri -eq $null){Add-CACRLDistributionPoint -Uri "http://crl.$using:domainName/CertEnroll/<CAName><CRLNameSuffix><DeltaCRLAllowed>.crl" -AddToCertificateCDP -AddToFreshestCrl -Force}

                # Remove All Default AIA Locations
                Get-CAAuthorityInformationAccess | Where-Object {$_.Uri -like 'ldap*'} | Remove-CAAuthorityInformationAccess -Force
                Get-CAAuthorityInformationAccess | Where-Object {$_.Uri -like 'http*'} | Remove-CAAuthorityInformationAccess -Force
                Get-CAAuthorityInformationAccess | Where-Object {$_.Uri -like 'file*'} | Remove-CAAuthorityInformationAccess -Force

                # Check for and if not present add LDAP AIA Location
                $LDAPAIAURI = Get-CAAuthorityInformationaccess | Where-object {$_.uri -like "ldap:///CN=<CATruncatedName>,CN=AIA"+"*"}
                IF ($LDAPAIAURI.uri -eq $null){Add-CAAuthorityInformationaccess -Uri "ldap:///CN=<CATruncatedName>,CN=AIA,CN=Public Key Services,CN=Services,<ConfigurationContainer><CAObjectClass>" -AddToCertificateAia -Force}

                # Check for and if not present add HTTP AIA Location
                $HTTPAIAURI = Get-CAAuthorityInformationaccess | Where-object {$_.uri -like "http://crl"+"*"}
                IF ($HTTPAIAURI.uri -eq $null){Add-CAAuthorityInformationaccess -Uri "http://crl.$using:domainName/CertEnroll/<ServerDNSName>_<CAName><CertificateName>.crt" -AddToCertificateAia -Force}

                # Check for and if not present add HTTP OCSP Location
                $HTTPOCSPURI = Get-CAAuthorityInformationaccess | Where-object {$_.uri -like "http://ocsp"+"*"}
                IF ($HTTPOCSPURI.uri -eq $null){Add-CAAuthorityInformationaccess -Uri "http://ocsp.$using:domainName/ocsp" -AddToCertificateOcsp -Force}

                # Set CRL Publication Internal
                certutil -setreg CA\CRLPeriodUnits 6
                certutil -setreg CA\CRLPeriod "Months"

                # Set RootCA Certificate Expiration Period
                certutil -setreg CA\ValidityPeriodUnits 10
                certutil -setreg CA\ValidityPeriod "Years"

                # Configure Offline Root for Revocation
                certutil -setreg CA\DSConfigDN "CN=Configuration,$using:BaseDN"
                certutil -setreg CA\DSDomainDN "$using:BaseDN"
                Restart-Service -Name CertSvc 

                certutil -CRL

                # Allow Remote Copy
                $winrmserviceitem = get-item -Path "HKLM:\Software\Policies\Microsoft\Windows\WinRm\Service" -ErrorAction 0
                $allowunencrypt = get-itemproperty -Path "HKLM:\Software\Policies\Microsoft\Windows\WinRm\Service" -Name "AllowUnencryptedTraffic" -ErrorAction 0
                $allowbasic = get-itemproperty -Path "HKLM:\Software\Policies\Microsoft\Windows\WinRm\Service" -Name "AllowBasic" -ErrorAction 0
                $firewall = Get-NetFirewallRule "FPS-SMB-In-TCP" -ErrorAction 0
                IF ($winrmserviceitem -eq $null) {New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\WinRm\" -Name "Service" -Force}
                IF ($allowunencrypt -eq $null) {New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\WinRM\Service\" -Name "AllowUnencryptedTraffic" -Value 1}
                IF ($allowbasic -eq $null) {New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\WinRM\Service\" -Name "AllowBasic" -Value 1}
                IF ($firewall -ne $null) {Enable-NetFirewallRule -Name "FPS-SMB-In-TCP"}

                # Enable Auto Accept for Root CA Requests
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\CertSvc\Configuration\$using:RootCAName\PolicyModules\CertificateAuthority_MicrosoftDefault.Policy\" -Name "RequestDisposition" -Value 1
                Restart-Service -Name CertSvc   
                
                certutil -CRL      
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[AdcsCertificationAuthority]CertificateAuthority'
        }
   
     }
  }