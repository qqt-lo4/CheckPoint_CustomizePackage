function Get-JSONFileList {
    <#
    .SYNOPSIS
        Loads and parses all JSON files from a folder

    .DESCRIPTION
        Reads all JSON/JSONC files from a folder and returns objects with the parsed
        JSON content, file info, and specified column values extracted at the top level.

    .PARAMETER JsonFolder
        Path to the folder containing JSON files

    .PARAMETER JsonColumn
        Property names to extract from each JSON object (default: "Description")

    .PARAMETER Filter
        Optional file name filter patterns (e.g., "*.json")

    .OUTPUTS
        PSCustomObject[]. Objects with json, file, and extracted column properties.

    .EXAMPLE
        Get-JSONFileList -JsonFolder "C:\Config" -Filter "*.json"

    .NOTES
        Author  : Loïc Ade
        Version : 1.1.0

        Version 1.0: First release
        Version 1.1: Added $Filter to filter files in $jsonFolder
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$JsonFolder,
        [string[]]$JsonColumn = "Description",
        [string[]]$Filter
    )
    if (Test-Path $JsonFolder -PathType Container) {
        $fileList = if ($Filter) {
            Get-ChildItem -Path ("$JsonFolder\*") -Include $Filter
        } else {
            Get-ChildItem -Path $JsonFolder
        }
        $aResult = @()
        foreach ($item in $fileList) {
            $jsonItem = $(Get-Content $item.FullName | Out-String | ConvertFrom-Jsonc)
            $hItem = @{
                json = $jsonItem
                file = $item
            }
            foreach ($sColumn in $JsonColumn) {
                $hItem[$sColumn] = $jsonItem.$sColumn
            }
            $aResult += [PSCustomObject]$hItem
        }
        return $aResult
    } else {
        throw [System.IO.DirectoryNotFoundException] "Json directory ($JsonFolder) not found"
    }
}