function Resolve-RelativePath {
    <#
    .SYNOPSIS
        Resolves a relative path between two locations

    .DESCRIPTION
        Calculates the relative path from one location to another by temporarily
        changing the current location and using Resolve-Path.

    .PARAMETER From
        Starting location.

    .PARAMETER To
        Target location.

    .OUTPUTS
        [String]. Relative path from source to target.

    .EXAMPLE
        Resolve-RelativePath -From "C:\folder1" -To "C:\folder2\file.txt"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [string]$From,
        [string]$To
    )
    $oLocationBefore = Get-Location
    Set-Location $From 
    Resolve-Path -Path $To -Relative
    Set-Location $oLocationBefore
}