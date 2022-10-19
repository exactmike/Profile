## Initial Tenant Setup

### Register an Enterprise App

Attribute | Value
-- | --
Name | Stale Account Management
Supported Account Types | Accounts in this organizational directory only

Note the application (client) ID and the Directory (tenant) ID

### Add a client credential (certificate) to Enterprise App

See Client Certificate Management

### Add required permissions to the Enterprise App

The Stale User Accounts application requires the following permissions:

 - Sign in and read user profile (allows app sign in)
 - Read and write all users' full profiles (allows app to disable a user account)
 - Read all groups (allows app to view groups)
 - Read and write all group memberships (allows app to add and remove members to the application groups)
 - Read all audit log data (allows app to view last logon audit information)

### Add required security groups to Azure AD

 - A group to hold objects that have been disabled and are pending deletion for the DeleteAfterDays period
 - A group to hold objects granted an exception to automated deletion due to stale login activity
 - The objectID of each of these groups will be required for running to application function

## Client Certificate Management

### Requirements

- Windows PowerShell 5.1
- Microsoft's built-in PKI PowerShell Module
- Elevated PowerShell 5.1 instance on the automation server
- Access to Azure AD and permissions to manage the StaleCloudAccountsProcessing application Azure AD

### Steps

#### Create certificate

Suggested Values
```PowerShell
$ValidYears = 1
$ThroughDate = $(Get-Date).AddYears($ValidYears)
$DNSName = '#####.onmicrosoft.com' # replace #### with your tenant's subdomain
```

```PowerShell
$Certificate = New-SelfSignedCertificate -DnsName $DNSName -CertStoreLocation "cert:\CurrentUser\My" -NotAfter $ThroughDate -KeySpec KeyExchange
#OR
"cert:\LocalMachine\My" -NotAfter $ThroughDate -KeySpec KeyExchange
```

#### Export certificate for upload to Azure AD

```PowerShell
$Certificate | Export-Certificate -FilePath PublicCert.cer
```

#### Upload certificate to the StaleCloudAccountsProcessing application in Azure AD


- Navigate to the application in Azure AD Portal and access Certificates & Secrets.
- Click, 'Upload Certificate' and select and add the exported certificate file.
- Verify the certificate thumbprint, start date, and expiration date

#### Update the run script with the new certificate thumbprint

- Update the value provided in the script for the CertificateThumbprint parameter.

### Backup the Certificate (if required)

#### Export certificate to .pfx file with private key

```PowerShell
$CertificateFullFilePath = 'c:\MyCert.cer'
$Password = $(Get-Credential).Password
$Certificate | Export-PfxCertificate -FilePath $CertificateFullFilePath -Password $Password
```
