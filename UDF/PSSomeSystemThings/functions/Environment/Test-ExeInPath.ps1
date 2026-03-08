function Test-ExeInPath {
    <#
    .SYNOPSIS
        Searches for an executable file in PATH directories

    .DESCRIPTION
        Checks each directory in the system PATH environment variable for the
        specified executable file and returns all matching full paths.

    .PARAMETER ExeFile
        The executable filename to search for (e.g., "python.exe").

    .OUTPUTS
        [string[]]. Full paths where the executable was found.

    .EXAMPLE
        Test-ExeInPath -ExeFile "git.exe"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    Param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$ExeFile
    )
    $aPath = ($env:Path).Split(";") | Select-Object -Unique
    $aResult = @()
    foreach ($item in $aPath) {
        $exeItemPath = ($item + "\" + $ExeFile).Replace("\\", "\")
        if (Test-Path -Path ($exeItemPath)) {
            $aResult += $exeItemPath
        }
    }
    return $aResult
}
