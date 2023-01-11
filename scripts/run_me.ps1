$os = [System.Environment]::OSVersion.Platform

if($os = "Unix"){
    Write-Host $os
    ./export_logs -OutputPath "../logs"

} else {
    cd C:\Collector\Sentinel
    .\export_logs.ps1 -OutputPath "C:\Collector\Sentinel\Logs"
}