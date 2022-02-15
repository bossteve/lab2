$ConfigContext = ([ADSI]"LDAP://RootDSE").ConfigurationNamingContext 
$ADSI = [ADSI]"LDAP://CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext" 

$NewWebTempl = $ADSI.Create("pKICertificateTemplate", "CN=WebServer1") 
$NewWebTempl.put("distinguishedName","CN=WebServer1,CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext") 
$NewWebTempl.put("flags","131680")
$NewWebTempl.put("displayName","Web Server1")
$NewWebTempl.put("revision","100")
$NewWebTempl.put("pKIDefaultKeySpec","1")
$NewWebTempl.SetInfo()
$NewWebTempl.put("pKIMaxIssuingDepth","0")
$NewWebTempl.put("pKICriticalExtensions","2.5.29.15")
$NewWebTempl.put("pKIExtendedKeyUsage","1.3.6.1.5.5.7.3.1")
$NewWebTempl.put("pKIDefaultCSPs","1,Microsoft RSA SChannel Cryptographic Provider")
$NewWebTempl.put("msPKI-RA-Signature","0")
$NewWebTempl.put("msPKI-Enrollment-Flag","8")
$NewWebTempl.put("msPKI-Private-Key-Flag","16842768")
$NewWebTempl.put("msPKI-Certificate-Name-Flag","1")
$NewWebTempl.put("msPKI-Minimal-Key-Size","2048")
$NewWebTempl.put("msPKI-Template-Schema-Version","2")
$NewWebTempl.put("msPKI-Template-Minor-Revision","2")
$NewWebTempl.put("msPKI-Cert-Template-OID","1.3.6.1.4.1.311.21.8.7183632.6046387.16009101.13536898.4471759.164.5869043.12046343")
$NewWebTempl.put("msPKI-Certificate-Application-Policy","1.3.6.1.5.5.7.3.1")
$NewWebTempl.SetInfo()

$BaseWebTempl = $ADSI.psbase.children | where {$_.displayName -eq "Web Server"}

$NewWebTempl.pKIKeyUsage = $BaseWebTempl.pKIKeyUsage
$NewWebTempl.pKIExpirationPeriod = $BaseWebTempl.pKIExpirationPeriod
$NewWebTempl.pKIOverlapPeriod = $BaseWebTempl.pKIOverlapPeriod
$NewWebTempl.SetInfo()
$NewWebTempl | select *

$acl = $NewWebTempl.psbase.ObjectSecurity
$acl | select -ExpandProperty Access
$AdObj = New-Object System.Security.Principal.NTAccount("Authenticated Users")
$identity = $AdObj.Translate([System.Security.Principal.SecurityIdentifier])
$adRights = "ReadProperty, ExtendedRight, GenericExecute"
$type = "Allow"
$ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($identity,$adRights,$type)
$NewWebTempl.psbase.ObjectSecurity.SetAccessRule($ACE)
$NewWebTempl.psbase.commitchanges()

$NewOCSPTempl = $ADSI.Create("pKICertificateTemplate", "CN=OCSPResponseSigning1") 
$NewOCSPTempl.put("distinguishedName","CN=OCSPResponseSigning1,CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext") 
$NewOCSPTempl.put("flags","66112")
$NewOCSPTempl.put("displayName","OCSP Response Signing1")
$NewOCSPTempl.put("revision","100")
$NewOCSPTempl.put("pKIDefaultKeySpec","2")
$NewOCSPTempl.SetInfo()
$NewOCSPTempl.put("pKIMaxIssuingDepth","0")
$NewOCSPTempl.put("pKICriticalExtensions","2.5.29.15")
$NewOCSPTempl.put("pKIExtendedKeyUsage","1.3.6.1.5.5.7.3.9")
$NewOCSPTempl.put("pKIDefaultCSPs","1,Microsoft Software Key Storage Provider")
$NewOCSPTempl.put("msPKI-RA-Signature","0")
$NewOCSPTempl.put("msPKI-RA-Application-Policies",'msPKI-Asymmetric-Algorithm`PZPWSTR`RSA`msPKI-Hash-Algorithm`PZPWSTR`SHA256`')
$NewOCSPTempl.put("msPKI-Enrollment-Flag","20480")
$NewOCSPTempl.put("msPKI-Private-Key-Flag","0")
$NewOCSPTempl.put("msPKI-Certificate-Name-Flag","402653184")
$NewOCSPTempl.put("msPKI-Minimal-Key-Size","2048")
$NewOCSPTempl.put("msPKI-Template-Schema-Version","3")
$NewOCSPTempl.put("msPKI-Template-Minor-Revision","8")
$NewOCSPTempl.put("msPKI-Cert-Template-OID","1.3.6.1.4.1.311.21.8.11803725.16015575.3099577.1880784.14317363.53.1.32")
$NewOCSPTempl.put("msPKI-Certificate-Application-Policy","1.3.6.1.5.5.7.3.9")
$NewOCSPTempl.SetInfo()

$BaseNewOCSPTempl = $ADSI.psbase.children | where {$_.displayName -eq "OCSP Response Signing"}
$BaseWebTempl = $ADSI.psbase.children | where {$_.displayName -eq "Web Server"}

$NewOCSPTempl.pKIKeyUsage = $BaseNewOCSPTempl.pKIKeyUsage
$NewOCSPTempl.pKIExpirationPeriod = $BaseWebTempl.pKIExpirationPeriod
$NewOCSPTempl.pKIOverlapPeriod = $BaseWebTempl.pKIOverlapPeriod
$NewOCSPTempl.SetInfo()
$NewOCSPTempl | select *

$acl = $NewOCSPTempl.psbase.ObjectSecurity
$acl | select -ExpandProperty Access
$AdObj = New-Object System.Security.Principal.NTAccount("Authenticated Users")
$identity = $AdObj.Translate([System.Security.Principal.SecurityIdentifier])
$adRights = "ReadProperty, ExtendedRight, GenericExecute"
$type = "Allow"
$ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($identity,$adRights,$type)
$NewOCSPTempl.psbase.ObjectSecurity.SetAccessRule($ACE)
$NewOCSPTempl.psbase.commitchanges()

certsrv
Start-Sleep 30
Add-CATemplate -Name 'WebServer1' -Force
Add-CATemplate -Name 'OCSPResponseSigning1' -Force