function Get-JSONFileList {
    <#
    .DESCRIPTION
    Function to get json objects from files in $jsonFolder
    Will return an array of files with two additional properties 
    (the json content in $json and the json description based on $jsonColumn)
    .VERSION 1.0
    First release
    .VERSION 1.1
    Added $Filter to filter files in $jsonFolder
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