function Restart-OneDrive {
    <#
    .SYNOPSIS
        Restarts the OneDrive client

    .DESCRIPTION
        Shuts down the running OneDrive process (if any), waits for it to exit,
        then relaunches it in the background. Automatically locates the executable
        if no path is provided.

    .PARAMETER OneDriveClientPath
        Path to the OneDrive executable. Auto-detected if not specified.

    .EXAMPLE
        Restart-OneDrive

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    Param(
        [string]$OneDriveClientPath
    )
    $odPath = if (($null -eq $OneDriveClientPath) -or ($OneDriveClientPath -eq "")) {
        $OnedriveEXEs = Get-Item "C:\Program Files*\Microsoft OneDrive\OneDrive.exe" , "$env:LOCALAPPDATA\Microsoft\Onedrive\onedrive.exe" -ErrorAction SilentlyContinue
    
        if ($null -eq $OnedriveEXEs) {
            throw [System.IO.FileNotFoundException] "OneDrive is not installed"
        } elseif (@($OnedriveEXEs).Count -gt 1) {
            Write-Warning "Hi you managed to apparently have both a per-user and per-machine install"
            Write-Warning "Congratulations! I couldn't manage to replicate or rule this out with my testing, so no promises if this works at all"
            
            ($OnedriveEXEs | Select-Object -first 1).FullName
        } else {
            $OnedriveEXEs.FullName
        }
    } elseif (-not (Test-Path $OneDriveClientPath)) {
        throw [System.IO.FileNotFoundException] "OneDrive is not installed or path is invalid"
    } else {
        $OneDriveClientPath
    }
    if ($null -ne (Get-Process onedrive -ErrorAction SilentlyContinue)) {
        &$odPath /shutdown
        Wait-Process -Name "onedrive"
    }
    &$odPath /background
}