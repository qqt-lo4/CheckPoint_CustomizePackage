function Set-StringFormat {
    <#
    .SYNOPSIS
        Applies ANSI text formatting (underline, bold, italic, blink) to a string or substring.

    .DESCRIPTION
        This function adds ANSI escape sequences to format text for console display. It can apply
        formatting to an entire string, a specific character position, or a range of characters.
        Supports underline, bold, italic, and blink formatting styles, which can be combined.
        The function uses ANSI escape codes (ESC[XXm) that are supported by modern terminals
        including PowerShell 5.1+ and Windows Terminal.

    .PARAMETER InputObject
        The string to format. This parameter is mandatory, can be used at position 0, and accepts
        pipeline input. Works with all parameter sets.

    .PARAMETER Start
        The zero-based starting position for formatting. This parameter is mandatory in the
        "StartEnd" parameter set and can be used at position 1. Formatting begins at this character
        index (inclusive).

    .PARAMETER End
        The zero-based ending position for formatting. This parameter is optional in the "StartEnd"
        parameter set and can be used at position 2. Formatting ends at this character index
        (exclusive). If not specified, formats to the end of the string.

    .PARAMETER Position
        The zero-based position of a single character to format. This parameter is mandatory in
        the "Position" parameter set and can be used at position 2. Formats only the character
        at this index.

    .PARAMETER Underline
        Switch parameter. When specified, applies underline formatting to the text.
        ANSI codes: ESC[4m (start), ESC[24m (end).

    .PARAMETER Bold
        Switch parameter. When specified, applies bold formatting to the text.
        ANSI codes: ESC[1m (start), ESC[22m (end).

    .PARAMETER Italic
        Switch parameter. When specified, applies italic formatting to the text.
        ANSI codes: ESC[3m (start), ESC[23m (end).
        Note: Not all terminals support italic rendering.

    .PARAMETER Blink
        Switch parameter. When specified, applies blink formatting to the text.
        ANSI codes: ESC[5m (start), ESC[25m (end).
        Note: Blink is rarely supported in modern terminals.

    .OUTPUTS
        Returns a string with ANSI escape sequences inserted at the appropriate positions.

    .EXAMPLE
        Set-StringFormat "Hello World" -Underline
        # Returns: "ESC[4mHello WorldESC[24m" (entire string underlined)

        Applies underline formatting to the entire string.

    .EXAMPLE
        "Important" | Set-StringFormat -Bold -Underline
        # Returns: "ESC[1mESC[4mImportantESC[24mESC[22m" (bold and underlined)

        Combines bold and underline formatting on the entire string via pipeline.

    .EXAMPLE
        Set-StringFormat "Hello World" -Start 6 -End 11 -Bold
        # Returns: "Hello ESC[1mWorldESC[22m" (only "World" is bold)

        Applies bold formatting to characters from index 6 to 10 (end is exclusive).

    .EXAMPLE
        Set-StringFormat "Hello World" -Start 6 -Italic
        # Returns: "Hello ESC[3mWorldESC[23m" (from index 6 to end)

        Applies italic formatting from position 6 to the end of the string.

    .EXAMPLE
        Set-StringFormat "Test" -Position 0 -Underline
        # Returns: "ESC[4mTESC[24mest" (only first character 'T' underlined)

        Applies underline to a single character at position 0.

    .EXAMPLE
        "Error: Something failed" | Set-StringFormat -Start 0 -End 6 -Bold | Write-Host
        # Displays: "Error:" in bold, rest in normal

        Highlights the "Error:" prefix in bold.

    .NOTES
        Module: CLIDialog
        Author: Loïc Ade
        Created: 2025-10-20
        Version: 1.0.0
        Dependencies: None

        This function is part of the CLI String utilities and is commonly used with CLI Dialog
        framework for highlighting specific parts of text.

        PARAMETER SETS:
        - All (default): Formats the entire string (no Start/End/Position)
        - StartEnd: Formats from Start to End (or end of string if End omitted)
        - Position: Formats a single character at Position

        ANSI ESCAPE SEQUENCES:
        - Underline: ESC[4m to start, ESC[24m to end
        - Bold: ESC[1m to start, ESC[22m to end
        - Italic: ESC[3m to start, ESC[23m to end
        - Blink: ESC[5m to start, ESC[25m to end
        - Multiple styles can be combined

        TERMINAL COMPATIBILITY:
        - Windows PowerShell 5.1+: Supports ANSI escape codes
        - Windows Terminal: Full support for all formatting
        - PowerShell Core/7+: Full support
        - Legacy Console (cmd.exe): Limited or no support
        - Italic and Blink: Not universally supported across all terminals

        INDEX BEHAVIOR:
        - Start: Inclusive (formatting starts at this position)
        - End: Exclusive (formatting stops before this position)
        - Position: Formats only the character at this index
        - All indices are zero-based

        COMBINING FORMATS:
        - Multiple switches can be used together (e.g., -Bold -Underline)
        - ANSI codes are stacked in order: Underline, Bold, Italic, Blink
        - End codes are added in reverse order for proper nesting

        USAGE WITH CLI DIALOG:
        - Often used to create underlined keyboard shortcuts in button text
        - Can highlight important parts of messages or prompts
        - Works with New-CLIDialogText, New-CLIDialogProperty, etc.

        CHANGELOG:

        Version 1.0.0 - 2025-10-20 - Loïc Ade
            - Initial release
            - Three parameter sets: All, StartEnd, Position
            - Four formatting styles: Underline, Bold, Italic, Blink
            - Combinable formatting styles
            - Pipeline support
            - ANSI escape sequence injection
            - Zero-based indexing with inclusive Start and exclusive End
    #>
    [CmdletBinding(DefaultParameterSetName = "All")]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ParameterSetName = "StartEnd")]
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ParameterSetName = "Position")]
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ParameterSetName = "All")]
        [string]$InputObject,
        [Parameter(Mandatory, Position = 1, ParameterSetName = "StartEnd")]
        [int]$Start,
        [Parameter(Position = 2, ParameterSetName = "StartEnd")]
        [int]$End,
        [Parameter(Mandatory, Position = 2, ParameterSetName = "Position")]
        [int]$Position,
        [switch]$Underline,
        [switch]$Bold,
        [switch]$Italic,
        [switch]$Blink
    )
    $sStartChar, $sEndChar = "", ""
    if ($Underline) {
        $sStartChar += "$([char]27)[4m"
        $sEndChar += "$([char]27)[24m"
    }
    if ($Bold) {
        $sStartChar += "$([char]27)[1m"
        $sEndChar += "$([char]27)[22m"
    }
    if ($Italic) {
        $sStartChar += "$([char]27)[3m"
        $sEndChar += "$([char]27)[23m"
    }
    if ($Blink) {
        $sStartChar += "$([char]27)[5m"
        $sEndChar += "$([char]27)[25m"
    }
    $iEnd = switch ($PSCmdlet.ParameterSetName) {
        "All" { $InputObject.Length }
        "StartEnd" { if ($PSBoundParameters.ContainsKey("End")) { $End } else { $InputObject.Length } }
        "Position" { $Position + 1 }
    }
    $iStart = switch ($PSCmdlet.ParameterSetName) {
        "All" { 0 }
        "StartEnd" { $Start }
        "Position" { $Position }
    }
    return $InputObject.Insert($iEnd, $sEndChar).Insert($iStart, $sStartChar)
}
