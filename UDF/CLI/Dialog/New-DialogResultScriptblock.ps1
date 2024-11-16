function New-DialogResultScriptblock {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [object]$Value,
        [object]$DialogResult
    )
    $sResultType = "DialogResult.Scriptblock"
    $hResult = @{
        Type = "Scriptblock"
        Value = $Value
        DialogResult = $DialogResult
    }
    $hResult.PSTypeNames.Insert(0, $sResultType)
    return $hResult
}
