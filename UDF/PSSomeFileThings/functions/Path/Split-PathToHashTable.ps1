function Split-PathToHashTable {
    <#
    .SYNOPSIS
        Splits a path into components returned as a hashtable

    .DESCRIPTION
        Parses a Windows path and returns all components (Root, Parent, ItemName,
        ItemNameWithoutExt, Extension, FullPath) as an ordered hashtable.

    .PARAMETER Path
        Path to split.

    .OUTPUTS
        [Hashtable]. Ordered hashtable with path components.

    .EXAMPLE
        Split-PathToHashTable -Path "C:\folder\file.txt"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]$Path
    )
    $sWindowsPathRegEx = "^(?<fullpath>(?<parent>(?<root>([^:]+):)\\.+)(\\((?<itemname>[^\\]+))))\\?$"
    if ($Path[0] -match $sWindowsPathRegEx) {
        $sRoot = $Matches.root
        $sParent = $Matches.parent
        $sItemName = $Matches.itemname
        $sFullPath = $Matches.fullpath
        if ($sItemName -match "^(?<itemnamewithoutext>.+)(\.(?<ext>[^.]+))$") {
            $sItemNameWithoutExt = $Matches.itemnamewithoutext
            $sExtension = $Matches.ext
        }
        $hResult = [ordered]@{
            "Root" = $sRoot
            "Parent" = $sParent
            "ItemName" = $sItemName
            "ItemNameWithoutExt" = $sItemNameWithoutExt
            "Extension" = $sExtension
            "FullPath" = $sFullPath
        }
        return $hResult
    }
}
