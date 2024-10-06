function New-DialogResultAction {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Action,
        [AllowNull()]
        [object]$Value,
        [object]$DialogResult
    )
    $sResultType = "DialogResult.Action.$Action"
    $hResult = @{
        Type = "Action"
        Action = $Action
        DialogResult = $DialogResult
    }
    if ($Value) {
        $hResult.Value = $Value
    }
    if ($Action -eq "Back") {
        $hResult.Depth = 0
    }
    $hResult.PSTypeNames.Insert(0, $sResultType)
    return $hResult
}
