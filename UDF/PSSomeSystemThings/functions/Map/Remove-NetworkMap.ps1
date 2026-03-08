function Remove-NetworkMap {
    <#
    .SYNOPSIS
        Removes a network drive mapping

    .DESCRIPTION
        Disconnects a mapped network drive using net use /d.

    .PARAMETER Name
        The drive letter to disconnect (e.g., "Z" or "Z:").

    .OUTPUTS
        None. Removes the network mapping via net use.

    .EXAMPLE
        Remove-NetworkMap -Name "Z"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdLetBinding()]
    Param(
        [string]$Name
    )
    $sDriveLetter = if ($Name -match "[a-zA-Z]:") {
        $Name
    } elseif ($Name -match "[a-zA-Z]") {
        $Name + ":"
    } else {
        throw "Invalid drive letter"
    }
    &net use $sDriveLetter /d /y
}
