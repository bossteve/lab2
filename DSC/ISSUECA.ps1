Configuration ISSUECA
{
   param
   (
        [String]$computerName,
        [String]$TimeZone,
        [String]$NamingConvention,
        [String]$NetBiosDomain,
        [String]$IssuingCAName,
        [String]$RootCAName,
        [String]$RootCAIP,
        [String]$IssuingCAHashAlgorithm,
        [String]$IssuingCAKeyLength,
        [System.Management.Automation.PSCredential]$Admincreds
    )
 
    Import-DscResource -Module ActiveDirectoryCSDsc # Used for Certificate Authority
    Import-DscResource -Module ComputerManagementDsc # Used for TimeZone

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($AdminCreds.UserName)", $AdminCreds.Password)
 
    Node localhost
    {
        # Install the RSAT PowerShell Module which is required by the xWaitForResource
        WindowsFeature RSATADPowerShell
        { 
            Ensure = "Present"
            Name = "RSAT-AD-PowerShell"
        } 
 
        # Install the CA Service
        WindowsFeature ADCSCA
        {
            Name = 'ADCS-Cert-Authority'
            Ensure = 'Present'
            DependsOn = "[WindowsFeature]RSATADPowerShell"
        }
 
        # Install the Web Enrollment Service
        WindowsFeature WebEnrollmentCA
        {
            Name = 'ADCS-Web-Enrollment'
            Ensure = 'Present'
            DependsOn = "[WindowsFeature]ADCSCA"
        }
 
        File CertEnroll
        {
            Type = 'Directory'
            DestinationPath = 'C:\CertEnroll'
            Ensure = "Present"
        }

        # Configure the Sub CA which will create the Certificate REQ file that Root CA will use
        # to issue a certificate for this Sub CA.
        ADCSCertificationAuthority CertificateAuthority
        {
            Ensure = 'Present'
            Credential = $DomainCreds
            CAType = 'EnterpriseSubordinateCA'
            CACommonName = $IssuingCAName
            CADistinguishedNameSuffix = $Node.CADistinguishedNameSuffix
            OverwriteExistingCAinDS  = $True
            HashAlgorithmName = $IssuingCAHashAlgorithm
            KeyLength = $IssuingCAKeyLength
            IsSingleInstance = 'Yes'
            OutputCertRequestFile = "C:\CertEnroll\$IssuingCAName.req"
            DependsOn = '[File]CertEnroll'
        }
 
        # Configure the Web Enrollment Feature
        ADCSWebEnrollment ConfigWebEnrollment
        {
            Ensure = 'Present'
            Credential = $DomainCreds
            IsSingleInstance = 'Yes'
            DependsOn = '[AdcsCertificationAuthority]CertificateAuthority'
        }

        WindowsFeature RSAT-ADCS 
        { 
            Ensure = 'Present' 
            Name = 'RSAT-ADCS' 
            DependsOn = '[AdcsWebEnrollment]ConfigWebEnrollment'
        }
        
        WindowsFeature Web-Mgmt-Console
        { 
            Ensure = 'Present' 
            Name = 'Web-Mgmt-Console' 
            DependsOn = '[AdcsWebEnrollment]ConfigWebEnrollment'
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

        File CopyFilesFromRootCA
        {
            Ensure = "Present"
            Type = "Directory"
            Recurse = $true
            SourcePath = "\\$RootCAIP\c$\Windows\System32\certsrv\CertEnroll"
            DestinationPath = "C:\Windows\System32\certsrv\CertEnroll\"
            Credential = $DomainCreds
            DependsOn = '[AdcsCertificationAuthority]CertificateAuthority'
        }

        File CopyToRootCA
        {
            Ensure = "Present"
            Type = "File"
            SourcePath = "C:\CertEnroll\$IssuingCAName.req"
            DestinationPath = "\\$RootCAIP\c$\CertEnroll\$IssuingCAName.req"
            Credential = $Admincreds
            DependsOn = "[AdcsCertificationAuthority]CertificateAuthority"
        }

        Script PublishRootCDPandCRL
        {
            SetScript =
            {
                # Public Root CA CDP and CRL
                certutil -dspublish -f "C:\Windows\System32\CertSrv\CertEnroll\$using:NamingConvention-rca-01_$using:RootCAName.crt" RootCA
                certutil -dspublish -f "C:\Windows\System32\CertSrv\CertEnroll\$using:RootCAName.crl"
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $DomainCreds
        }
     }
  }