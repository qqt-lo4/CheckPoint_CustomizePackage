function Search-AutoItCompile {
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