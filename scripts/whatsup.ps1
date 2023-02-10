$currentPath = (Split-Path $MyInvocation.MyCommand.Definition -Parent)
Import-Module "$currentPath\utils\utils.psm1" -Force

Show-Calendar -start "2018-05-10"