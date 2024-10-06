function Get-CommandProxy {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Command
    )
    $metadata = New-Object system.management.automation.commandmetadata (Get-Command $Command)
    return [System.management.automation.proxycommand]::Create($MetaData) 
}