function Test-ValidNumberInput {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [AllowEmptyString()]
        [string]$inputString,
        [Parameter(Mandatory, Position = 1)]
        [int]$minimumValue,
        [Parameter(Mandatory, Position = 2)]
        [int]$maximumValue,
        [switch]$allowEmptyValue
    )
    if ($allowEmptyValue.IsPresent) {
        if ($inputString -match "^$") {
            return $true, $minimumValue
        }
    } else {
        if ($inputString -match "^$") {
            throw [System.ArgumentException] "Illegal input string"
        }
    }
    $result = if ($inputString -match "^[0-9]+$") {
        $boolResult = ([int]$inputString -ge $minimumValue) -and ([int]$inputString -le $maximumValue)
        $boolResult, [int]$selectedItem
    } else {
        $false, -1
    } 
    return $result
}