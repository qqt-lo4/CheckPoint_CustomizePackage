function New-NetworkMap {
    <#
    .SYNOPSIS
        Creates a new network drive mapping

    .DESCRIPTION
        Maps a network UNC path to a local drive letter using net use.
        Supports %username% placeholder in the remote path.

    .PARAMETER Name
        The drive letter to assign (e.g., "Z" or "Z:").

    .PARAMETER Root
        The UNC remote path (e.g., "\\server\share"). Supports %username% placeholder.

    .OUTPUTS
        None. Creates the network mapping via net use.

    .EXAMPLE
        New-NetworkMap -Name "Z" -Root "\\server\share"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [string]$Root
    )
    $sRemotePath = $Root -replace "%username%", $env:USERNAME
    $sDriveLetter = if ($Name -match "[a-zA-Z]:") {
        $Name
    } elseif ($Name -match "[a-zA-Z]") {
        $Name + ":"
    } else {
        throw "Invalid drive letter"
    }
    &net use $sDriveLetter $sRemotePath
    #New-SmbMapping -LocalPath $sDriveLetter -RemotePath $sRemotePath -Persistent $true -ErrorAction Stop
}