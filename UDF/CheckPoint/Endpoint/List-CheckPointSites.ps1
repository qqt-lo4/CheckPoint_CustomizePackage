function List-CheckPointSites {
    Param(
        [string]$tracexe = $(Get-CheckPointTracExe)
    )
    $result = Get-CheckPointTracInfo -tracexe $tracexe | ForEach-Object { if ($_ -match "^Conn ([^:]+):") { return $Matches.1 } }
    $result
}