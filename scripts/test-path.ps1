$Path = (Get-Location).Path

$CONFIGFILE = "$Path/config.json"   
$SCHEMASFILE = "$Path/schema.json"   

Write-Host "This is the schema path $SCHEMASFILE"

if (-not (Test-Path -Path $SCHEMASFILE))
{
    Write-Host "Schemas file is missing. Default list of subscriptions will be used."
}

$json = Get-Content -Raw -Path $SCHEMASFILE
[PSCustomObject]$schemas = ConvertFrom-Json -InputObject $json
foreach ($item in $schemas.psobject.Properties)
{
    if ($schemas."$($item.Name)" -eq "True")
    {
        $Subscriptions += $item.Name
    }
}
Write-Host "Subscriptions list: $Subscriptions"    