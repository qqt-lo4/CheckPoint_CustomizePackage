function Split-PathToHashTable {
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
