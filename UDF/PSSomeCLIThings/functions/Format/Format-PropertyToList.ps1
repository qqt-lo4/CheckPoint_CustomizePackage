function Format-PropertyToList {
    <#
    .SYNOPSIS
        Renders a single property-value pair in list format with colored output.

    .DESCRIPTION
        Displays a property name and its value(s) in a formatted list layout
        (e.g., "PropertyName : Value"). The property name is displayed with a
        configurable color and alignment. Values can be regex-highlighted using
        Write-ColoredString. Supports multi-value arrays where each additional
        value is indented to align with the first.

    .PARAMETER Property
        The property name to display.

    .PARAMETER Value
        The value(s) to display. Supports arrays for multi-line output.

    .PARAMETER PropertyColor
        Color for the property name. Default: Green.

    .PARAMETER PropertyAlign
        Alignment of the property name. Valid values: "Left", "Right". Default: "Left".

    .PARAMETER ValueColor
        Color for matching value text when using regex pattern highlighting.

    .PARAMETER Pattern
        Regex pattern for value color highlighting.

    .PARAMETER ColorGroups
        Regex group names to colorize. Default: @("0").

    .PARAMETER AllMatches
        Color all regex matches, not just the first.

    .PARAMETER LongestPropertyName
        Length of the longest property name, used for padding and alignment.

    .OUTPUTS
        Formatted property-value pair output to the console.

    .EXAMPLE
        Format-PropertyToList -Property "Status" -Value "Running" -LongestPropertyName 10

        Displays "Status     : Running" with the property name in green.

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory)]
        [string]$Property,
        [Parameter(Mandatory)]
        [Object[]]$Value,
        [System.ConsoleColor]$PropertyColor = ([System.ConsoleColor]::Green),
        [ValidateSet("Left", "Right")]
        [string]$PropertyAlign = "Left",
        [System.ConsoleColor]$ValueColor,
        [string]$Pattern,
        [string[]]$ColorGroups = @("0"),
        [switch]$AllMatches,
        [int]$LongestPropertyName
    )
    $iAlign = if ($PropertyAlign -eq "Left") { -1 } else { 1 }
    Write-Host ("{0,$($LongestPropertyName * $iAlign)} : " -f $Property) -NoNewline -ForegroundColor $PropertyColor
    $hColorString = @{}
    if ($Pattern) { $hColorString.Pattern = $Pattern }
    if ($ColorGroups) { $hColorString.ColorGroups = $ColorGroups }
    if ($null -ne $ValueColor) { 
        $hColorString.Color = $ValueColor.ToString()
    }
    if ($AllMatches) { $hColorString.AllMatches = $AllMatches }
    Write-ColoredString -InputObject $Value[0] @hColorString
    if ($Value.Count -gt 1) {
        for ($i = 1; $i -lt $Value.Count; $i++) {
            Write-Host (" " * ($LongestPropertyName + 3)) -NoNewline
            Write-ColoredString -InputObject $Value[$i] @hColorString
        }
    }
}
