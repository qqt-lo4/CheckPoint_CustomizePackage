function Get-ColumnFormat {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [object[]]$SelectedObjects,
        [Parameter(Position = 1)]
        [hashtable]$AddColumnnFormat
    )
    $aProperties = $SelectedObjects[0].PSObject.Properties
    $aFormatProperties = @()
    foreach ($p in $aProperties) {
        $aColumnValues = ($SelectedObjects).$($p.Name)
        $sPropertyName = $p.Name 
        $aTypes = ($aColumnValues | Where-Object { $_ -ne $null } | ForEach-Object { $_.PSTypeNames[0] } |  Group-Object)
        $sType = if ($aTypes) {
            $aTypes[0].Name
        } else {
            "System.String"
        }        
        $sAlign = switch -Regex ($sType) {
            "^System`.Int.*$" { "right" }
            "^System`.Boolean$" { "right" }
            default { "left" }
        }
        $hColumnFormat = [ordered]@{
            Name = $sPropertyName
            Type = $sType
            Alignment = $sAlign
        }
        if ($AddColumnnFormat) {
            if ($AddColumnnFormat[$sPropertyName]) {
                if ($AddColumnnFormat[$sPropertyName].Format) {
                    $hColumnFormat.Format = $AddColumnnFormat[$sPropertyName].Format
                }
                if ($AddColumnnFormat[$sPropertyName].Width) {
                    $hColumnFormat.Width = $AddColumnnFormat[$sPropertyName].Width
                }
                if ($AddColumnnFormat[$sPropertyName].AutoWidth) {
                    $hColumnFormat.AutoWidth = $AddColumnnFormat[$sPropertyName].AutoWidth
                }
            }
        }
        if ($hColumnFormat.Format) {
            $hColumnFormat.Values = $aColumnValues | ForEach-Object { if ($_) { $_.ToString($hColumnFormat.Format) } }
        } else {
            $hColumnFormat.Values = $aColumnValues
        }

        $hColumnFormat.ContentMaxWidth = $hColumnFormat.Values | ForEach-Object -Begin { $iMax = 0 } -Process { if ($_ -and ($_.ToString().Length -gt $iMax)) { $iMax = $_.ToString().Length } } -End { $iMax }
        
        $aFormatProperties += $hColumnFormat
    }
    return $aFormatProperties
}
