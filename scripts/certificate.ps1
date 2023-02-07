# Create certificate
$mycert = New-SelfSignedCertificate -DnsName $env:graph_tenant_domain -CertStoreLocation "cert:\CurrentUser\My" -NotAfter (Get-Date).AddYears(1) -KeySpec KeyExchange
# Export certificate to .pfx file
$mycert | Export-PfxCertificate -FilePath Sentinel.pfx -Password (Get-Credential).password
# Export certificate to .cer file
$mycert | Export-Certificate -FilePath Sentinel.cer 