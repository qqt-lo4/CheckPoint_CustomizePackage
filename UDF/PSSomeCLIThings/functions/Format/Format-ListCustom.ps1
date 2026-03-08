function Format-ListCustom {
    <#
    .SYNOPSIS
        Displays an object's properties in a custom list format with colored property names.

    .DESCRIPTION
        Similar to Format-List but with colored property names, alignment control, and
        optional value coloring via regex patterns. Supports hashtable input by converting
        to PSCustomObject. Iterates over properties, calculates the longest property name
        for alignment, and delegates rendering to Format-PropertyToList.

    .PARAMETER InputObject
        The object to display. Accepts pipeline input. Hashtables are automatically
        converted to PSCustomObject.

    .PARAMETER Sort
        Sort properties alphabetically.

    .PARAMETER Descending
        Sort properties in descending order. Used with -Sort.

    .PARAMETER PropertiesColor
        Color for property names. Default: Green.

    .PARAMETER PropertyAlign
        Alignment of property names. Valid values: "Left", "Right". Default: "Left".

    .PARAMETER PropertiesValuesToColor
        Array of objects with Property, Color, Pattern, ColorGroups, and AllMatches
        properties for applying regex-based color highlighting to specific values.

    .OUTPUTS
        Formatted list output to the console with colored property names.

    .EXAMPLE
        Get-Process | Select-Object -First 1 | Format-ListCustom -PropertiesColor Cyan

        Displays the first process properties in a list with cyan property names.

    .EXAMPLE
        @{Name="Server01"; Status="Running"} | Format-ListCustom -Sort -PropertyAlign Right

        Displays a hashtable as a right-aligned sorted property list.

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    param (
        [Parameter(ValueFromPipeline = $true)]
        [Object]$InputObject,
        [Switch]$Sort,
        [Switch]$Descending,
        [System.ConsoleColor]$PropertiesColor = ([System.ConsoleColor]::Green),
        [ValidateSet("Left", "Right")]
        [string]$PropertyAlign = "Left",
        [object[]]$PropertiesValuesToColor
    )
    process {
        $oInputObject = if ($InputObject -is [hashtable]) {
            New-Object -TypeName psobject -Property $InputObject
        } else {
            $InputObject
        }
        $properties = $oInputObject.PSObject.Properties

        if ($Sort) {
            $properties = $properties | Sort-Object -Property Name -Descending:$Descending
        }

        $longestName = 0
        $longestValue = 0

        $properties | ForEach-Object {
            if ($_.Name.Length -gt $longestName) {
                $longestName = $_.Name.Length
            }

            if (($null -ne $oInputObject."$($_.Name)") -and ($oInputObject."$($_.Name)".ToString().Length -gt $longestValue)) {
                $longestValue = $oInputObject."$($_.Name)".ToString().Length * -1
            }
        }

        $properties | ForEach-Object { 
            $oValue = if ($null -eq $oInputObject."$($_.Name)") { "" } else { $oInputObject."$($_.Name)" }
            if ($PropertiesValuesToColor | Where-Object Property -eq $_.Name) {
                $oColorInfo = $PropertiesValuesToColor | Where-Object Property -eq $_.Name
                Format-PropertyToList -Property $_.Name -Value $oValue -PropertyColor $PropertiesColor -PropertyAlign $PropertyAlign `
                                      -LongestPropertyName $longestName -ValueColor $oColorInfo.Color -Pattern $oColorInfo.Pattern `
                                      -ColorGroups $oColorInfo.ColorGroups -AllMatches:$oColorInfo.AllMatches
            } else {
                Format-PropertyToList -Property $_.Name -Value $oValue -PropertyColor $PropertiesColor `
                                      -PropertyAlign $PropertyAlign -LongestPropertyName $longestName
            }
       }
    }
}
