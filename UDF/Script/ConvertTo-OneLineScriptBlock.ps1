function ConvertTo-OneLineScriptBlock {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [scriptblock]$ScriptBlock
    )
    $aString = $ScriptBlock.ToString().Split("`n")
    $aResult = @()
    foreach ($item in $aString) {
        if ($item.Trim() -ne "") {
            $aResult += $item.Trim()
        }
    }
    return $aResult -join " ; "
}