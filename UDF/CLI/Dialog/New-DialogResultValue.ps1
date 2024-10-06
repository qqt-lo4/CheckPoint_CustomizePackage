function New-DialogResultValue {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [object]$Value,
        [AllowNull()]
        [object]$SelectedProperties,
        [object]$DialogResult
    )
    $sResultType = "DialogResult.Value"
    $hResult = @{
        Type = "Value"
        Value = $Value
        SelectedProperties = $SelectedProperties
        DialogResult = $DialogResult
    }
    $hResult | Add-Member -MemberType ScriptMethod -Name "ValueCount" -Value {
        if ($null -eq $this.Value) {
            return 0
        } elseif ($this.Value -is [array]) {
            return $this.Value.Count
        } else {
            return 1
        }
    }
    $hResult.PSTypeNames.Insert(0, $sResultType)
    return $hResult
}
