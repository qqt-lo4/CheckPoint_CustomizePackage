# Load all .ps1 functions from the module directory and subdirectories
foreach ($Script in (Get-ChildItem -Path $PSScriptRoot -Filter '*.ps1' -File -Recurse -FollowSymlink)) {
    try {
        . $Script.FullName
    } catch {
        Write-Error "Failed to load $($Script.FullName): $_"
    }
}
