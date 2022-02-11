configuration CONFIGDNSEXT
{
   param
   (
        [String]$computerName,
        [String]$NetBiosDomain,
        [String]$InternaldomainName,
        [String]$ExternaldomainName,
        [String]$ReverseLookup1,
        [String]$ForwardLookup1,
        [String]$dc1lastoctet,
        [String]$icaIP,
        [String]$ocspIP,
        [String]$ex1IP,
        [Int]$RetryIntervalSec=420,
        [System.Management.Automation.PSCredential]$Admincreds
    )

    Import-DscResource -ModuleName DnsServerDsc
    Import-DscResource -ModuleName ActiveDirectoryDsc

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        WaitForADDomain DscForestWait
        {
            DomainName = $InternaldomainName
            Credential= $DomainCreds
            WaitTimeout = $RetryIntervalSec
        }

        DnsServerADZone ExternalDomain
        {
            Name             = "$ExternaldomainName"
            DynamicUpdate = 'Secure'
            Ensure           = 'Present'
            ReplicationScope = 'Domain'
            DependsOn = '[WaitForADDomain]DscForestWait'
        }

        DnsServerADZone ReverseADZone1
        {
            Name             = "$ReverseLookup1.in-addr.arpa"
            DynamicUpdate = 'Secure'
            Ensure           = 'Present'
            ReplicationScope = 'Domain'
            DependsOn = '[WaitForADDomain]DscForestWait'
        }

        DnsRecordPtr DC1PtrRecord
        {
            Name      = "$computerName.$InternaldomainName"
            ZoneName = "$ReverseLookup1.in-addr.arpa"
            IpAddress = "$ForwardLookup1.$dc1lastoctet"
            Ensure    = 'Present'
            DependsOn = "[DnsServerADZone]ReverseADZone1"           
        }

        DnsRecordA crlrecord
        {
            Name      = "crl"
            ZoneName  = "$ExternaldomainName"
            IPv4Address = "$icaIP"
            Ensure    = 'Present'
            DependsOn = '[DnsServerADZone]ExternalDomain'
        }

        DnsRecordA ocsprecord
        {
            Name      = "ocsp"
            ZoneName  = "$ExternaldomainName"
            IPv4Address = "$ocspIP"
            Ensure    = 'Present'
            DependsOn = '[DnsServerADZone]ExternalDomain'
        }

        DnsRecordA owa2016record1
        {
            Name      = "owa2016"
            ZoneName  = "$ExternaldomainName"
            IPv4Address  = "$ex1IP"
            Ensure    = 'Present'
            DependsOn = '[DnsServerADZone]ExternalDomain'
        }

        DnsRecordA autodiscover2016record1
        {
            Name      = "autodiscover2016"
            ZoneName  = "$ExternaldomainName"
            IPv4Address  = "$ex1IP"
            Ensure    = 'Present'
            DependsOn = '[DnsServerADZone]ExternalDomain'
        }

        DnsRecordA outlook2016record1
        {
            Name      = "outlook2016"
            ZoneName  = "$ExternaldomainName"
            IPv4Address  = "$ex1IP"
            Ensure    = 'Present'
            DependsOn = '[DnsServerADZone]ExternalDomain'
        }

        DnsRecordA eas2016record1
        {
            Name      = "eas2016"
            ZoneName  = "$ExternaldomainName"
            IPv4Address  = "$ex1IP"
            Ensure    = 'Present'
            DependsOn = '[DnsServerADZone]ExternalDomain'
        }


        DnsRecordA smtprecord1
        {
            Name      = "smtp"
            ZoneName  = "$ExternaldomainName"
            IPv4Address = "$ex1IP"
            Ensure    = 'Present'
            DependsOn = '[DnsServerADZone]ExternalDomain'
         }
    }
}