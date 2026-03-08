function Set-StringUnderline {
    <#
    .SYNOPSIS
        Applies underline formatting to a string or substring using ANSI escape sequences.

    .DESCRIPTION
        This is a convenience wrapper function around Set-StringFormat that specifically applies
        underline formatting. It simplifies the syntax by automatically specifying the -Underline
        switch. Supports formatting the entire string, a specific character position, or a range
        of characters. Uses ANSI escape codes (ESC[4m and ESC[24m) that are supported by modern
        terminals including PowerShell 5.1+ and Windows Terminal.

    .PARAMETER InputObject
        The string to underline. This parameter is mandatory, can be used at position 0, and
        accepts pipeline input. Works with all parameter sets.

    .PARAMETER Start
        The zero-based starting position for underline formatting. This parameter is mandatory
        in the "StartEnd" parameter set and can be used at position 1. Underlining begins at
        this character index (inclusive).

    .PARAMETER End
        The zero-based ending position for underline formatting. This parameter is optional in
        the "StartEnd" parameter set and can be used at position 2. Underlining ends at this
        character index (exclusive). If not specified, underlines to the end of the string.

    .PARAMETER Position
        The zero-based position of a single character to underline. This parameter is mandatory
        in the "Position" parameter set and can be used at position 2. Underlines only the
        character at this index.

    .OUTPUTS
        Returns a string with ANSI underline escape sequences (ESC[4m and ESC[24m) inserted
        at the appropriate positions.

    .EXAMPLE
        Set-StringUnderline "Hello World"
        # Returns: "ESC[4mHello WorldESC[24m" (entire string underlined)

        Applies underline to the entire string.

    .EXAMPLE
        "Important Text" | Set-StringUnderline
        # Returns: "ESC[4mImportant TextESC[24m" (underlined via pipeline)

        Underlines the entire string via pipeline.

    .EXAMPLE
        Set-StringUnderline "Hello World" -Start 6 -End 11
        # Returns: "Hello ESC[4mWorldESC[24m" (only "World" is underlined)

        Underlines characters from index 6 to 10 (end is exclusive).

    .EXAMPLE
        Set-StringUnderline "Hello World" -Start 0 -End 5
        # Returns: "ESC[4mHelloESC[24m World" (only "Hello" is underlined)

        Underlines the first word from position 0 to 4.

    .EXAMPLE
        Set-StringUnderline "Test" -Position 0
        # Returns: "ESC[4mTESC[24mest" (only first character 'T' underlined)

        Underlines a single character at position 0.

    .EXAMPLE
        "&Save" -replace "&", "" | Set-StringUnderline -Position 0
        # Returns: "ESC[4mSESC[24mave" (creates underlined shortcut character)

        Creates an underlined keyboard shortcut by underlining the first character.

    .NOTES
        Module: CLIDialog
        Author: Loïc Ade
        Created: 2025-10-20
        Version: 1.0.0
        Dependencies: Set-StringFormat

        This function is a convenience wrapper around Set-StringFormat. It simplifies common
        underline operations by eliminating the need to specify the -Underline switch.

        PARAMETER SETS:
        - All (default): Underlines the entire string (no Start/End/Position)
        - StartEnd: Underlines from Start to End (or end of string if End omitted)
        - Position: Underlines a single character at Position

        ANSI ESCAPE SEQUENCES:
        - Start underline: ESC[4m (where ESC is character code 27)
        - End underline: ESC[24m
        - Format: $([char]27)[4m and $([char]27)[24m in PowerShell

        TERMINAL COMPATIBILITY:
        - Windows PowerShell 5.1+: Supports ANSI escape codes
        - Windows Terminal: Full support
        - PowerShell Core/7+: Full support
        - Legacy Console (cmd.exe): Limited or no support

        INDEX BEHAVIOR:
        - Start: Inclusive (underlining starts at this position)
        - End: Exclusive (underlining stops before this position)
        - Position: Underlines only the character at this index
        - All indices are zero-based

        COMMON USE CASES:
        - Highlighting keyboard shortcuts in menu items
        - Emphasizing important words or phrases
        - Creating visual focus on specific text segments
        - Formatting command-line interface prompts

        RELATION TO OTHER FUNCTIONS:
        - This is a wrapper for Set-StringFormat -Underline
        - For multiple formatting styles (bold, italic, blink), use Set-StringFormat directly
        - Often used with CLI Dialog framework for button shortcuts

        CHANGELOG:

        Version 1.0.0 - 2025-10-20 - Loïc Ade
            - Initial release
            - Wrapper around Set-StringFormat with -Underline
            - Three parameter sets: All, StartEnd, Position
            - Pipeline support
            - Simplified syntax for underline-only operations
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
        [int]$Position
    )
    return Set-StringFormat -Underline @PSBoundParameters
}
