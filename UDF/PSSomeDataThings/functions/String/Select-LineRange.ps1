function Select-LineRange {
    <#
    .SYNOPSIS
        Selects a range of lines from a string array using regex delimiters

    .DESCRIPTION
        Extracts a subset of lines from a string array using regex patterns to identify
        the start and end boundaries. At least one of StartRegex or EndRegex must be provided.
        If StartRegex is empty, extraction starts from the first line.
        If EndRegex is empty, extraction continues to the last line.

    .PARAMETER InputArray
        The string array to search through.

    .PARAMETER StartRegex
        Regex pattern to identify the first line to extract. Optional.

    .PARAMETER EndRegex
        Regex pattern to identify the last line to extract. Optional.

    .PARAMETER FromEnd
        If specified, searches the array from end to start to optimize lookups near the end.

    .PARAMETER IncludeStartLine
        Whether to include the line matching StartRegex in the result. Defaults to $true.

    .PARAMETER IncludeEndLine
        Whether to include the line matching EndRegex in the result. Defaults to $true.

    .OUTPUTS
        System.String[]. The selected range of lines.

    .EXAMPLE
        $output = @("Start", "Data1", "Data2", "End")
        Select-LineRange -InputArray $output -StartRegex "Start" -EndRegex "End"

    .EXAMPLE
        # Without start regex (begins at first line)
        Select-LineRange -InputArray $output -EndRegex "ERROR"

    .EXAMPLE
        # Optimized search from end of array
        Select-LineRange -InputArray $output -StartRegex "Final" -EndRegex "Complete" -FromEnd

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]$InputArray,
        
        [Parameter(Mandatory = $false)]
        [switch]$FromEnd,
        
        [Parameter(Mandatory = $false)]
        [string]$StartRegex = "",
        
        [Parameter(Mandatory = $false)]
        [string]$EndRegex = "",
        
        [Parameter(Mandatory = $false)]
        [bool]$IncludeStartLine = $true,
        
        [Parameter(Mandatory = $false)]
        [bool]$IncludeEndLine = $true
    )
    
    # Validation des paramètres
    if ([string]::IsNullOrWhiteSpace($StartRegex) -and [string]::IsNullOrWhiteSpace($EndRegex)) {
        throw "Au moins une des deux regex (StartRegex ou EndRegex) doit être renseignée"
    }
    
    if ($InputArray.Count -eq 0) {
        Write-Warning "Le tableau d'entrée est vide"
        return @()
    }
    
    # Déterminer l'index de début
    $startIndex = 0
    
    if (-not [string]::IsNullOrWhiteSpace($StartRegex)) {
        if ($FromEnd) {
            # Parcours depuis la fin pour StartRegex
            for ($i = $InputArray.Count - 1; $i -ge 0; $i--) {
                if ($InputArray[$i] -match $StartRegex) {
                    $startIndex = $i
                    if (-not $IncludeStartLine) {
                        $startIndex++
                    }
                    break
                }
            }
            
            # Si aucune ligne ne correspond à StartRegex
            if ($i -lt 0) {
                Write-Warning "Aucune ligne ne correspond à la regex de début: '$StartRegex'"
                return @()
            }
        } else {
            # Parcours normal depuis le début pour StartRegex
            for ($i = 0; $i -lt $InputArray.Count; $i++) {
                if ($InputArray[$i] -match $StartRegex) {
                    $startIndex = $i
                    if (-not $IncludeStartLine) {
                        $startIndex++
                    }
                    break
                }
            }
            
            # Si aucune ligne ne correspond à StartRegex
            if ($i -eq $InputArray.Count) {
                Write-Warning "Aucune ligne ne correspond à la regex de début: '$StartRegex'"
                return @()
            }
        }
    }
    
    # Chercher l'index de fin
    $endIndex = $InputArray.Count - 1  # Par défaut, jusqu'à la fin
    
    if (-not [string]::IsNullOrWhiteSpace($EndRegex)) {
        $foundEnd = $false
        if ($FromEnd) {
            # Parcours depuis la fin pour EndRegex
            for ($i = $InputArray.Count - 1; $i -ge $startIndex; $i--) {
                if ($InputArray[$i] -match $EndRegex) {
                    $endIndex = $i
                    if (-not $IncludeEndLine) {
                        $endIndex--
                    }
                    $foundEnd = $true
                    break
                }
            }
        } else {
            # Parcours normal depuis startIndex pour EndRegex
            for ($i = $startIndex; $i -lt $InputArray.Count; $i++) {
                if ($InputArray[$i] -match $EndRegex) {
                    $endIndex = $i
                    if (-not $IncludeEndLine) {
                        $endIndex--
                    }
                    $foundEnd = $true
                    break
                }
            }
        }
        
        # Si aucune ligne ne correspond à EndRegex
        if (-not $foundEnd) {
            Write-Warning "Aucune ligne ne correspond à la regex de fin: '$EndRegex'"
            return @()
        }
    }
    
    # Validation des index
    if ($startIndex -gt $endIndex) {
        Write-Warning "L'index de début ($startIndex) est supérieur à l'index de fin ($endIndex)"
        return @()
    }
    
    # Extraire les lignes
    $result = @()
    for ($i = $startIndex; $i -le $endIndex; $i++) {
        $result += $InputArray[$i]
    }
    
    return $result
}
