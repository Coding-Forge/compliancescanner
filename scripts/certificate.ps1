# Create certificate
$mycert = New-SelfSignedCertificate -DnsName $env:my_tenant_domain -CertStoreLocation "cert:\CurrentUser\My" -NotAfter (Get-Date).AddYears(1) -KeySpec KeyExchange
# Export certificate to .pfx file
$mycert | Export-PfxCertificate -FilePath Sentinel.pfx -Password (Get-Credential).password
# Export certificate to .cer file
$mycert | Export-Certificate -FilePath Sentinel.cer 

## Pull out the Thumbprint to be used for Automation
$cert = Get-ChildItem Cert:\CurrentUser\My | where{$_.Subject -eq "CN=$env:my_tenant_domain"}
Write-Host $cert.Thumbprint