# Exchange 2016 Single-Site with External Access
<img src="../x_Images/Exchange2016SingleSite.png" alt="Exchange 2016" width="150">
Click a button below to deploy to the cloud of your choice

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fbossteve%2Flab1%2Fmain%2FExchange2016-Single-Site-with-External-Access%2Fazuredeploy.json)
[![Deploy To Azure US Gov](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.svg?sanitize=true)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Felliottfieldsjr%2FKillerHomeLab%2Fmaster%2FDeployments%2FExchange2016-Single-Site-with-External-Access%2Fazuredeploy.json)

!!!!NOTE:  PLEASE MAKE SURE TO APPLY CRITICAL SECURITY UPDATE KB5000871 TO BOTH EXCHANGE SERVERS AFTER THE DEPLOYMENT IS COMPLETE.

This Templates deploys a Single Forest/Domain:

- 1 - Active Directory Forest/Domain
- 1 - Active Directory Site
- 1 - Domain Controller
- 1 - Offline Root Certificate Authority Server
- 1 - Issuing Certificate Authority Server
- 1 - Online Certificate Status Protocol Server
- 1 - Exchange 2016 Organization
- 1 - Exchange 2016 Server
- 1 - File Share Witness Server
- 1 - Database Availability Group
- 1 - Domain Joined Window 11, 10 or 7 Workstation
- 1 - Azure DNS Zone (Created based on NetBiosDomain and TLD Parameters)
- 1 - Network Security Group (1 Created in each Region)

The deployment also makes the following customizations:
- Adds Public IP Address to OCSP and Exchange Servers.
- Creates Azure DNS Zone Records based on the correesponding Servers Public IP
- -- OCSP (OCSP VM Public IP)
- -- OWA2016 (Exchange VM1 Public IP)
- -- AUTODISCOVER2016 (Exchange VM1 Public IP)
- -- OUTLOOK2016 (Exchange VM1 Public IP)
- -- EAS2016 (Exchange VM1 Public IP)
- -- SMTP (Exchange VM1 Public IP)

The deployment leverages Desired State Configuration scripts to further customize the following:

AD OU Structure:
- [domain.com]
- -- Accounts
- --- End User
- ---- Office 365
- ---- Non-Office 365
- --- Admin
- --- Service
- -- Groups
- --- End User
- --- Admin
- -- Servers
- --- Servers2012R2
- --- Serverrs2016
- --- Servers2019
- --- Servers2022
- -- MaintenanceServers
- -- MaintenanceWorkstations
- -- Workstations
- --- Windows10
- --- Windows10
- --- Windows7

AD DNS Zone Record Creation:
- CRL (For CRL Download)
- OCSP (For OCSP Server)
- OWA2016 (For Exchange Server1)
- AUTODISCOVER2016 (For Exchange Server1)
- OUTLOOK2016 (For Exchange Server1)
- EAS2016 (For Exchange Server1)
- SMTP (For Exchange Server1)

PKI
- Offline Root CA Configuaration
- Issuing CA Configuration
- OCSP Configuaration

Exchange
- File Share Witness Creation
- Exchange 2016 OS Prerequisites
- Exchange 2016 Installation
- Request/Receive Exchange 2016 SAN Certificate from Issuing CA
- Exchange 2016 Certificate Enablement
- Exchange Virtual Directory Internal/External Configuration
- Exchange Virtual Directory Authentication Configuration
- DAG Creation and Adding both Exchange Servers

Parameters that support changes
- TimeZone.  Select an appropriate Time Zone.
- AutoShutdownEnabled.  Yes = AutoShutdown Enabled, No = AutoShutdown Disabled.
- AutoShutdownTime.  24-Hour Clock Time for Auto-Shutdown (Example: 1900 = 7PM)
- AutoShutdownEmail.  Auto-Shutdown notification Email (Example:  user@domain.com)
- Exchange Org Name. Enter a name that will be used for your Exchange Organization Name.
- Exchange2016ISOUrl.  You must enter a URL or created SAS URL that points to an Exchange 2016 ISO for this installation to be successful.
- Admin Username.  Enter a valid Admin Username
- Admin Password.  Enter a valid Admin Password
- To Email.  Please provide a working email address that the Trusted Certificate Authority Chain Can be sent to.  These certificates will allow access to Exchange Services like OWA, 
- WindowsServerLicenseType.  Choose Windows Server License Type (Example:  Windows_Server or None)
- WindowsClientLicenseType.  Choose Windows Client License Type (Example:  Windows_Client or None)
EAS and Outlook without Certificate Security warnings. (Depending on What Public IP you get initially.  Exchange mailflow may be blocked if it's blacklisted)
- Naming Convention. Enter a name that will be used as a naming prefix for (Servers, VNets, etc) you are using.
- Sub DNS Domain.  OPTIONALLY, enter a valid DNS Sub Domain. (Example:  sub1. or sub1.sub2.    This entry must end with a DOT )
- Sub DNS BaseDN.  OPTIONALLY, enter a valid DNS Sub Base DN. (Example:  DC=sub1, or DC=sub1,DC=sub2,    This entry must end with a COMMA )
- Net Bios Domain.  Enter a valid Net Bios Domain Name (Example:  killerhomelab).
- Internal Domain.  Enter a valid Internal Domain (Exmaple:  killerhomelab)
- InternalTLD.  Select a valid Top-Level Domain for your Internal Domain using the Pull-Down Menu.
- External Domain.  Enter a valid External Domain (Exmaple:  killerhomelab)
- ExternalTLD.  Select a valid Top-Level Domain for your External Domain using the Pull-Down Menu.
- Vnet1ID.  Enter first 2 octets of your desired Address Space for Virtual Network 1 (Example:  10.1)
- Reverse Lookup1.  Enter first 2 octets of your desired Address Space in Reverse (Example:  1.10)
- Root CA Name.  Enter a Name for your Root Certificate Authority
- Issuing CA Name.  Enter a Name for your Issuing Certificate Authority
- RootCAHashAlgorithm.  Hash Algorithm for Offline Root CA
- RootCAKeyLength.  Key Length for Offline Root CA
- IssuingCAHashAlgorithm.  Hash Algorithm for Issuing CA
- IssuingCAKeyLength.  Key Length for Issuing CA
- DC1OSVersion.  Select 2022-Datacenter (Windows 2022), 2019-Datacenter (Windows 2019) or 2016-Datacenter (Windows 2016) Domain Controller 1 OS Version
- RCAOSVersion.  Select 2022-Datacenter (Windows 2022), 2019-Datacenter (Windows 2019) or 2016-Datacenter (Windows 2016) Root CA OS Version
- ICAOSVersion.  Select 2022-Datacenter (Windows 2022), 2019-Datacenter (Windows 2019) or 2016-Datacenter (Windows 2016) Issuing CA OS Version
- OCSPOSVersion.  Select 2022-Datacenter (Windows 2022), 2019-Datacenter (Windows 2019) or 2016-Datacenter (Windows 2016) OCSP OS Version
- FSOSVersion.  Select 2022-Datacenter (Windows 2022), 2019-Datacenter (Windows 2019) or 2016-Datacenter (Windows 2016) File ShareWiteness OS Version
- EXOSVersion.  Exchange Servers OS Version is not configurable and set to 2016-Datacenter (Windows 2016).
- WK1OSVersion.  Select Windows-11, Windows-10 or Windows-7 Worksation 1 OS Version
- WK2OSVersion.  Select Windows-11, Windows-10 or Windows-7 Worksation 1 OS Version
- DC1VMSize.  Enter a Valid VM Size based on which Region the VM is deployed.
- RCAVMSize.  Enter a Valid VM Size based on which Region the VM is deployed.
- ICAVMSize.  Enter a Valid VM Size based on which Region the VM is deployed.
- OCSPVMSize.  Enter a Valid VM Size based on which Region the VM is deployed.
- FS1VMSize.  Enter a Valid VM Size based on which Region the VM is deployed.
- EX1VMSize.  Enter a Valid VM Size based on which Region the VM is deployed.
- WK1VMSize.  Enter a Valid VM Size based on which Region the VM is deployed.