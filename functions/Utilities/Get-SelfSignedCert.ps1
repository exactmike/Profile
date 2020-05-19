Function Get-SelfSignedCert
{
  [cmdletbinding()]
  param(
    $TenantName = "contoso.onmicrosoft.com" # Your tenant name (can something more descriptive as well)
    ,
    $FilePath = "C:\Temp\PowerShellGraphCert.cer" # Where to export the certificate without the private key
    ,
    $CertificateStorePath = "Cert:\CurrentUser\My" # What cert store you want it to be in
    ,
    $ExpirationDate = (Get-Date).AddYears(2) # Expiration date of the new certificate
  )
  # Splat for readability
  $CertificateSplat = @{
    FriendlyName      = "AzureADApp"
    DnsName           = $TenantName
    CertStoreLocation = $CertificateStorePath
    NotAfter          = $ExpirationDate
    KeyExportPolicy   = "Exportable"
    KeySpec           = "Signature"
    Provider          = "Microsoft Enhanced RSA and AES Cryptographic Provider"
    HashAlgorithm     = "SHA256"
  }

  # Create certificate
  $Certificate = New-SelfSignedCertificate @CertificateSplat

  # Get certificate path
  $CertificatePath = Join-Path -Path $CertificateStorePath -ChildPath $Certificate.Thumbprint

  # Export certificate without private key
  Export-Certificate -Cert $CertificatePath -FilePath $FilePath | Out-Null
}
