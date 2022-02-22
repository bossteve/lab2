configuration CREATEFSGMSA
{
   param
   (
        [String]$NetBiosDomain,
        [String]$domainName
    )

    Node localhost
    {
        Script IssueCARequest
        {
            SetScript =
            {
                # Create KDS Root Key
                $rootkey = Get-KdsRootKey
                IF ($rootkey -eq $nullvar){Add-KdsRootKey -EffectiveTime (Get-Date).AddHours(-10)}
     
                # Create Group Managed Service Account
                $gmsa = Get-ADServiceAccount -Filter * | Where-Object {$_.Name -like 'fsgmsa*'}
                IF ($gmsa -eq $nullvar){New-ADServiceAccount FsGmsa -DNSHostName "adfs.$using:domainName" -ServicePrincipalNames "http/adfs.$using:domainName"}

            }
            GetScript =  { @{} }
            TestScript = { $false}
        }

    }
}