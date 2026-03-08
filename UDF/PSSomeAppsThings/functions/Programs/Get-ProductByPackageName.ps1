function Get-ProductByPackageName {
    <#
    .SYNOPSIS
        Finds installed products by their AppX package name

    .DESCRIPTION
        Searches installed programs for entries matching the specified AppX package names.
        Uses case-insensitive comparison on the PackageName property.

    .PARAMETER programs
        Optional pre-loaded list of installed programs. If not provided, calls Get-InstalledPrograms.

    .PARAMETER packageName
        One or more AppX package names to search for

    .OUTPUTS
        PSCustomObject[]. Matching installed program objects.

    .EXAMPLE
        Get-ProductByPackageName -packageName "Microsoft.WindowsTerminal"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
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