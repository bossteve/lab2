configuration CREATESITES
{
   param
   (
        [String]$computerName,
        [String]$NamingConvention,
        [String]$BaseDN,
        [String]$Site1Prefix
    )

    Import-DscResource -Module ActiveDirectoryDsc

    Node localhost
    {

        ADReplicationSite Site1
        {
            Ensure = 'Present'
            Name   = "$NamingConvention-Site1"
        }

        ADReplicationSubnet Site1Subnet1
        {
            Name     = $Site1Prefix
            Site     = "$NamingConvention-Site1"
            DependsOn = "[ADReplicationSite]Site1"
        }

        Script UpdateDNSSettings
        {
            SetScript =
            {

                # Move First Domain Controller
                $Site1DN = "CN=$using:NamingConvention-Site1,CN=Sites,CN=Configuration,$using:BaseDN"
                Move-ADDirectoryServer -Identity $using:computerName -Site $Site1DN

            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = "[ADReplicationSubnet]Site1Subnet1"
        }

    }
}