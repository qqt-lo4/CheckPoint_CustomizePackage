function Get-ScriptLogFile {
    Param(
        [ValidateNotNullOrEmpty()]
        [string]$log_folder = $env:Temp,
        [string]$fallback_folder = $null
    )
    $filename = Get-ScriptLogFileName
    if (Test-Path -Path $log_folder -PathType Container) {
        $log_folder + $filename
    } else {
        if ($fallback_folder -eq $null) {
            throw [System.IO.DirectoryNotFoundException] "Directory $log_folder does not exists"
        } else {
            if (Test-Path -Path $fallback_folder -PathType Container) {
                $fallback_folder + $filename
            } else {
                throw [System.IO.DirectoryNotFoundException] "Directories $log_folder and $fallback_folder do not exist"
            }
        }
    }
}
