function Invoke-Process {
    <#
    .SYNOPSIS
        Launches an external process and captures its standard output and error streams.

    .DESCRIPTION
        Starts an external process using System.Diagnostics.Process, capturing both
        standard output and standard error. Returns a PSCustomObject with Title, Command,
        Arguments, StdOut, StdErr, and ExitCode. The DisplayLevel parameter controls
        what portion of the result is returned (full object, StdOut only, StdErr only,
        ExitCode only, or nothing).

    .PARAMETER FilePath
        Path to the executable to run.

    .PARAMETER ArgumentList
        Command-line arguments to pass to the executable.

    .PARAMETER DisplayLevel
        Controls what is returned. Valid values: "Full" (complete result object),
        "StdOut" (standard output only), "StdErr" (standard error only),
        "ExitCode" (exit code only), "None" (nothing). Default: "Full".

    .PARAMETER Verb
        Process verb to use (e.g., "RunAs" for elevated execution).

    .OUTPUTS
        PSCustomObject with Title, Command, Arguments, StdOut, StdErr, ExitCode
        when DisplayLevel is "Full". Otherwise returns the selected portion.

    .EXAMPLE
        $result = Invoke-Process -FilePath "ping" -ArgumentList "localhost -n 1"
        $result.ExitCode

        Runs ping and returns the full result object.

    .EXAMPLE
        Invoke-Process -FilePath "git" -ArgumentList "status" -DisplayLevel StdOut

        Runs git status and returns only the standard output.

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$ArgumentList,

        [ValidateSet("Full","StdOut","StdErr","ExitCode","None")]
        [string]$DisplayLevel = "Full",

        [string]$Verb
    )

    $ErrorActionPreference = 'Stop'

    try {
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = $FilePath
        $pinfo.RedirectStandardError = $true
        $pinfo.RedirectStandardOutput = $true
        $pinfo.UseShellExecute = $false
        $pinfo.WindowStyle = 'Hidden'
        $pinfo.CreateNoWindow = $true
        $pinfo.Arguments = $ArgumentList
        if ($Verb) {
            $pinfo.Verb = $Verb
        }
        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = $pinfo
        $p.Start() | Out-Null
        $result = [pscustomobject]@{
            Title = ($MyInvocation.MyCommand).Name
            Command = $FilePath
            Arguments = $ArgumentList
            StdOut = $p.StandardOutput.ReadToEnd()
            StdErr = $p.StandardError.ReadToEnd()
            ExitCode = $p.ExitCode
        }
        $p.WaitForExit()

        if (-not([string]::IsNullOrEmpty($DisplayLevel))) {
            switch($DisplayLevel) {
                "Full" { return $result; break }
                "StdOut" { return $result.StdOut; break }
                "StdErr" { return $result.StdErr; break }
                "ExitCode" { return $result.ExitCode; break }
            }
        }
    } catch {
        
    }
}