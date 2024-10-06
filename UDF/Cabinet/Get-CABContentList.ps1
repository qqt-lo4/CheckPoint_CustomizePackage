function Get-CABContentList {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$CABFile
    )
    $sCommandResult = (&expand -D $CABFile)
    $sCommandResult = $sCommandResult | Select-String -Pattern ("^" + $CABFile.Replace("\", "\\") +": (.+)$") | ForEach-Object { $_.Matches.Groups[1].Value }
    return $sCommandResult
}