function Invoke-Pause {
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
