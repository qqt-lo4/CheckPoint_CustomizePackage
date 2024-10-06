function Read-NumericValue {
    Param(
        [string]$header,
        [switch]$decimal,
        [double]$min,
        [double]$max,
        [double]$valueIfEmpty,
        [string]$errorMessage = "Invalid value, please enter value with correct format."
    )

    if ($PSBoundParameters.ContainsKey("min") -and $PSBoundParameters.ContainsKey("max") -and ($min -gt $max)) {
        throw [System.ArgumentOutOfRangeException] "Minimum value is higher than max value!"
    }
    $result = ""
    while ($true) {
        $result = Read-Host -Prompt $header
        if (($result -eq "") -and ($PSBoundParameters.ContainsKey("valueIfEmpty"))) {
            return $valueIfEmpty
        }
        $foundValue = $false
        if ($decimal.IsPresent) {
            if ($result -match "^-?[0-9]+(.|,)[0-9]+$") {
                $result = [double]$result
                $foundValue = $true
            }
        } else {
            if ($result -match "^-?[0-9]+$") {
                $result = [double]$result
                $foundValue = $true
            }
        }
        if ($foundValue) {
            $valueGEmin = $false
            $valueLEmax = $false
            if ($PSBoundParameters.ContainsKey("min")) {
                $valueGEmin = ($result -ge $min)
            } else {
                $valueGEmin = $true
            }
            if ($PSBoundParameters.ContainsKey("max")) {
                $valueLEmax = ($result -le $max)
            } else {
                $valueLEmax = $true
            }
            if ($valueGEmin -and $valueLEmax) {
                return $result
            } else {
                $foundValue = $false
            }
            if (-not $valueGEmin) {
                Write-Host "Value $result is lower than minimum ($min)" -ForegroundColor Red
            }
            if (-not $valueLEmax) {
                Write-Host "Value $result is higher than max ($max)" -ForegroundColor Red
            }
        } else {
            Write-Host $errorMessage -ForegroundColor Red
        }
    }
}

