function Get-CommandProxy {
    <#
    .SYNOPSIS
        Creates a proxy command for a PowerShell command

    .DESCRIPTION
        Generates a proxy command script block from an existing PowerShell command.
        Proxy commands allow wrapping or extending existing cmdlets with additional logic.

    .PARAMETER Command
        Name of the command to create a proxy for.

    .OUTPUTS
        [String]. Proxy command script block.

    .EXAMPLE
        Get-CommandProxy -Command "Get-Process"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Command
    )
    $metadata = New-Object system.management.automation.commandmetadata (Get-Command $Command)
    return [System.management.automation.proxycommand]::Create($MetaData) 
}