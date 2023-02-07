$Date = (Get-date).AddDays(-5)
$Date = $Date.ToString('MM-dd-yyyy hh:mm:ss')

$num = 5

Write-Host 'this is the starting date: '$Date
while((Get-date).ToString('MM-dd-yyyy hh:mm:ss') -ge ($Date)){
    $Date=[datetime]$Date
    $Date = $Date.AddDays(1)
    $Date = $Date.ToString('MM-dd-yyyy hh:mm:ss')
    Write-Host 'this is the calculated date: '$Date

}

