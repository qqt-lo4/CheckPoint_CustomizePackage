function Invoke-Pause {
    <#
    .SYNOPSIS
        Pauses script execution and waits for user to press any key, with customizable message display.

    .DESCRIPTION
        This function provides an enhanced pause mechanism for PowerShell scripts with options to
        control how the pause message is displayed and replaced after the user presses a key.
        Unlike the built-in pause command, it offers three display modes:

        1. ReplaceByEmptyLine (default): Message is replaced by spaces (appears to vanish)
        2. ReplaceByLine: Message is replaced by a line of dashes (visual separator)
        3. Neither: Message remains with a new line added below it

        The function uses [System.Console]::ReadKey($true) to capture keypresses without echoing
        them to the console, providing a clean user experience. It supports custom messages and
        color customization for both the message and replacement line.

    .PARAMETER Message
        The message to display while waiting for user input.
        Default: "Press any key to continue..."

        This message is shown without a newline, keeping the cursor on the same line.

    .PARAMETER ReplaceByLine
        When specified, after the user presses a key, the message is replaced with a line of
        dashes (-) matching the message length. The line appears in the LineColor.

        This creates a visual separator effect and is mutually exclusive with ReplaceByEmptyLine.

    .PARAMETER ReplaceByEmptyLine
        When specified (or by default), after the user presses a key, the message is replaced
        with spaces, making it appear to vanish from the screen.

        This is the default behavior and is mutually exclusive with ReplaceByLine.

    .PARAMETER MessageColor
        The console color for the pause message. If not specified, uses the current console
        foreground color.

        Valid values: Black, DarkBlue, DarkGreen, DarkCyan, DarkRed, DarkMagenta, DarkYellow,
        Gray, DarkGray, Blue, Green, Cyan, Red, Magenta, Yellow, White

    .PARAMETER LineColor
        The console color for the replacement line (when ReplaceByLine is used).
        Default: Blue

        Only affects output when -ReplaceByLine is specified.

    .OUTPUTS
        None. This function does not return any value.

    .EXAMPLE
        Invoke-Pause

        Displays "Press any key to continue..." and waits. After keypress, message vanishes.

    .EXAMPLE
        Invoke-Pause -Message "Press ENTER to proceed with installation..."

        Displays custom message, then makes it vanish after keypress.

    .EXAMPLE
        Invoke-Pause -ReplaceByLine -MessageColor Yellow -LineColor Cyan

        Shows yellow message, then replaces it with a cyan line of dashes after keypress.

    .EXAMPLE
        Invoke-Pause -Message "Review the output above" -ReplaceByLine

        Shows message, then draws a blue separator line after keypress, useful for visually
        separating script output sections.

    .EXAMPLE
        Write-Host "Configuration completed successfully!" -ForegroundColor Green
        Invoke-Pause -Message "Press any key to exit..." -MessageColor Green

        Shows success message, then matching green pause message that vanishes on keypress.

    .EXAMPLE
        foreach ($server in $servers) {
            Write-Host "Processing $server..." -ForegroundColor Cyan
            Process-Server $server
            Invoke-Pause -Message "Press any key for next server..." -ReplaceByLine
        }

        Pauses between server processing with visual separators.

    .NOTES
        Author: Loïc Ade
        Created: 2025-01-16
        Version: 1.0.0
        Module: CLIDialog
        Dependencies: None

        The function uses carriage return (`r) to move the cursor back to the beginning of
        the line, then overwrites the message with either spaces or dashes. This creates
        the effect of message replacement without scrolling the console.

        PARAMETER SETS:
        The function uses PowerShell parameter sets to ensure ReplaceByLine and ReplaceByEmptyLine
        are mutually exclusive:
        - "ReplaceByEmptyLine" (default): Message replaced by spaces
        - "ReplaceByLine": Message replaced by dashes

        KEYPRESS HANDLING:
        Uses [System.Console]::ReadKey($true) where:
        - $true parameter = intercept key (don't echo to console)
        - Returns immediately on any keypress
        - Accepts any key (Enter, Space, letters, etc.)

        REPLACEMENT MECHANISM:
        After keypress, the function:
        1. Outputs carriage return (`r) to move cursor to line start
        2. Outputs replacement characters (spaces or dashes) matching message length
        3. Line color is used for the replacement line (only visible with ReplaceByLine)

        USE CASES:
        - Pausing script execution for user review
        - Creating visual separators in script output
        - Allowing users to control script pacing
        - Interactive scripts requiring user acknowledgment
        - Step-by-step script execution

        COMPARISON WITH ALTERNATIVES:
        - Read-Host "Press Enter": Requires specific key, shows input
        - pause (cmd): Shows "Press any key...", leaves message visible
        - Invoke-Pause (this): Customizable message and post-keypress behavior

        DISPLAY MODES COMPARISON:

        ReplaceByEmptyLine (default):
        Before: "Press any key to continue..."
        After:  (blank line)

        ReplaceByLine:
        Before: "Press any key to continue..."
        After:  "-------------------------------" (blue by default)

        Neither (no switch):
        Before: "Press any key to continue..."
        After:  "Press any key to continue..."
                (cursor moved to next line)

    .LINK
        Read-Host
        Write-Host
    #>
    [CmdletBinding(DefaultParameterSetName = "ReplaceByEmptyLine")]
    Param(
        [string]$Message = "Press any key to continue...",
        [Parameter(ParameterSetName = "ReplaceByLine")]
        [switch]$ReplaceByLine,
        [Parameter(ParameterSetName = "ReplaceByEmptyLine")]
        [switch]$ReplaceByEmptyLine,
        [System.ConsoleColor]$MessageColor,
        [System.ConsoleColor]$LineColor = ([System.ConsoleColor]::Blue)
    )
    if ($MessageColor) {
        Write-Host $Message -NoNewline -ForegroundColor $MessageColor
    } else {
        Write-Host $Message -NoNewline
    }
    [void][System.Console]::ReadKey($true)
    if ($ReplaceByLine -or $ReplaceByEmptyLine) {
        $LineMessage = "`r"
        if ($ReplaceByLine) {
            $LineMessage += ("-" * $Message.Length)
        } else {
            $LineMessage += (" " * $Message.Length)
        }
        Write-Host $LineMessage -ForegroundColor $LineColor
    } else {
        Write-Host ([Environment]::NewLine) -NoNewline
    }
}
