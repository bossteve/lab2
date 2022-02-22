configuration CONFIGDNSINT

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
        [String]$Server1IP,
        [String]$ex1IP,
        [String]$ADFSServer1IP,
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

        DnsRecordA server1record
        {
            Name      = "ocsp"
            ZoneName  = "$ExternaldomainName"
            IPv4Address = "$Server1IP"
            Ensure    = 'Present'
        }

        DnsRecordA owa2016record1
        {
            Name      = "owa2016"
            ZoneName  = "$ExternaldomainName"
            IPv4Address  = "$ex1IP"
            Ensure    = 'Present'
        }

        DnsRecordA autodiscover2016record1
        {
            Name      = "autodiscover2016"
            ZoneName  = "$ExternaldomainName"
            IPv4Address  = "$ex1IP"
            Ensure    = 'Present'
        }

        DnsRecordA outlook2016record1
        {
            Name      = "outlook2016"
            ZoneName  = "$ExternaldomainName"
            IPv4Address  = "$ex1IP"
            Ensure    = 'Present'
        }

        DnsRecordA eas2016record1
        {
            Name      = "eas2016"
            ZoneName  = "$ExternaldomainName"
            IPv4Address  = "$ex1IP"
            Ensure    = 'Present'
        }

        DnsRecordA smtprecord1
        {
            Name      = "smtp"
            ZoneName  = "$ExternaldomainName"
            IPv4Address = "$ex1IP"
            Ensure    = 'Present'
         }

         xDnsRecord adfsrecord
         {
             Name      = "adfs"
             Zone      = $ExternalDomainName
             Target    = $ADFSServer1IP
             Type      = 'ARecord'
             Ensure    = 'Present'
         }
    }
}