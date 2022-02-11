configuration GRANTCA
{
   param
   (
        [String]$NamingConvention,
        [String]$IssuingCAName,
        [String]$RootCAName

    )

    Node localhost
    {
        Script IssueCARequest
        {
            SetScript =
            {
                # Check to see if CRT File Already Exists
                $file = Get-Item -Path "C:\CertEnroll\$using:IssuingCAName.crt" -ErrorAction 0
                IF ($file -eq $null) {certreq -submit -config "$using:NamingConvention-rca-01\$using:RootCAName" "C:\CertEnroll\$using:IssuingCAName.req" "C:\CertEnroll\$using:IssuingCAName.crt"}

            }
            GetScript =  { @{} }
            TestScript = { $false}
        }

    }
}