# Authenticate to Exchange Online
Connect-ExchangeOnline -CertificateThumbPrint $env:graph_certificate `
                       -AppID $env:graph_client_id `
                       -Organization $env:graph_tenant_domain

# Authenticate to Security and Compliance                       
Connect-IPPSSession -CertificateThumbPrint $env:graph_certificate `
                    -AppID $env:graph_client_id `
                    -Organization $env:graph_tenant_domain