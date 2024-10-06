function Invoke-AutoItCompile {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$File,
        [switch]$Beta,
        [switch]$X64
    )

    Begin {
        $hAutoITCompile = Search-AutoItCompile -Beta:$Beta -X64:$X64
        $hAutoITCompile.Arguments = $hAutoITCompile.Arguments -replace "%l", $File
    }
    Process {
        Start-Process -FilePath $hAutoITCompile.Program -ArgumentList $hAutoITCompile.Arguments -Wait
    }
}