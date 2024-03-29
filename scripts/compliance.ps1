<#
.NOTES
              Version:        2.7
              Author:         Walid Elmorsy - Principal Program Manager - Compliance CAT team.
                              Brendon Lee - Senior Program Manager - Compliance CAT team
              Creation Date:  11/11/2021
              Purpose :       Collect Microsoft 365 Compliance Audit Log Activity Information via Office 365 Management API endpoints, and export to JSON files (For testing purposes only)
#> 

#------------------------------------------------------------------------------  
#  
#   
# This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  
# THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, 
# INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
# We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code 
# form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in 
# which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code is 
# embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, 
# including attorneys fees, that arise or result from the use or distribution of the Sample Code.
#  
#------------------------------------------------------------------------------ 

#API Endpoint URLs ---> Don't Update anything here
$Enterprise = "https://manage.office.com"
$GCC = "https://manage-gcc.office.com"
$GCCH = "https://manage.office365.us"
$DOD = "https://manage.protection.apps.mil"

# Script variables 01  --> Update everything in this section:
$AppClientID = $env:graph_client_id
$ClientSecretValue = $env:graph_client_secret
$TenantGUID = $env:graph_tenant_id
$tenantdomain = $env:graph_tenant_domain
$OutputPath = "../logs/"
$APIResource = $Enterprise  #(Your tenant endpoint URL choice here)


# Script variables 02  ---> Don't Update anything here:
$loginURL = "https://login.microsoftonline.com/"
$BaseURI = "$APIResource/api/v1.0/$tenantGUID/activity/feed/subscriptions"
$Subscriptions = @('Audit.AzureActiveDirectory','Audit.Exchange','Audit.SharePoint','Audit.General','DLP.All')

#$Date = Get-date
$Date = (Get-date).AddDays(-265)

# Invoke-WebRequest -Method GET -Headers $OfficeToken -Uri "$BaseURI/content?contentType=$Subscription&startTime=$Date022T00:00&endTime=$Date022T23:59&PublisherIdentifier=$TenantGUID" ErrorAction Stop
# Create Function to Check content availability in all content types (inlcuding all pages) and store results in $Subscription variable, also build the URI list in the correct format
function buildLog($BaseURI, $Subscription, $tenantGUID, $OfficeToken, $StartDate, $EndDate){

        try {
            write-host 'good to go'
            $Log = Invoke-WebRequest -Method GET -Headers $OfficeToken -Uri "$BaseURI/content?contentType=$Subscription&PublisherIdentifier=$TenantGUID&startTime=$StartDate&endTime=$EndDate" -UseBasicParsing -ErrorAction Stop
        } catch {
                write-host -ForegroundColor Red "Invoke-WebRequest command has failed"
                Write-host $error[0]
                return
        }
            #Try to find if there is a NextPage in the returned URI
        if ($Log.Headers.NextPageUri) {
            $NextContentPage = $true
            $NextContentPageURI = $Log.Headers.NextPageUri
            while ($NextContentPage -ne $false) {
                $ThisContentPage = Invoke-WebRequest -Headers $OfficeToken -Uri $NextContentPageURI -UseBasicParsing
                $TotalContentPages += $ThisContentPage

                if ($ThisContentPage.Headers.NextPageUri)
                {
                    $NextContentPage = $true    
                }
                Else{
                    $NextContentPage = $false
                }
                $NextContentPageURI = $ThisContentPage.Headers.NextPageUri
            }
        } 
        $TotalContentPages += $Log
    Write-Host -ForegroundColor Green "OK"
    return $TotalContentPages
}


# Access token Request and Retrieval 
$body = @{grant_type="client_credentials";resource=$APIResource;client_id=$AppClientID;client_secret=$ClientSecretValue}
Write-Host -ForegroundColor Blue -BackgroundColor white "Obtaining authentication token..." -NoNewline
try{
    $oauth = Invoke-RestMethod -Method Post -Uri "$loginURL/$tenantdomain/oauth2/token?api-version=1.0" -Body $body -ErrorAction Stop
    $OfficeToken = @{'Authorization'="$($oauth.token_type) $($oauth.access_token)"}
    Write-Host -ForegroundColor Green "Authentication token obtained"
} catch {
    write-host -ForegroundColor Red "FAILED"
    write-host -ForegroundColor Red "Invoke-RestMethod failed."
    Write-host -ForegroundColor Red $error[0]
    exit
}


#create new Subscription (if needed)

Write-Host -ForegroundColor Blue -BackgroundColor white "Creating Subscriptions...."

foreach($Subscription in $Subscriptions){
    Write-Host -ForegroundColor Cyan "$Subscription : " -NoNewline
    try { 
        $response = Invoke-WebRequest -Method Post -Headers $OfficeToken -Uri "$BaseURI/start?contentType=$Subscription" -UseBasicParsing -ErrorAction Stop
    } catch {
        if(($error[0] | ConvertFrom-Json).error.message -like "The subscription is already enabled*"){
            Write-host -ForegroundColor Yellow "Subscription already Exists"
        } else {
            write-host -ForegroundColor Red "Failed to create a subscription for $Subscription"
            Write-host -Foregroundcolor Red $error[0]
        }
    }
}


#Check subscription status
$CheckSubTemp = Invoke-WebRequest -Headers $OfficeToken -Uri "$BaseURI/list" -UseBasicParsing
Write-Host -ForegroundColor Blue -BackgroundColor white "Subscription Content Status"
$CheckSub = $CheckSubTemp.Content | convertfrom-json
$CheckSub | %{write-host $_.contenttype "--->" -nonewline; write-host $_.status -ForegroundColor Green}
 

#Check folder path and construct file names
function getFileName($Date, $Subscription, $OutputPath){
    #path should end with \
    if (!$OutputPath.EndsWith("\"))
    {
        $OutputPath += "\"
    }

    # path should not be on root drive
    if ($OutputPath.EndsWith(":\"))
    {
        $OutputPath += "apilogs\"
    }

    # verify folder exists, if not try to create it
    if (!(Test-Path($OutputPath)))
    {
        Write-Host -ForegroundColor Yellow ">> Warning: '$OutputPath' does not exist. Creating one now..."
        Write-host -ForegroundColor Gray "Creating '$OutputPath': " -NoNewline
        try
        {
            New-Item -ItemType "directory" -Path $OutputPath -ErrorAction Stop | Out-Null
            Write-Host -ForegroundColor Green "Path '$OutputPath' has been created successfully"
        } catch {
            write-host -ForegroundColor Red "FAILED to create '$OutputPath'"
            Write-Host -ForegroundColor Red ">> ERROR: The directory '$OutputPath' could not be created."
            Write-Host -ForegroundColor Red $error[0]
           }
           }
           else{
            Write-Host -ForegroundColor Green "Path '$OutputPath' already exists"
            }

    $JSONfilename = ($Subscription + "_" + $Date + ".json")
    return $OutputPath + $JSONfilename
}


#Generate the correct URI format and export  logs
function outputToFile($TotalContentPages, $JSONfilename, $Officetoken){
    if($TotalContentPages.content.length -gt 2){
        $uris = @()
        $pages = $TotalContentPages.content.split(",")
        
        foreach($page in $pages){
            if($page -match "contenturi"){
                $uri = $page.split(":")[2] -replace """"
                $uri = "https:$uri"
                $uris += $uri
            }
        }
        foreach($uri in $uris){
            try{
                $Logdata += Invoke-RestMethod -Uri $uri -Headers $Officetoken -Method Get
                $Logdata | ConvertTo-Json -Depth 100 | Set-Content -Encoding UTF8 $JSONfilename
            } catch {
                write-host -ForegroundColor Red "ERROR"
                Write-host $error[0]
                return
            }      
        }
        write-host -ForegroundColor Green "OK"
    } else {
        Write-Host -ForegroundColor Yellow "Nothing to output"
    }
}


#Collecting and Exporting Log data
Write-Host -ForegroundColor Blue -BackgroundColor white "Checking output folder path"

$Date = (Get-date).AddDays(-6)
#$Date = $Date.ToString('MM-dd-yyyy hh:mm:ss')

while((Get-date).AddDays(-1) -ge ($Date)){
    $StartDate = $Date.ToString("yyyy-MM-ddT00:00")
    $EndDate = $Date.ToString("yyyy-MM-ddT23:59")
    $JSONfileName = getFileName $StartDate $Subscription $outputPath
    $Date = $Date.AddDays(1)

    Write-Host -ForegroundColor Blue -BackgroundColor white "Collecting and Exporting Log data"
    foreach($Subscription in $Subscriptions){
        
        Write-Host -ForegroundColor Cyan "-> Collecting log data from '" -NoNewline
        Write-Host -ForegroundColor White -BackgroundColor DarkGray $Subscription -NoNewline
        Write-Host -ForegroundColor Cyan "': " -NoNewline
        $logs = buildLog $BaseURI $Subscription $TenantGUID $OfficeToken $StartDate $EndDate
    
        $JSONfilename = ($OutputPath + $Subscription + "_" + $StartDate + ".json")
      
        Write-host -ForegroundColor Cyan "---> Exporting log data to '" -NoNewline
        Write-Host -ForegroundColor White -BackgroundColor DarkGray $JSONfilename -NoNewline
        Write-Host -ForegroundColor Cyan "': " -NoNewline
        outputToFile $logs $JSONfilename $OfficeToken
    }

}
