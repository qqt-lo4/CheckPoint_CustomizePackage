function New-MenuRow {
    <#
    .SYNOPSIS
        Creates a menu row with a header label and content items for displaying grouped menu elements.

    .DESCRIPTION
        Constructs a menu row object that displays a header label followed by content items (buttons,
        textboxes, or other menu elements). Rows are used to organize menu items into labeled sections
        with customizable alignment, separators, and colors.

        The row header can be aligned left or right, with a customizable separator between the header
        and content. Supports different color schemes for focused and unfocused states.

    .PARAMETER Text
        Row header text (label). Mandatory. Position 0.

    .PARAMETER Content
        Array of menu items to display in the row. Mandatory. Position 1.

    .PARAMETER HeaderAlign
        Header text alignment. Valid values: Left, Right. Default: Left.

    .PARAMETER Separator
        Text separator between header and content. Default: " : "

    .PARAMETER SeparatorLocation
        Fixed column position for the separator. If not specified, separator appears
        immediately after the header text.

    .PARAMETER HeaderForegroundColor
        Header text color when not focused. Default: Green.

    .PARAMETER HeaderBackgroundColor
        Header background color when not focused. Default: console background color.

    .PARAMETER FocusedHeaderForegroundColor
        Header text color when row is focused. Default: Blue.

    .PARAMETER FocusedHeaderBackgroundColor
        Header background color when row is focused. Default: console background color.

    .EXAMPLE
        $row = New-MenuRow -Text "Options" -Content @(
            New-MenuItem -Text "Edit" -Content { Edit-Config }
            New-MenuItem -Text "Delete" -Content { Remove-Config }
        )

    .EXAMPLE
        New-MenuRow -Text "Server" -Content $menuItems -HeaderAlign Right -Separator " > "

    .NOTES
        Author: Loïc Ade
        Created: 2025-11-22
        Version: 1.0.0
        Module: CLIDialog
        Dependencies: New-CLIDialogObjectsRow
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Text,
        [Parameter(Mandatory, Position = 1)]
        [object]$Content,
        [ValidateSet("Left", "Right")]
        [string]$HeaderAlign = "Left",
        [string]$Separator = " : ",
        [int]$SeparatorLocation,
        [System.ConsoleColor]$HeaderForegroundColor = [System.ConsoleColor]::Green,
        [System.ConsoleColor]$HeaderBackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [System.ConsoleColor]$FocusedHeaderForegroundColor = [System.ConsoleColor]::Blue,
        [System.ConsoleColor]$FocusedHeaderBackgroundColor = (Get-Host).UI.RawUI.BackgroundColor
    )
    $hResult = @{
        Text = $Text
        Type = "menurow"
        Content = $Content
        HeaderAlign = $HeaderAlign
        Separator = $Separator
        SeparatorLocation = $SeparatorLocation
        BackgroundColor = $BackgroundColor
        ForegroundColor = $ForegroundColor
        HeaderForegroundColor = $HeaderForegroundColor
        HeaderBackgroundColor = $HeaderBackgroundColor
        FocusedHeaderForegroundColor = $FocusedHeaderForegroundColor
        FocusedHeaderBackgroundColor = $FocusedHeaderBackgroundColor
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "ConvertToDialog" -Value {
        $aResult = @()
        foreach ($item in $this.Content) {
            $aResult += $item.ConvertToDialog()
        }
        return New-CLIDialogObjectsRow -Row $aResult -Header $this.Text -HeaderAlign $this.HeaderAlign -HeaderSeparator $this.Separator `
                -HeaderForegroundColor $this.HeaderForegroundColor -HeaderBackgroundColor $this.HeaderBackgroundColor `
                -FocusedHeaderForegroundColor $this.FocusedHeaderForegroundColor -FocusedHeaderBackgroundColor $this.FocusedHeaderBackgroundColor `
                -SeparatorLocation $this.SeparatorLocation
    }

    return $hResult
}
