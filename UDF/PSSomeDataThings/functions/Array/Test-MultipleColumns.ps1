function Test-MultipleColumns {
    <#
    .SYNOPSIS
        Validates that an object array has the expected columns

    .DESCRIPTION
        Checks the first object in an array for required columns, forbidden columns,
        and optional columns. Returns a validation result with details.

    .PARAMETER InputObject
        The array of objects to validate

    .PARAMETER Columns
        Required column names that must be present

    .PARAMETER ForbiddenColumns
        Column names that must not be present

    .PARAMETER OptionalColumns
        Column names to check for presence (informational, does not affect validity)

    .OUTPUTS
        PSCustomObject with IsCorrectArray, BadColumns, MissingColumns, and OptionalColumnsPresent.

    .EXAMPLE
        $result = Test-MultipleColumns -InputObject $data -Columns "Name","Id" -ForbiddenColumns "Password"
        if ($result.IsCorrectArray) { "Valid" }

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory)]
        [object]$InputObject,
        [Parameter(Mandatory)]
        [string[]]$Columns,
        [string[]]$ForbiddenColumns,
        [string[]]$OptionalColumns
    )
    $isCorrectArray = $true
    $badColumns = @()
    $missingColumns = @()
    $optionalColumnsPresent = @()
    foreach ($column in $Columns) {
        if ($column -notin $InputObject[0].PSObject.Properties.name) {
            if ($missingColumns.Count -eq 1) { $missingColumns = @($missingColumns, $column) } else { $missingColumns += $column }
            $isCorrectArray = $false
        }
    }
    foreach ($column in $InputObject[0].PSObject.Properties.name) {
        if ($ForbiddenColumns -and ($column -in $ForbiddenColumns)) {
            if ($badColumns.Count -eq 1) { $badColumns = @($badColumns, $column) } else { $badColumns += $column }
            $isCorrectArray = $false
        }
        if ($OptionalColumns -and ($column -in $OptionalColumns)) {
            if ($optionalColumnsPresent.Count -eq 1) { $optionalColumnsPresent = @($optionalColumnsPresent, $column) } else { $optionalColumnsPresent += $column }
        }
    }
    $result = @{ 
        IsCorrectArray = $isCorrectArray 
        BadColumns = $badColumns
        MissingColumns = $missingColumns
        OptionalColumnsPresent = $optionalColumnsPresent
    }
    return New-Object -TypeName psobject -Property $result
}