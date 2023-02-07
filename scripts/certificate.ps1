# Create certificate
$mycert = New-SelfSignedCertificate -DnsName "<dns name>" -CertStoreLocation "cert:\CurrentUser\My" -NotAfter (Get-Date).AddYears(1) -KeySpec KeyExchange
# Export certificate to .pfx file
$mycert | Export-PfxCertificate -FilePath Sentinel.pfx -Password (Get-Credential).password
# Export certificate to .cer file
$mycert | Export-Certificate -FilePath Sentinel.cer 