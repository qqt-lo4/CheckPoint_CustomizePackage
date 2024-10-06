function New-CLIDialogTableItems {
    Param(
        [Parameter(Mandatory)]
        [Object[]]$Objects,
        [AllowNull()]
        [object]$Properties,
        [switch]$Checkbox,
        [ref]$EnabledObjectsArray,
        [string]$EnabledObjectsUniqueProperty
    )
    $ContentMaxWidth = if ($Checkbox) {
        (Get-Host).UI.RawUI.WindowSize.Width - 4
    } else {
        (Get-Host).UI.RawUI.WindowSize.Width
    }
    $aFormatTableItems = $Objects | Format-TableCustom -ToString -HeaderColor Green -Property $Properties -ContentMaxWidth $ContentMaxWidth
    $aFormRows = @(
        # First line containing array headers
        $sFirstRowText = if ($Checkbox) {
            "    $($aFormatTableItems[0])"
        } else {
            $aFormatTableItems[0]
        }
        New-CLIDialogText -Text $sFirstRowText -ForegroundColor Green -AddNewLine
    )
    for ($i = 1; $i -lt $aFormatTableItems.Count; $i++) {
        $hParams = @{
            Text = $aFormatTableItems[$i]
            Object = $Objects[$i - 1] 
            AddNewLine = $true 
            NoSpace = $true
        }
        $aFormRows += if ($Checkbox) {
            if ($EnabledObjectsArray) {
                if ($EnabledObjectsArray.Value | Where-Object { $_.$EnabledObjectsUniqueProperty -eq $Objects[$i - 1].$EnabledObjectsUniqueProperty }) {
                    New-CLIDialogCheckBox @hParams -Enabled $true
                } else {
                    New-CLIDialogCheckBox @hParams -Enabled $false
                }
            } else {
                New-CLIDialogCheckBox @hParams
            }
        } else {
            New-CLIDialogButton @hParams
        }
    }
    return $aFormRows
}
