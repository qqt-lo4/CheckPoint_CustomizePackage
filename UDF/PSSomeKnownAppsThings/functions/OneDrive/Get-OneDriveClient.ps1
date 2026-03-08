function Get-OneDriveClient {
    <#
    .SYNOPSIS
        Gets the OneDrive client executable path

    .DESCRIPTION
        Locates the OneDrive executable by checking both per-machine
        (Program Files) and per-user (LOCALAPPDATA) install locations.
        Warns if both are found.

    .OUTPUTS
        [System.IO.FileInfo]. The OneDrive executable file info.

    .EXAMPLE
        $onedrive = Get-OneDriveClient

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdletBinding()]

    $OnedriveEXEs = Get-Item "C:\Program Files*\Microsoft OneDrive\OneDrive.exe" , "$env:LOCALAPPDATA\Microsoft\Onedrive\onedrive.exe" -ErrorAction SilentlyContinue
    
    if ($null -eq $OnedriveEXEs) {
        Write-Error "No OneDrive EXE Found. Please ensure you are running as the user you want to act on, not System"
    } elseif (@($OnedriveEXEs).Count -gt 1) {
        Write-Warning "Hi you managed to apparently have both a per-user and per-machine install"
        Write-Warning "Congratulations! I couldn't manage to replicate or rule this out with my testing, so no promises if this works at all"
        
        return ($OnedriveEXEs | Select-Object -first 1)
    } else {
        return $OnedriveEXEs
    }
}