function Get-FunctionCode {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$FunctionName
    )
    $func = Get-Item Function:\$FunctionName
    if ($func) {
        $functionBody = $func.ScriptBlock.ToString()
        return @"
function $FunctionName {
    $functionBody
}
"@
    } else {
        throw [System.ArgumentException] "Function $FunctionName not found"
    }
}