function Expand-CABFile {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$CABFile,
        [Parameter(Position = 1)]
        [string]$Destination,
        [Parameter(Position = 2)]
        [string]$Filename
    )
    if (Test-Path -Path $CABFile -PathType Leaf) {
        $sFilename = if ($Filename) { $Filename } else { "*" }
        $sCommandResult = (expand -F:$sFilename $CABFile $Destination)
        return $sCommandResult
    } else {
        throw [System.IO.FileNotFoundException] "`$CABFile not found"
    }
}