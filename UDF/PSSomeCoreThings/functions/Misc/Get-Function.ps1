function Get-Function {
    <#
    .SYNOPSIS
        Retrieves a function, alias, or command object by name

    .DESCRIPTION
        Looks up a command by name, checking aliases first (resolving to the target),
        then functions, then general commands.

    .PARAMETER Name
        The function, alias, or command name to look up.

    .OUTPUTS
        [FunctionInfo], [AliasInfo], [CommandInfo], or $null.

    .EXAMPLE
        $func = Get-Function "Write-LogInfo"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    Param(
        [Parameter(Mandatory, Position = 0)]
        [ValidatePattern("[a-zA-Z0-9_-]")]
        [string]$Name
    )
    $oAlias = Get-Alias $Name -ErrorAction SilentlyContinue
    if ($oAlias) {
        if ($null -ne $oAlias.ResolvedCommand) {
            return $oAlias.ResolvedCommand
        } else {
            return $null
        }
    }
    $oFunc = Get-Item Function:\$Name -ErrorAction SilentlyContinue
    if ($oFunc) {
        return $oFunc
    }
    $oCommand = Get-Command $Name -ErrorAction SilentlyContinue
    if ($oCommand) {
        return $oCommand
    }
    return $null
}
