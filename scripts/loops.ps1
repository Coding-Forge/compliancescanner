$RecordTypes = @(
    "ExchangeAdmin",	
    "ExchangeItem",	
    "ExchangeItemGroup",	
    "SharePoint",	
    "SyntheticProbe",	
    "SharePointFileOperation",	
    "OneDrive",	
    "AzureActiveDirectory",	
    "AzureActiveDirectoryAccountLogon",	
    "DataCenterSecurityCmdlet"
)

foreach ($item in $RecordTypes){
    Write-Host "This is the record type: [$item]"
}