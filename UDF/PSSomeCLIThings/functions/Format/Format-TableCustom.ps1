function Format-TableCustom {
    <#
    .SYNOPSIS
        Formats objects as a customized table with advanced column formatting and color support.

    .DESCRIPTION
        This function provides enhanced table formatting capabilities beyond PowerShell's built-in
        Format-Table cmdlet. It offers precise control over column widths, alignment, header colors,
        automatic width calculation, and content truncation. The function supports both pipeline
        input and custom property selection with hashtable definitions.

        Key features:
        - Custom column width calculation with automatic width for one column
        - Header color customization with optional underline
        - Content truncation with ellipsis (...) for columns exceeding width
        - Support for custom property definitions using hashtables
        - ANSI color escape sequences for terminal compatibility
        - Output as string array or direct to host

    .PARAMETER InputObject
        The objects to format as a table. This parameter is mandatory and accepts pipeline input.
        Can be any array of objects with properties to display.

    .PARAMETER Property
        Specifies which properties to display and how to format them. Can be:
        - String array: Simple property names (e.g., "Name", "Value")
        - Hashtable array: Custom property definitions with formatting options

        Hashtable keys supported:
        - n/name/l/label: Column header name
        - e/expression: Property name or script block to calculate value
        - Additional formatting properties (width, alignment, etc.)

    .PARAMETER HideHeader
        When specified, suppresses the header row from the output. Useful for data-only display
        or when combining multiple table outputs.

    .PARAMETER HeaderColor
        The console color to use for the header row. Default is the current foreground color.
        Valid values: Black, DarkBlue, DarkGreen, DarkCyan, DarkRed, DarkMagenta, DarkYellow,
        Gray, DarkGray, Blue, Green, Cyan, Red, Magenta, Yellow, White

    .PARAMETER HeaderUnderline
        When specified, adds an underline row below the header using dashes. The underline
        matches the header color and respects column widths.

    .PARAMETER ToString
        When specified, returns the formatted table as a string array instead of writing
        directly to the host. Useful for further processing or storing the output.

    .PARAMETER ContentMaxWidth
        The maximum width of the entire table in characters. Default is the current console
        window width. Used to calculate column widths and prevent line wrapping.

    .OUTPUTS
        String[] (when -ToString is specified)
        Otherwise writes directly to host with no output object

    .EXAMPLE
        Get-Process | Select-Object -First 5 | Format-TableCustom -Property Name, CPU, WS

        Displays the first 5 processes with Name, CPU, and Working Set columns using default formatting.

    .EXAMPLE
        $data = @(
            [PSCustomObject]@{ Name = "Server1"; Status = "Running"; Memory = "4GB" }
            [PSCustomObject]@{ Name = "Server2"; Status = "Stopped"; Memory = "8GB" }
        )
        $data | Format-TableCustom -HeaderColor Green -HeaderUnderline

        Displays custom objects with a green header and underline.

    .EXAMPLE
        Get-ChildItem | Format-TableCustom -Property @(
            @{n="Name"; e={$_.Name}}
            @{n="Size"; e={$_.Length}}
        ) -ToString

        Formats directory contents with custom properties and returns as string array.

    .EXAMPLE
        Get-Service | Where-Object Status -eq "Running" |
            Format-TableCustom -Property Name, DisplayName, Status -HideHeader

        Displays running services without the header row.

    .NOTES
        Author: Loïc Ade
        Created: 2025-01-16
        Version: 1.0.0
        Module: CLIDialog
        Dependencies: Get-ColumnFormat, Copy-Hashtable, Convert-ConsoleColorToInt

        The function uses ANSI escape sequences for color formatting, which are supported
        in PowerShell 5.1+ and PowerShell Core. The automatic width column feature allows
        one column to expand/contract based on available console width.

        Content that exceeds column width is truncated with an ellipsis (…) character.
        Column alignment (left/right) is determined by the Get-ColumnFormat function
        based on data type.

    .LINK
        Format-Table
        Get-ColumnFormat
    #>
    Param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [object[]]$InputObject,
        [Parameter(Position = 1)]
        [object[]]$Property,
        [switch]$HideHeader,
        [System.ConsoleColor]$HeaderColor = (Get-Host).UI.RawUI.ForegroundColor,
        [switch]$HeaderUnderline,
        [switch]$ToString,
        [int]$ContentMaxWidth = (Get-Host).UI.RawUI.WindowSize.Width
    )
    Begin {
        function Get-HashtableName {
            Param(
                [Parameter(Mandatory, Position = 0)]
                [hashtable]$InputObject
            )
            $aName = $InputObject.Keys | Where-Object { $_ -in @("l", "label", "n", "name") }
            if ($aName) {
                return $InputObject.$aName
            } else {
                throw "Hashtable does not have a name"
            }
        }
        $aSelectProperties = @("l", "label", "n", "name", "e", "expression")
        $aInputObject = @()
    }
    Process {
        $aInputObject += $InputObject
    }
    End {
        $aSelectedObjects = if ($Property) {
            $aSelectObjectProperties = $Property | ForEach-Object -Process { if ($_ -is [string]) { $_ } else { Copy-Hashtable -InputObject $_ -Properties $aSelectProperties } }
            $aInputObject | ForEach-Object { [pscustomobject]$_ | Select-Object -Property $aSelectObjectProperties }
        } else {
            $aInputObject
        }
        $aColumnFormatAdditionalProperties = if ($Property) {
            $Property | ForEach-Object -Begin { $hResult = @{} } -Process { if ($_ -isnot [string]) {$h = Copy-Hashtable -InputObject $_ -Properties $aSelectProperties -Not ; if ($h) { $hResult.$(Get-HashtableName $_) = $h }}} -End { $hResult }
        } else {
            $null
        }
        $aColumnFormat = Get-ColumnFormat -SelectedObjects $aSelectedObjects -AddColumnnFormat $aColumnFormatAdditionalProperties
        $iMaxTableWidth = 0
        $iColumnAutoWidth = 0
        $oAutoWidthColumn = $null
        $hColumns = @{}
        foreach ($column in $aColumnFormat) {
            $hColumns[$column.Name] = $column
            if ($column.AutoWidth) {
                $iColumnAutoWidth = $column.ContentMaxWidth
                $oAutoWidthColumn = $column
            } else {
                $column.Width = if ($column.Name.Length -gt $column.ContentMaxWidth) { $column.Name.Length } else { $column.ContentMaxWidth }
                $iMaxTableWidth += $column.Width
            }
        }
        $iMaxTableWidth += ($aColumnFormat.Count - 1)
        if (($iMaxTableWidth + $iColumnAutoWidth) -le $ContentMaxWidth) {
            $iMaxTableWidth += $iColumnAutoWidth
            if ($oAutoWidthColumn) {
                $oAutoWidthColumn.Width = $iColumnAutoWidth
            }
        } else {
            $oAutoWidthColumn.Width = $ContentMaxWidth - $iMaxTableWidth
        }
    
        $aResultLine = @()
        
        if (-not $HideHeader) {
            $sHeaderLine = "$([char]27)[" + (Convert-ConsoleColorToInt $HeaderColor) + "m"
            if ($aColumnFormat -is [array]) {
                for($i = 0; $i -lt $aColumnFormat.Name.Count; $i++) {
                    $sPropertyName = $aColumnFormat.Name[$i]
                    $column = $hColumns[$sPropertyName]
                    $iAlign = if ($column.Alignment -eq "left") { -1 } else { 1 }
                    $sHeaderLine += ("{0,$($column.width * $iAlign)}" -f $column.Name) 
                    if ($i -lt ($aColumnFormat.Name.Count - 1)) {
                        $sHeaderLine += " "
                    }
                }    
            } else {
                $column = $aColumnFormat
                $iAlign = if ($column.Alignment -eq "left") { -1 } else { 1 }
                $sHeaderLine += ("{0,$($column.width * $iAlign)}" -f $column.Name) + " "
            }
            $sHeaderLine += "$([char]27)[0m"
            $aResultLine += $sHeaderLine
            if ($HeaderUnderline) {
                $sUnderLine = "$([char]27)[" + (Convert-ConsoleColorToInt $HeaderColor) + "m"
                for($i = 0; $i -lt $aColumnFormat.Name.Count; $i++) {
                    $sPropertyName = $aColumnFormat.Name[$i]
                    $column = $hColumns[$sPropertyName]
                    $sUnderLine += ("-" * $sPropertyName.Length) + (" " * ($column.Width - $sPropertyName.Length))
                    if ($i -lt ($aColumnFormat.Name.Count - 1)) {
                        $sUnderLine += " "
                    }
                }
                $aResultLine += $sUnderLine
            }
        }
    
        foreach ($Object in $aSelectedObjects) {
            $sLine = ""
            if ($Object.PSObject.Properties.Name -is [array]) {
                for($i = 0; $i -lt $Object.PSObject.Properties.Name.Count; $i++) {
                    $sPropertyName = $Object.PSObject.Properties.Name[$i]
                    $column = $hColumns[$sPropertyName]
                    $iAlign = if ($column.Alignment -eq "left") { -1 } else { 1 }
                    $sValue = $Object.$sPropertyName
                    if ($sValue.Length -gt $column.width) {
                        $sValue = $sValue.SubString(0, $column.width - 1) + "…"
                    } 
                    $sLine += ("{0,$($column.width * $iAlign)}" -f $sValue) 
                    if ($i -lt ($Object.PSObject.Properties.Name.Count - 1)) {
                        $sLine += " "
                    }
                }    
            } else {
                $sPropertyName = $Object.PSObject.Properties.Name
                $column = $hColumns[$sPropertyName]
                $iAlign = if ($column.Alignment -eq "left") { -1 } else { 1 }     
                $sValue = $Object.$sPropertyName
                if ($sValue.Length -gt $column.width) {
                    $sValue = $sValue.SubString(0, $column.width - 1) + "…"
                }
                $sLine += ("{0,$($column.width * $iAlign)}" -f $sValue) 
            }
            $aResultLine += $sLine
        }
        if ($ToString) {
            return $aResultLine
        } else {
            $aResultLine | Write-Host
        }    
    }
}
