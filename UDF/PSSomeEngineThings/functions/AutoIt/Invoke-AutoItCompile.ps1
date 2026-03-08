function Invoke-AutoItCompile {
    <#
    .SYNOPSIS
        Compiles an AutoIt script to executable

    .DESCRIPTION
        Invokes the AutoIt compiler (Aut2Exe) to compile an AutoIt script (.au3) to an executable (.exe).
        Supports beta versions, x64 compilation, and custom icons.

    .PARAMETER File
        Path to the AutoIt script file (.au3) to compile.

    .PARAMETER Icon
        Optional path to an icon file (.ico) to embed in the executable.

    .PARAMETER Beta
        If specified, uses the beta version of the AutoIt compiler.

    .PARAMETER X64
        If specified, compiles for x64 architecture instead of x86.

    .OUTPUTS
        None. Compiles the script and creates an executable.

    .EXAMPLE
        Invoke-AutoItCompile -File "C:\Scripts\MyScript.au3"

    .EXAMPLE
        Invoke-AutoItCompile -File "C:\Scripts\MyScript.au3" -Icon "C:\Icons\app.ico" -X64

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$File,
        [string]$Icon,
        [switch]$Beta,
        [switch]$X64
    )

    Begin {
        $hAutoITCompile = Search-AutoItCompile -Beta:$Beta -X64:$X64
        $hAutoITCompile.Arguments = $hAutoITCompile.Arguments -replace "%l", $File
        if ($Icon) {
            $hAutoITCompile.Arguments += " /icon `"$Icon`""
        }
    }
    Process {
        Start-Process -FilePath $hAutoITCompile.Program -ArgumentList $hAutoITCompile.Arguments -Wait
    }
}