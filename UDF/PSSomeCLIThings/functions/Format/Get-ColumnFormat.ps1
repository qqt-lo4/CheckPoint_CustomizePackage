function Get-ColumnFormat {
    <#
    .SYNOPSIS
        Analyzes object properties to determine optimal column formatting for table display.

    .DESCRIPTION
        This function examines a collection of objects and generates formatting metadata for each
        property/column. It automatically determines appropriate alignment based on data types,
        calculates maximum content width, and supports custom formatting options through the
        AddColumnnFormat parameter.

        The function returns an array of hashtables, one per column, containing:
        - Name: Property name
        - Type: Data type of the property
        - Alignment: "left" or "right" based on type
        - ContentMaxWidth: Maximum width needed to display all values
        - Values: All column values (formatted if Format is specified)
        - Format: Optional format string (from AddColumnnFormat)
        - Width: Optional fixed width (from AddColumnnFormat)
        - AutoWidth: Optional auto-width flag (from AddColumnnFormat)

        Alignment rules:
        - Numeric types (Int16, Int32, Int64, etc.): right-aligned
        - Boolean type: right-aligned
        - All other types (String, DateTime, etc.): left-aligned

    .PARAMETER SelectedObjects
        An array of objects to analyze. The function examines the properties of the first object
        and applies the analysis to all objects in the array. All objects should have the same
        property structure for consistent results.

        This parameter is mandatory and can be used at position 0.

    .PARAMETER AddColumnnFormat
        A hashtable containing additional formatting options for specific columns. The keys
        should be property names, and values should be hashtables with formatting options.

        Supported options per column:
        - Format: Format string for the data (e.g., "N2" for numbers, "yyyy-MM-dd" for dates)
        - Width: Fixed width for the column in characters
        - AutoWidth: Boolean flag to allow automatic width calculation

    .OUTPUTS
        System.Collections.Hashtable[]
        Returns an array of ordered hashtables, one per column, containing formatting metadata.

    .EXAMPLE
        $data = @(
            [PSCustomObject]@{ Name = "Server1"; CPU = 45.5; Active = $true }
            [PSCustomObject]@{ Name = "Server2"; CPU = 78.234; Active = $false }
        )
        $format = Get-ColumnFormat -SelectedObjects $data

        Returns formatting metadata for three columns:
        - Name: left-aligned, width based on longest name
        - CPU: right-aligned, width based on longest value
        - Active: right-aligned, width of 5 ("False")

    .EXAMPLE
        $data = 1..100 | ForEach-Object {
            [PSCustomObject]@{ ID = $_; Value = $_ * 1.5 }
        }
        $customFormat = @{
            Value = @{ Format = "N2"; Width = 10 }
        }
        $format = Get-ColumnFormat -SelectedObjects $data -AddColumnnFormat $customFormat

        Returns formatting with custom format for Value column (2 decimal places, fixed width).

    .EXAMPLE
        Get-Process | Select-Object -First 10 Name, CPU, WS |
            Get-ColumnFormat

        Analyzes process objects to determine optimal column formatting for display.

    .NOTES
        Author: Loïc Ade
        Created: 2025-01-16
        Version: 1.0.0
        Module: CLIDialog
        Dependencies: None

        The function examines all values in each column to determine the maximum content width.
        This ensures that the resulting table can accommodate the widest value in each column
        without truncation (unless explicitly overridden with custom Width).

        Type detection uses the PSTypeNames property of objects, taking the first (most specific)
        type name. Null values are excluded from type detection to avoid incorrect type inference.

        The AddColumnnFormat parameter name has a typo (extra 'n') but is kept for backward
        compatibility with existing code that uses this function.

    .LINK
        Format-TableCustom
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [object[]]$SelectedObjects,
        [Parameter(Position = 1)]
        [hashtable]$AddColumnnFormat
    )
    $aProperties = $SelectedObjects[0].PSObject.Properties
    $aFormatProperties = @()
    foreach ($p in $aProperties) {
        $aColumnValues = ($SelectedObjects).$($p.Name)
        $sPropertyName = $p.Name 
        $aTypes = ($aColumnValues | Where-Object { $_ -ne $null } | ForEach-Object { $_.PSTypeNames[0] } |  Group-Object)
        $sType = if ($aTypes) {
            $aTypes[0].Name
        } else {
            "System.String"
        }        
        $sAlign = switch -Regex ($sType) {
            "^System`.Int.*$" { "right" }
            "^System`.Boolean$" { "right" }
            default { "left" }
        }
        $hColumnFormat = [ordered]@{
            Name = $sPropertyName
            Type = $sType
            Alignment = $sAlign
        }
        if ($AddColumnnFormat) {
            if ($AddColumnnFormat[$sPropertyName]) {
                if ($AddColumnnFormat[$sPropertyName].Format) {
                    $hColumnFormat.Format = $AddColumnnFormat[$sPropertyName].Format
                }
                if ($AddColumnnFormat[$sPropertyName].Width) {
                    $hColumnFormat.Width = $AddColumnnFormat[$sPropertyName].Width
                }
                if ($AddColumnnFormat[$sPropertyName].AutoWidth) {
                    $hColumnFormat.AutoWidth = $AddColumnnFormat[$sPropertyName].AutoWidth
                }
            }
        }
        if ($hColumnFormat.Format) {
            $hColumnFormat.Values = $aColumnValues | ForEach-Object { if ($_) { $_.ToString($hColumnFormat.Format) } }
        } else {
            $hColumnFormat.Values = $aColumnValues
        }

        $hColumnFormat.ContentMaxWidth = $hColumnFormat.Values | ForEach-Object -Begin { $iMax = 0 } -Process { if ($_ -and ($_.ToString().Length -gt $iMax)) { $iMax = $_.ToString().Length } } -End { $iMax }
        
        $aFormatProperties += $hColumnFormat
    }
    return $aFormatProperties
}
