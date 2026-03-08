function Read-FileNonBlocking {
    <#
    .SYNOPSIS
        Reads a file without locking it, allowing other processes to continue writing

    .DESCRIPTION
        Uses FileShare.ReadWrite to read a file that may be actively written to
        by another process, avoiding locking conflicts.

    .PARAMETER Path
        Path to the file to read

    .OUTPUTS
        String content of the file, or $null if unable to read

    .EXAMPLE
        Read-FileNonBlocking -Path "C:\logs\active.log"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    Param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        return $null
    }

    try {
        $fileStream = [System.IO.File]::Open(
            $Path,
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::Read,
            [System.IO.FileShare]::ReadWrite
        )

        $reader = New-Object System.IO.StreamReader($fileStream)
        $content = $reader.ReadToEnd()

        $reader.Close()
        $fileStream.Close()

        return $content
    }
    catch {
        Write-Verbose "Could not read file: $_"
        return $null
    }
}
