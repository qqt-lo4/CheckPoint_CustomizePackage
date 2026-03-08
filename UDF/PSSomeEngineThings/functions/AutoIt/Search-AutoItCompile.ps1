function Search-AutoItCompile {
    <#
    .SYNOPSIS
        Searches for the AutoIt compiler executable

    .DESCRIPTION
        Locates the AutoIt Aut2Exe compiler by querying shell extension commands.
        Supports both standard and beta versions, and x86/x64 variants.

    .PARAMETER Beta
        If specified, searches for the beta version of AutoIt compiler.

    .PARAMETER X64
        If specified, searches for the x64 compiler instead of x86.

    .OUTPUTS
        [PSCustomObject]. Object containing Program path and Arguments for the compiler.

    .EXAMPLE
        Search-AutoItCompile

    .EXAMPLE
        Search-AutoItCompile -Beta -X64

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [switch]$Beta,
        [switch]$X64
    )
    Begin {
        $sAutoItEdition = if ($Beta.IsPresent) { "AutoIt3ScriptBeta" } else { "AutoIt3Script" }
        $sPlateformTarget = if ($x64.IsPresent) { "X64" } else { "X86" }
    }
    Process {
        try {
            return Get-FileTypeShellExtensionCommand -FileType "$sAutoItEdition" -ShellExtensionName "Compile$sPlateformTarget"
        } catch {
            throw [System.IO.FileNotFoundException] "Autoit or AutoIt Beta not installed"            
        }
    }
}