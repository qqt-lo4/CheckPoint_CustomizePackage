function Get-Function {
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
