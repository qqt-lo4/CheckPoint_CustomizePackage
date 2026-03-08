function New-CLIDialogSpace {
    <#
    .SYNOPSIS
        Creates a horizontal space element for CLI dialog interfaces.

    .DESCRIPTION
        This function creates a space object that renders as a horizontal blank area in CLI dialogs.
        It's useful for creating spacing, alignment, and visual separation between dialog elements.
        The space can have a custom length and background color, making it versatile for various
        layout needs in console-based user interfaces.

    .PARAMETER Length
        The number of space characters to display. Must be a positive integer (minimum 1).
        Default is 1. This parameter can be used at position 0.

    .PARAMETER Color
        The background color for the space. Default is the current console background color.
        Useful for creating colored separators or matching the dialog's color scheme.

    .OUTPUTS
        Returns a hashtable object with the following members:
        - Properties: Type, Length, Color
        - Methods: Draw(), GetTextHeight(), GetTextWidth(), IsDynamicObject()

    .EXAMPLE
        $space = New-CLIDialogSpace -Length 5
        $space.Draw()

        Creates a 5-character space and displays it.

    .EXAMPLE
        $separator = New-CLIDialogSpace -Length 50 -Color DarkGray

        Creates a 50-character space with dark gray background, useful as a visual separator.

    .EXAMPLE
        $row = @(
            New-CLIDialogButton -Text "OK"
            New-CLIDialogSpace -Length 3
            New-CLIDialogButton -Text "Cancel"
        )

        Creates a row with two buttons separated by 3 spaces.

    .EXAMPLE
        $indent = New-CLIDialogSpace -Length 10
        $width = $indent.GetTextWidth()  # Returns 10

        Creates a space and gets its width for layout calculations.

    .NOTES
        Module: CLIDialog
        Author: Loïc Ade
        Created: 2025-10-20
        Version: 1.0.0
        Dependencies: None

        This function is part of the CLI Dialog framework and is typically used with
        New-CLIDialogObjectsRow to create horizontal layouts with proper spacing.

        METHODS:
        - Draw(): Renders the space to the console (no newline)
        - GetTextHeight(): Always returns 1 (spaces are single-line)
        - GetTextWidth(): Returns the length of the space
        - IsDynamicObject(): Returns $false (space is static)

        CHANGELOG:

        Version 1.0.0 - 2025-10-20 - Loïc Ade
            - Initial release
            - Configurable length with validation
            - Custom background color support
            - Standard dialog object methods (Draw, GetTextHeight, GetTextWidth)
    #>
    Param(
        [Parameter(Position = 0)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Length = 1,
        [System.ConsoleColor]$Color = (Get-Host).UI.RawUI.BackgroundColor
    )
    $hResult = @{
        Type = "space"
        Length = $Length
        Color = $Color
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "Draw" -Value {
        Write-Host (" " * $this.Length) -NoNewline -BackgroundColor $this.Color
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetTextHeight" -Value {
        return 1
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetTextWidth" -Value {
        return $this.Length
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "IsDynamicObject" -Value {
        return $false
    }

    return $hResult
}
