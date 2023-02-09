<#
## Audit Log Record Type

Member name	                          |  Description
----------------------------------------------------
ExchangeAdmin	
ExchangeItem	
ExchangeItemGroup	
SharePoint	
SyntheticProbe	
SharePointFileOperation	
OneDrive	
AzureActiveDirectory	
AzureActiveDirectoryAccountLogon	
DataCenterSecurityCmdlet
#>

$startValue = -285


# get the path to the current users My Documents
$mydocuments = [environment]::getfolderpath("mydocuments")

#Modify the values for the following variables to configure the audit log search.
[DateTime]$start = [DateTime]::UtcNow.AddDays($startValue)
[DateTime]$end = [DateTime]::UtcNow.AddDays($startValue+30)
#$record = "SharePoint"
$resultSize = 5000
$intervalMinutes = 60

#Start script
[DateTime]$currentStart = $start
[DateTime]$currentEnd = $end

Function Write-LogFile ([String]$Message, [String]$logFile)
{
    $final = [DateTime]::Now.ToUniversalTime().ToString("s") + ":" + $Message
    $final | Out-File $logFile -Append
}

$RecordTypes = @(
    "OneDrive",	
    "ExchangeAdmin",	
    "ExchangeItem",	
    "ExchangeItemGroup",	
    "SharePoint",	
    "SyntheticProbe",	
    "SharePointFileOperation",	
    "AzureActiveDirectory",	
    "AzureActiveDirectoryAccountLogon",	
    "DataCenterSecurityCmdlet"
)

Function Get-Records([string]$record) {


    # Authenticate to Exchange Online
    Connect-ExchangeOnline -CertificateThumbPrint $env:graph_certificate `
                            -AppID $env:graph_client_id `
                            -Organization $env:graph_tenant_domain


    $logFile = "$mydocuments\AuditLogSearchLog_$record.txt"
    $outputFile = "$mydocuments\AuditLogRecords_$record.csv"

    Write-LogFile "BEGIN: Retrieving audit records between $($start) and $($end), RecordType=$record, PageSize=$resultSize." $logFile
    Write-Host "Retrieving audit records for the date range between $($start) and $($end), RecordType=$record, ResultsSize=$resultSize"

    $totalCount = 0
    while ($true)
    {
        $currentEnd = $currentStart.AddMinutes($intervalMinutes)
        if ($currentEnd -gt $end)
        {
            $currentEnd = $end
        }
        
        if ($currentStart -eq $currentEnd)
        {
            break
        }

        $sessionID = [Guid]::NewGuid().ToString() + "_" +  "ExtractLogs" + (Get-Date).ToString("yyyyMMddHHmmssfff")
        Write-LogFile "INFO: Retrieving audit records for activities performed between $($currentStart) and $($currentEnd)" $logFile
        Write-Host "Retrieving audit records for activities performed between $($currentStart) and $($currentEnd)"
        $currentCount = 0

        $sw = [Diagnostics.StopWatch]::StartNew()
        do
        {
            $results = Search-UnifiedAuditLog -StartDate $currentStart -EndDate $currentEnd -RecordType $record -SessionId $sessionID -SessionCommand ReturnLargeSet -ResultSize $resultSize
            
            if (($results | Measure-Object).Count -ne 0)
            {
                $results | export-csv -Path $outputFile -Append -NoTypeInformation
                
                $currentTotal = $results[0].ResultCount
                $totalCount += $results.Count
                $currentCount += $results.Count
                Write-LogFile "INFO: Retrieved $($currentCount) audit records out of the total $($currentTotal)" $logFile
                
                if ($currentTotal -eq $results[$results.Count - 1].ResultIndex)
                {
                    $message = "INFO: Successfully retrieved $($currentTotal) audit records for the current time range. Moving on!"
                    Write-LogFile $message $logFile
                    Write-Host "Successfully retrieved $($currentTotal) audit records for the current time range. Moving on to the next interval." -foregroundColor Yellow
                    ""
<<<<<<< HEAD
                    break
=======
                    # break
>>>>>>> 37c188a50227f2ca52f9b8467ae1ec242196ea5e
                }
            }
        }
        while (($results | Measure-Object).Count -ne 0)
        
        $currentStart = $currentEnd
    }

    Write-LogFile "END: Retrieving audit records between $($start) and $($end), RecordType=$record, PageSize=$resultSize, total count: $totalCount." -logFile $logFile
    Write-Host "Script complete! Finished retrieving audit records for the date range between $($start) and $($end). Total count: $totalCount" -foregroundColor Green

}


foreach ($record in $RecordTypes){
    Get-Records -record $record
}
