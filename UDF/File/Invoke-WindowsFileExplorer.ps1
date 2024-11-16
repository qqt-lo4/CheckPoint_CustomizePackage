function Invoke-WindowsFileExplorer {
    Param(
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_})]
        [string]$Path
    )
    if ($Path.Contains(",")) {
        throw "Unsupported Path: a bug in explorer.exe prevent opening path that contains commas"
    }
    &explorer $Path
}