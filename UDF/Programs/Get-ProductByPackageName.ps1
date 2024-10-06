function Get-ProductByPackageName {
    param (
        [AllowNull()]
        [object]$programs,
        [string[]]$packageName
    )
    $allprograms = if ($programs) {
        $programs
    } else {
        Get-InstalledPrograms 
    }
    $allprograms | Where-Object { ($_.PackageName -iin $packageName) }   
}