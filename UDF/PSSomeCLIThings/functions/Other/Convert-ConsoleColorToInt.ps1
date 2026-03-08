function Convert-ConsoleColorToInt {
    <#
    .SYNOPSIS
        Converts PowerShell ConsoleColor enum values to ANSI escape sequence color codes.

    .DESCRIPTION
        This function translates System.ConsoleColor enumeration values into their corresponding
        ANSI escape sequence numeric codes for use in terminal color formatting. It supports both
        foreground and background color codes, which are used in ANSI escape sequences like:
        ESC[{code}m (where ESC is character 27).

        ANSI color codes are used for terminal text formatting and are widely supported across
        modern terminals and PowerShell versions. The function handles all 16 standard console
        colors defined in the System.ConsoleColor enumeration.

        Foreground codes (default):
        - Dark colors: 30-37 (DarkGray=30, DarkRed=31, DarkGreen=32, etc.)
        - Bright colors: 90-97 (Black=90, Red=91, Green=92, etc.)

        Background codes:
        - Dark colors: 40-47 (DarkGray=40, DarkRed=41, DarkGreen=42, etc.)
        - Bright colors: 100-107 (Black=100, Red=101, Green=102, etc.)

    .PARAMETER Color
        The System.ConsoleColor enumeration value to convert. This parameter is mandatory and
        can be used at position 0.

        Valid values: Black, DarkBlue, DarkGreen, DarkCyan, DarkRed, DarkMagenta, DarkYellow,
        Gray, DarkGray, Blue, Green, Cyan, Red, Magenta, Yellow, White

    .PARAMETER FG
        Specifies that the color should be converted to a foreground color code. This is the
        default behavior if neither -FG nor -BG is specified.

        Aliases: ForegroundColor, Foreground

    .PARAMETER BG
        Specifies that the color should be converted to a background color code instead of
        foreground.

        Aliases: BackgroundColor, Background

    .OUTPUTS
        System.Int32
        Returns the ANSI color code as an integer (30-37, 40-47, 90-97, or 100-107).

    .EXAMPLE
        Convert-ConsoleColorToInt -Color Red

        Returns: 91
        Converts Red to foreground ANSI code (91) for use in escape sequences.

    .EXAMPLE
        Convert-ConsoleColorToInt -Color Green -BG

        Returns: 102
        Converts Green to background ANSI code (102).

    .EXAMPLE
        $code = Convert-ConsoleColorToInt DarkBlue -Foreground
        Write-Host "$([char]27)[$($code)mThis text is dark blue$([char]27)[0m"

        Demonstrates using the function to create colored text with ANSI escape sequences.

    .EXAMPLE
        $fgCode = Convert-ConsoleColorToInt Yellow
        $bgCode = Convert-ConsoleColorToInt DarkBlue -BG
        $text = "$([char]27)[$fgCode;$($bgCode)mYellow on Blue$([char]27)[0m"
        Write-Host $text

        Combines foreground and background colors in a single ANSI sequence.

    .EXAMPLE
        [System.ConsoleColor]::Green | Convert-ConsoleColorToInt -BG

        Returns: 102
        Demonstrates pipeline input with background color conversion.

    .NOTES
        Author: Loïc Ade
        Created: 2025-01-16
        Version: 1.0.0
        Module: CLIDialog
        Dependencies: None

        ANSI escape sequences follow the format: ESC[{code}m where ESC is character 27 (0x1B).
        Multiple codes can be combined with semicolons: ESC[91;104m (red foreground, blue background).
        The sequence ESC[0m resets all formatting to default.

        This function is commonly used by formatting functions like Format-TableCustom to generate
        colored output in the terminal.

        Standard ANSI color code ranges:
        - Foreground dark: 30-37
        - Background dark: 40-47
        - Foreground bright: 90-97
        - Background bright: 100-107

    .LINK
        Format-TableCustom
        Write-Host
    #>
    [CmdletBinding(DefaultParameterSetName = "FG")]
    Param(
        [Parameter(Mandatory, Position = 0)]
        [System.ConsoleColor]$Color,
        [Parameter(ParameterSetName = "FG")]
        [Alias("ForegroundColor", "Foreground")]
        [switch]$FG,
        [Parameter(ParameterSetName = "BG")]
        [Alias("BackgroundColor", "Background")]
        [switch]$BG
    )
    if ($PSCmdlet.ParameterSetName -eq "FG") {
        switch ($Color) {
            "Black"       { return 90 }
            "Blue"        { return 94 }
            "Cyan"        { return 96 }
            "DarkBlue"    { return 34 }
            "DarkCyan"    { return 36 }
            "DarkGray"    { return 30 }
            "DarkGreen"   { return 32 }
            "DarkMagenta" { return 35 }
            "DarkRed"     { return 31 }
            "DarkYellow"  { return 33 }
            "Gray"        { return 37 }
            "Green"       { return 92 }
            "Magenta"     { return 95 }
            "Red"         { return 91 }
            "White"       { return 97 }
            "Yellow"      { return 93 }
        }    
    } else {
        switch ($Color) {
            "Black"       { return 100 }
            "Blue"        { return 104 }
            "Cyan"        { return 106 }
            "DarkBlue"    { return  44 }
            "DarkCyan"    { return  46 }
            "DarkGray"    { return  40 }
            "DarkGreen"   { return  42 }
            "DarkMagenta" { return  45 }
            "DarkRed"     { return  41 }
            "DarkYellow"  { return  43 }
            "Gray"        { return  47 }
            "Green"       { return 102 }
            "Magenta"     { return 105 }
            "Red"         { return 101 }
            "White"       { return 107 }
            "Yellow"      { return 103 }
        } 
    }
}