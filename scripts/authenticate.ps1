# Authenticate to Exchange Online
Connect-ExchangeOnline -CertificateThumbPrint $env:graph_certificate `
-AppID $env:graph_client_id `
-Organization $env:graph_tenant_domain

Search-UnifiedAuditLog -StartDate 5/21/2022 -EndDate 5/22/2022

$mydocuments = [environment]::getfolderpath("mydocuments")

$DlpPol = Export-DlpPolicyCollection
[System.IO.File]::WriteAllBytes("$mydocuments\Contoso PII2.xml", $DlpPol.FileData)

<#
# Authenticate to Security and Compliance                       
Connect-IPPSSession -CertificateThumbPrint $env:graph_certificate `
-AppID $env:graph_client_id `
-Organization $env:graph_tenant_domain



#>

# Get-AuditConfigurationRule | Format-List Name,Workload,AuditOperation,Policy                    

<#
$output = Export-ActivityExplorerData -StartTime "07/08/2022 07:15 AM" -EndTime "07/08/2022 11:08 AM" -PageSize 5000 -OutputFormat Json

foreach ($item in $output.psobject.Properties){
    Write-Host $item.DataType
}
#>

$Perms = Get-ManagementRole -Cmdlet Export-DlpPolicyCollection
Write-Host $Perms

