configuration GRANTETS
{
   param
   (
        [String]$TimeZone,
        [String]$NetBiosDomain
    )

    Import-DscResource -Module ComputerManagementDsc

    Node localhost
    {
        TimeZone SetTimeZone
        {
            IsSingleInstance = 'Yes'
            TimeZone         = $TimeZone
        }

        Script IssueCARequest
        {
            SetScript =
            {
                Add-LocalGroupMember -Member "$NetBiosDomain\Exchange Trusted Subsystem" -Group Administrators
                Get-NetFirewallProfile | Set-NetFirewallProfile -Enabled False
            }
            GetScript =  { @{} }
            TestScript = { $false}
        }

    }
}