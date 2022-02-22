configuration CONFIGEXCHANGE16
{
   param
   (
        [String]$ComputerName,
        [String]$InternaldomainName,
        [String]$ExternaldomainName,                 
        [String]$NetBiosDomain,
        [String]$BaseDN,
        [String]$ConfigDC,
        [String]$Site,
        [string]$CertSubjectName,
        [System.Management.Automation.PSCredential]$Admincreds
    )

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        File Certificates
        {
            Type = 'Directory'
            DestinationPath = 'C:\Certificates'
            Ensure = "Present"
        }

        Script ConfigureExchange2016
        {
            SetScript =
            {
                # Get Certificate 2016 Certificate
                $thumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like "CN=$using:CertSubjectName"}).Thumbprint
                
                # Connect to Exchange
                $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "http://$using:computerName.$using:InternalDomainName/PowerShell/"
                Import-PSSession $Session

                # Set Virtual Directories
                # Set AUTODISCOVER Virtual Directory
                Set-ClientAccessServer "$using:computerName" –AutodiscoverServiceInternalUri "https://autodiscover2016.$using:ExternalDomainName/Autodiscover/Autodiscover.xml"
                
                # Set OWA Virtual Directory"
                Set-OWAVirtualDirectory –Identity "$using:computerName\owa (Default Web Site)" –InternalURL "https://owa2016.$using:ExternalDomainName/OWA" -ExternalURL "https://owa2016.$using:ExternalDomainName/OWA" -ExternalAuthenticationMethods NTLM -FormsAuthentication:$False -BasicAuthentication:$False –WindowsAuthentication:$True

                # Set ECP Virtual Directory
                Set-ECPVirtualDirectory –Identity "$using:computerName\ecp (Default Web Site)" –InternalURL "https://owa2016.$using:ExternalDomainName/ECP" -ExternalURL "https://owa2016.$using:ExternalDomainName/ECP" -ExternalAuthenticationMethods NTLM -FormsAuthentication:$False -BasicAuthentication:$False –WindowsAuthentication:$True

                # Set OAB Virtual Directory
                Set-OABVirtualDirectory –Identity "$using:computerName\oab (Default Web Site)" –InternalURL "https://outlook2016.$using:ExternalDomainName/OAB" -ExternalURL "https://outlook2016.$using:ExternalDomainName/OAB"
                
                # Set MRS PROXY Virtual Directory"
                Set-WebServicesVirtualDirectory –Identity "$using:computerName\EWS (Default Web Site)" –MRSProxyEnabled:$True
                Set-WebServicesVirtualDirectory –Identity "$using:computerName\EWS (Default Web Site)" –InternalURL "https://outlook2016.$using:ExternalDomainName/EWS/Exchange.asmx" -ExternalURL "https://outlook2016.$using:ExternalDomainName/EWS/Exchange.asmx"

                # Set ACTIVESYNC Virtual Directory
                Set-ActiveSyncVirtualDirectory –Identity "$using:computerName\Microsoft-Server-ActiveSync (Default Web Site)" –InternalURL "https://eas2016.$using:ExternalDomainName/Microsoft-Server-ActiveSync" -ExternalURL "https://eas2016.$using:ExternalDomainName/Microsoft-Server-ActiveSync"

                # Set MAPI Virtual Directory
                Set-MapiVirtualDirectory –Identity "$using:computerName\mapi (Default Web Site)" –InternalURL "https://outlook2016.$using:ExternalDomainName/MAPI" -ExternalURL "https://outlook2016.$using:ExternalDomainName/MAPI" -IISAuthenticationMethods Ntlm,OAuth,Negotiate

                # Enable Exchange 2016 Certificate
                Enable-ExchangeCertificate -Thumbprint $thumbprint -Services IIS -Confirm:$False

                $InternetSendConnector = Get-SendConnector "$using:Site Internet" -ErrorAction 0
                IF ($InternetSendConnector -eq $Null) {
                New-SendConnector "$using:Site Internet" -AddressSpaces * -SourceTransportServers "$using:computerName"
                }

                # Create Accepted  Domain and Email Address Policies
                IF ($using:ExternalDomainName -ne $using:InternalDomainName){
                    $AcceptedDomain = Get-AcceptedDomain | Where-Object {$_.DomainName -like "$using:ExternalDomainName"}
                    IF ($AcceptedDomain -eq $null){
                    New-AcceptedDomain -Name "$using:ExternalDomainName" -DomainName "$using:ExternalDomainName" -DomainType Authoritative
                    Set-AcceptedDomain -MakeDefault $True -Identity "$using:ExternalDomainName"
                    }

                    $EmailAddressPolicy = Get-EmailAddressPolicy | Where-Object {$_.Name -like "$using:ExternalDomainName"}
                    IF ($EmailAddressPolicy -eq $Null) {
                    New-EmailAddressPolicy -Name "$using:ExternalDomainName" -IncludedRecipients MailboxUsers -EnabledEmailAddressTemplates "SMTP:%s%2g@$using:ExternalDomainName"
                    Update-EmailAddressPolicy -Identity "$using:ExternalDomainName"
                    }
                }
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $DomainCreds
            DependsOn = '[File]Certificates'
        }

        Script ConfigureExchangeSecurityandPerformance
        {
            SetScript =
            {
                # Set PageFile to Manual
                $pagefileset = Get-WmiObject Win32_pagefilesetting
                $pagefileset.InitialSize = 8192
                $pagefileset.MaximumSize = 32778
                $pagefileset.Put() | Out-Null
            
                # Disable SMB1
                Disable-WindowsOptionalFeature -Online -FeatureName smb1protocol
                Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force

                # Set TCP Keep Alive
                $tcpkeepalive = get-itemproperty -Path "HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters" -Name "KeepAliveTime" -ErrorAction 0
                IF ($tcpkeepalive -eq $null) {New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters\" -Name "KeepAliveTime" -Value 1800000}
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $DomainCreds
            DependsOn = '[Script]ConfigureExchange2016'
        }
    }
}