function Format-TableCustom {
    Param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [object[]]$InputObject,
        [Parameter(Position = 1)]
        [object[]]$Property,
        [switch]$HideHeader,
        [System.ConsoleColor]$HeaderColor = (Get-Host).UI.RawUI.ForegroundColor,
        [switch]$HeaderUnderline,
        [switch]$ToString,
        [int]$ContentMaxWidth = (Get-Host).UI.RawUI.WindowSize.Width
    )
    Begin {
        function Get-HashtableName {
            Param(
                [Parameter(Mandatory, Position = 0)]
                [hashtable]$InputObject
            )
            $aName = $InputObject.Keys | Where-Object { $_ -in @("l", "label", "n", "name") }
            if ($aName) {
                return $InputObject.$aName
            } else {
                throw "Hashtable does not have a name"
            }
        }
        $aSelectProperties = @("l", "label", "n", "name", "e", "expression")
        $aInputObject = @()
    }
    Process {
        $aInputObject += $InputObject
    }
    End {
        $aSelectedObjects = if ($Property) {
            $aSelectObjectProperties = $Property | ForEach-Object -Process { if ($_ -is [string]) { $_ } else { Copy-Hashtable -InputObject $_ -Properties $aSelectProperties } }
            $aInputObject | ForEach-Object { [pscustomobject]$_ | Select-Object -Property $aSelectObjectProperties }
        } else {
            $aInputObject
        }
        $aColumnFormatAdditionalProperties = if ($Property) {
            $Property | ForEach-Object -Begin { $hResult = @{} } -Process { if ($_ -isnot [string]) {$h = Copy-Hashtable -InputObject $_ -Properties $aSelectProperties -Not ; if ($h) { $hResult.$(Get-HashtableName $_) = $h }}} -End { $hResult }
        } else {
            $null
        }
        $aColumnFormat = Get-ColumnFormat -SelectedObjects $aSelectedObjects -AddColumnnFormat $aColumnFormatAdditionalProperties
        $iMaxTableWidth = 0
        $iColumnAutoWidth = 0
        $oAutoWidthColumn = $null
        $hColumns = @{}
        foreach ($column in $aColumnFormat) {
            $hColumns[$column.Name] = $column
            if ($column.AutoWidth) {
                $iColumnAutoWidth = $column.ContentMaxWidth
                $oAutoWidthColumn = $column
            } else {
                $column.Width = if ($column.Name.Length -gt $column.ContentMaxWidth) { $column.Name.Length } else { $column.ContentMaxWidth }
                $iMaxTableWidth += $column.Width
            }
        }
        $iMaxTableWidth += ($aColumnFormat.Count - 1)
        if (($iMaxTableWidth + $iColumnAutoWidth) -le $ContentMaxWidth) {
            $iMaxTableWidth += $iColumnAutoWidth
            if ($oAutoWidthColumn) {
                $oAutoWidthColumn.Width = $iColumnAutoWidth
            }
        } else {
            $oAutoWidthColumn.Width = $ContentMaxWidth - $iMaxTableWidth
        }
    
        $aResultLine = @()
        
        if (-not $HideHeader) {
            $sHeaderLine = "$([char]27)[" + (Convert-ConsoleColorToInt $HeaderColor) + "m"
            if ($aColumnFormat -is [array]) {
                for($i = 0; $i -lt $aColumnFormat.Name.Count; $i++) {
                    $sPropertyName = $aColumnFormat.Name[$i]
                    $column = $hColumns[$sPropertyName]
                    $iAlign = if ($column.Alignment -eq "left") { -1 } else { 1 }
                    $sHeaderLine += ("{0,$($column.width * $iAlign)}" -f $column.Name) 
                    if ($i -lt ($aColumnFormat.Name.Count - 1)) {
                        $sHeaderLine += " "
                    }
                }    
            } else {
                $column = $aColumnFormat
                $iAlign = if ($column.Alignment -eq "left") { -1 } else { 1 }
                $sHeaderLine += ("{0,$($column.width * $iAlign)}" -f $column.Name) + " "
            }
            $sHeaderLine += "$([char]27)[0m"
            $aResultLine += $sHeaderLine
            if ($HeaderUnderline) {
                $sUnderLine = "$([char]27)[" + (Convert-ConsoleColorToInt $HeaderColor) + "m"
                for($i = 0; $i -lt $aColumnFormat.Name.Count; $i++) {
                    $sPropertyName = $aColumnFormat.Name[$i]
                    $column = $hColumns[$sPropertyName]
                    $sUnderLine += ("-" * $sPropertyName.Length) + (" " * ($column.Width - $sPropertyName.Length))
                    if ($i -lt ($aColumnFormat.Name.Count - 1)) {
                        $sUnderLine += " "
                    }
                }
                $aResultLine += $sUnderLine
            }
        }
    
        foreach ($Object in $aSelectedObjects) {
            $sLine = ""
            if ($Object.PSObject.Properties.Name -is [array]) {
                for($i = 0; $i -lt $Object.PSObject.Properties.Name.Count; $i++) {
                    $sPropertyName = $Object.PSObject.Properties.Name[$i]
                    $column = $hColumns[$sPropertyName]
                    $iAlign = if ($column.Alignment -eq "left") { -1 } else { 1 }
                    $sValue = $Object.$sPropertyName
                    if ($sValue.Length -gt $column.width) {
                        $sValue = $sValue.SubString(0, $column.width - 1) + "…"
                    } 
                    $sLine += ("{0,$($column.width * $iAlign)}" -f $sValue) 
                    if ($i -lt ($Object.PSObject.Properties.Name.Count - 1)) {
                        $sLine += " "
                    }
                }    
            } else {
                $sPropertyName = $Object.PSObject.Properties.Name
                $column = $hColumns[$sPropertyName]
                $iAlign = if ($column.Alignment -eq "left") { -1 } else { 1 }     
                $sValue = $Object.$sPropertyName
                if ($sValue.Length -gt $column.width) {
                    $sValue = $sValue.SubString(0, $column.width - 1) + "…"
                }
                $sLine += ("{0,$($column.width * $iAlign)}" -f $sValue) 
            }
            $aResultLine += $sLine
        }
        if ($ToString) {
            return $aResultLine
        } else {
            $aResultLine | Write-Host
        }    
    }
}
