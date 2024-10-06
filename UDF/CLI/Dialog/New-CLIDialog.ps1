function New-CLIDialog {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [object[]]$Rows,
        [object]$EscapeObject,
        [object]$ValidateObject,
        [object]$RefreshObject,
        [object[]]$HiddenButtons,
        [int]$FocusedRow = 0,
        [bool]$PauseAfterErrorMessage,
        [string]$ValidationErrorMessage,
        [bool]$ValidationErrorDetails,
        [ref]$SelectedObjectsArray,
        [string]$SelectedObjectsUniqueProperty
    )

    function Test-ValidRow {
        Param(
            [Parameter(Mandatory, Position = 0)]
            [object]$Row
        )
        return $Row.Type -in @("text", "row", "textbox", "button", "separator", "property", "checkbox")
    }

    $aObjectIndex = @()
    $bValid = $true
    $aStaticRows = @()
    $aDynamicRows = @()
    $bDynamicObjectFound = $false
    for ($i = 0; $i -lt $Rows.Count; $i++) {
        if (Test-ValidRow $Rows[$i]) {
            if ($bDynamicObjectFound) {
                $aDynamicRows += $Rows[$i]
            } else {
                if ($Rows[$i].IsDynamicObject()) {
                    $bDynamicObjectFound = $true
                    $aDynamicRows += $Rows[$i]
                } else {
                    $aStaticRows += $Rows[$i]
                }
            }
            if ($Rows[$i].IsDynamicObject()) {
                $aObjectIndex += $i
            }
        } else {
            $bValid = $false
        }
    }
    if (-not $bValid) {
        throw "Some objects types are not valid"
    }

    $oEscapeObject = if ($EscapeObject) { $EscapeObject } else {
        foreach ($oRow in $Rows) {
            if ($oRow.Type -eq "row") {
                foreach ($item in $oRow.RowContent) {
                    if ($item.Cancel) {
                        $item
                    }
                }
            }
        }
    }

    $oValidateObject = if ($ValidateObject) { $ValidateObject } else {
        foreach ($oRow in $Rows) {
            if ($oRow.Type -eq "row") {
                foreach ($item in $oRow.RowContent) {
                    if ($item.Validate) {
                        $item
                    }
                }
            }
        }
    }

    $oRefreshObject = if ($RefreshObject) { $RefreshObject } else {
        foreach ($oRow in $Rows) {
            if ($oRow.Type -eq "row") {
                foreach ($item in $oRow.RowContent) {
                    if ($item.Refresh) {
                        $item
                    }
                }
            }
        }
    }

    # Add Row object to Radio Buttons
    foreach ($oRow in $Rows) {
        if ($oRow.Type -eq "row") {
            foreach ($item in $oRow.RowContent) {
                if ($item.Type -eq "radiobutton") {
                    $item.Row = $oRow
                }
            }
        }
    }

    $hResult = @{
        Rows = $Rows
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetHeaderRowMaxLength" -Value {
        $iHeaderRowMaxLength = 0
        foreach ($oRow in $this.Rows) {
            if ($oRow.Type -in @("row", "textbox", "property")) {
                if ($iHeaderRowMaxLength -lt $oRow.Header.Length) {
                    $iHeaderRowMaxLength = $oRow.Header.Length
                }
            }
        }
        return $iHeaderRowMaxLength
    }

    $hAllButtons = @{}
    $hObjectsWithValue = [ordered]@{}
    foreach ($oRow in $Rows) {
        if ($oRow.Type -in @("button", "checkbox")) {
            if ($oRow.Keyboard) {
                $hAllButtons.$($oRow.Keyboard.ToString()) = $oRow
            }
            if ($oRow.Type -eq "checkbox") {
                $hObjectsWithValue.($oRow.Name) = $oRow
            }
        } elseif ($oRow.Type -in @("row", "textbox", "property")) {
            if ($oRow.Type -eq "row") {
                if ($oRow.IsRadioButtonRow()) {
                    $hObjectsWithValue.($oRow.Name) = $oRow
                }
                foreach ($item in ($oRow.RowContent | Where-Object { $_.Type -in @("button", "checkbox", "radiobutton") })) {
                    if ($item.Keyboard) {
                        $hAllButtons.$($item.Keyboard.ToString()) = $item
                    }
                    if ($item.Type -in @("checkbox", "radiobutton")) {
                        $hObjectsWithValue.($item.Name) = $item
                    }
                }
            }
            if ($oRow.Type -eq "textbox") {
                $hObjectsWithValue.($oRow.Name) = $oRow
            }
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "SetSeparatorLocation" -Value {
        $iHeaderRowMaxLength = $this.GetHeaderRowMaxLength()
        $aFilteredRows = ($this.Rows | Where-Object {$_.Type -in @("row", "textbox", "property")})
        foreach ($oRow in $aFilteredRows) {
            $oRow.SeparatorLocation = $iHeaderRowMaxLength
        }
    }

    $hResult.SetSeparatorLocation()
    
    foreach ($item in $HiddenButtons) {
        if (($item.Type -eq "button") -and ($item.Keyboard)) {
            $hAllButtons.$($item.Keyboard.ToString()) = $item
        }
    }

    $hResult.StaticRows = $aStaticRows
    $hResult.DynamicRows = $aDynamicRows
    $hResult.EscapeObject = $oEscapeObject
    $hResult.ObjectsIndex = $aObjectIndex
    $hResult.ValidateObject = $oValidateObject
    $hResult.RefreshObject = $oRefreshObject
    $hResult.FocusedRow = $FocusedRow
    $hResult.AllButtons = $hAllButtons
    $hResult.PauseAfterErrorMessage = $PauseAfterErrorMessage
    $hResult.ValidationErrorDetails = $ValidationErrorDetails
    $hResult.AllObjectsWithValues = $hObjectsWithValue
    $hResult.SelectedObjectsArray = $SelectedObjectsArray
    $hResult.SelectedObjectsUniqueProperty = $SelectedObjectsUniqueProperty
    
    $hResult | Add-Member -MemberType ScriptMethod -Name "Draw" -Value {
        $bDrawUnderline = $this.Rows[$this.ObjectsIndex[$this.FocusedRow]].Type -ne "textbox"
        for ($i = 0; $i -lt $this.Rows.Count; $i++) {
            if ($this.ObjectsIndex.IndexOf($i) -eq $this.FocusedRow) {
                $this.Rows[$i].DrawFocused()
            } else {
                if ($this.Rows[$i].Type -eq "separator") {
                    $this.Rows[$i].Draw($this.GetTextWidth())
                } else {
                    $this.Rows[$i].Draw($bDrawUnderline)    
                }
            }
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "DrawStatic" -Value {
        $iFormWidth = $this.GetTextWidth()
        for ($i = 0; $i -lt $this.StaticRows.Count; $i++) {
            if ($this.StaticRows[$i].Type -eq "separator") {
                $this.StaticRows[$i].Draw($iFormWidth)
            } else {
                $this.StaticRows[$i].Draw()
            }
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "DrawDynamic" -Value {
        $iFormWidth = $this.GetTextWidth()
        $bDrawUnderline = $this.Rows[$this.ObjectsIndex[$this.FocusedRow]].Type -ne "textbox"
        for ($i = 0; $i -lt $this.DynamicRows.Count; $i++) {
            $j = $i + $this.StaticRows.Count
            if ($this.ObjectsIndex.IndexOf($j) -eq $this.FocusedRow) {
                $this.DynamicRows[$i].DrawFocused()
            } else {
                if ($this.DynamicRows[$i].Type -eq "separator") {
                    $this.DynamicRows[$i].Draw($iFormWidth)
                } else {
                    $this.DynamicRows[$i].Draw($bDrawUnderline)    
                }
            }
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetTextWidth" -Value {
        $iResult = 0
        for ($i = 0; $i -lt $this.Rows.Count; $i++) {
            #if ($this.Rows[$i].Type -ne "separator") {
                $oRow = $this.Rows[$i]
                $iObjectWidth = $oRow.GetTextWidth()
                if ($iObjectWidth -gt $iResult) {
                    $iResult = $iObjectWidth
                }
            #}
        }
        return $iResult
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressUp" -Value {
        Param(
            [System.ConsoleKeyInfo]$KeyInfo,
            [object]$Options
        )
        if ($this.FocusedRow -gt 0) {
            $oRowBefore = $this.Rows[$this.ObjectsIndex[$this.FocusedRow]]
            $this.FocusedRow--
            $oRow = $this.Rows[$this.ObjectsIndex[$this.FocusedRow]]
            if (($oRow.type -eq "textbox") -and ($null -ne $Options)) {
                $oRow.SetCursorPosition($Options)
            }
            if (($oRowBefore.type -eq "row") -and ($oRow.type -eq "row")) {
                $oRowBeforeObjTypes = $oRowBefore.RowContent.type | Select-Object -Unique
                $oRowObjTypes = $oRow.RowContent.type | Select-Object -Unique
                if (($oRowBeforeObjTypes.Count -eq 1) -and ($oRowObjTypes.Count -eq 1) -and ($oRowBeforeObjTypes = "button") -and ($oRowObjTypes = "button")) {
                    if ($oRowBefore.FocusedItem -eq 0) {
                        $oRow.FocusedItem = 0
                    } else {
                        $iButtonBeforeStart = 0
                        for ($i = 0; $i -lt $oRowBefore.FocusedItem; $i++) {
                            $iButtonBeforeStart += $oRowBefore.RowContent[$i].GetTextWidth()
                        }
                        $iButtonBeforeEnd = $iButtonBeforeStart + $oRowBefore.RowContent[$oRowBefore.FocusedItem].GetTextWidth() - 1
                        $iButtonBeforeMiddle = $iButtonBeforeStart + [System.Math]::Floor(($iButtonBeforeEnd - $iButtonBeforeStart) / 2)

                        $iRowButtonIndexesLength = ($oRow.RowContent | ForEach-Object { $_.GetTextWidth() } | Measure-Object -Sum).Sum

                        if ($iButtonBeforeMiddle -gt $iRowButtonIndexesLength) {
                            $oRow.FocusedItem = $oRow.RowContent.Count - 1
                        } else {
                            $aRowButtonIndexes = [int[]]::new($iRowButtonIndexesLength)
                            $i = 0
                            for ($j = 0; $j -lt $oRow.RowContent.Count ; $j++) {
                                $iButtonLength = $oRow.RowContent[$j].GetTextWidth()
                                for ($k = 0; $k -lt $iButtonLength ; $k++) {
                                    $aRowButtonIndexes[$i] = $j
                                    $i++
                                }
                            }    
                            $oRow.FocusedItem = $aRowButtonIndexes[$iButtonBeforeMiddle]
                        }
                    }
                }
            }
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressDown" -Value {
        Param(
            [System.ConsoleKeyInfo]$KeyInfo,
            [object]$Options
        )
        if ($this.FocusedRow -lt $this.ObjectsIndex.Count - 1) {
            $oRowBefore = $this.Rows[$this.ObjectsIndex[$this.FocusedRow]]
            $this.FocusedRow++
            $oRow = $this.Rows[$this.ObjectsIndex[$this.FocusedRow]]
            if (($oRow.type -eq "textbox") -and ($null -ne $Options)) {
                $oRow.SetCursorPosition($Options)
            }
            if (($oRowBefore.type -eq "row") -and ($oRow.type -eq "row")) {
                $oRowBeforeObjTypes = $oRowBefore.RowContent.type | Select-Object -Unique
                $oRowObjTypes = $oRow.RowContent.type | Select-Object -Unique
                if (($oRowBeforeObjTypes.Count -eq 1) -and ($oRowObjTypes.Count -eq 1) -and ($oRowBeforeObjTypes = "button") -and ($oRowObjTypes = "button")) {
                    if ($oRowBefore.FocusedItem -eq 0) {
                        $oRow.FocusedItem = 0
                    } else {
                        $iButtonBeforeStart = 0
                        for ($i = 0; $i -lt $oRowBefore.FocusedItem; $i++) {
                            $iButtonBeforeStart += $oRowBefore.RowContent[$i].GetTextWidth()
                        }
                        $iButtonBeforeEnd = $iButtonBeforeStart + $oRowBefore.RowContent[$oRowBefore.FocusedItem].GetTextWidth() - 1
                        $iButtonBeforeMiddle = $iButtonBeforeStart + [System.Math]::Floor(($iButtonBeforeEnd - $iButtonBeforeStart) / 2)

                        $iRowButtonIndexesLength = ($oRow.RowContent | ForEach-Object { $_.GetTextWidth() } | Measure-Object -Sum).Sum

                        if ($iButtonBeforeMiddle -gt $iRowButtonIndexesLength) {
                            $oRow.FocusedItem = $oRow.RowContent.Count - 1
                        } else {
                            $aRowButtonIndexes = [int[]]::new($iRowButtonIndexesLength)
                            $i = 0
                            for ($j = 0; $j -lt $oRow.RowContent.Count ; $j++) {
                                $iButtonLength = $oRow.RowContent[$j].GetTextWidth()
                                for ($k = 0; $k -lt $iButtonLength ; $k++) {
                                    $aRowButtonIndexes[$i] = $j
                                    $i++
                                }
                            }    
                            $oRow.FocusedItem = $aRowButtonIndexes[$iButtonBeforeMiddle]
                        }
                    }
                }
            }
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressTab" -Value {
        Param(
            [System.ConsoleKeyInfo]$KeyInfo
        )
        if ($KeyInfo.Modifiers -eq [System.ConsoleModifiers]::Shift) {
            if ($this.FocusedRow -gt 0) {
                $this.FocusedRow--
                $oNewRow = $this.Rows[$this.ObjectsIndex[$this.FocusedRow]]
                $oNewRow.FocusedItem = $oNewRow.ObjectsIndex.Count - 1
            } else {
                $this.FocusedRow = $this.ObjectsIndex.Count - 1
                $oRow = $this.Rows[$this.ObjectsIndex[$this.FocusedRow]]
                if ($oRow.Type -eq "row") {
                    $oRow.FocusedItem = $oRow.RowContent.Count - 1
                }
            }                            
        } else {
            if ($this.FocusedRow -lt $this.ObjectsIndex.Count - 1) {
                $this.FocusedRow++
                $oNewRow = $this.Rows[$this.ObjectsIndex[$this.FocusedRow]]
                $oNewRow.FocusedItem = 0
            } else {
                $this.FocusedRow = 0
                $oRow = $this.Rows[$this.ObjectsIndex[$this.FocusedRow]]
                if ($oRow.Type -eq "row") {
                    $oRow.FocusedItem = 0
                }
            }
        }    
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressEscape" -Value {
        Param(
            [System.ConsoleKeyInfo]$KeyInfo
        )
        if ($this.EscapeObject) {
            return $this.EscapeObject
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressEnter" -Value {
        Param(
            [System.ConsoleKeyInfo]$KeyInfo
        )
        $oPressKeyResult = $this.Rows[$this.ObjectsIndex[$this.FocusedRow]].PressKey($KeyInfo)
        if ($oPressKeyResult -is [System.ConsoleKeyInfo]) {
            $oRow = $this.Rows[$this.ObjectsIndex[$this.FocusedRow]]
            if ($oRow.Type -eq "row") {
                $oFocusedObject = $oRow.RowContent[$oRow.ObjectsIndex[$oRow.FocusedItem]]
                if ($oFocusedObject.Type -eq "button") {
                    return $oFocusedObject
                } else {
                    if ($this.ValidateObject) {
                        return $this.ValidateObject
                    }
                }
            } else {
                if ($this.ValidateObject) {
                    return $this.ValidateObject
                }
            }
        } else {
            return $oPressKeyResult
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressSpace" -Value {
        Param(
            [System.ConsoleKeyInfo]$KeyInfo
        )
        $oRow = $this.Rows[$this.ObjectsIndex[$this.FocusedRow]]
        if (($oRow.Type -eq "checkbox") -and ($oRow.Object)) {
            if ($this.SelectedObjectsArray) {
                $SelectedObjectsUniqueProperty = $this.SelectedObjectsUniqueProperty
                if ($oRow.Enabled) {
                    # checkbox enabled and object not in array
                    if ($oRow.Object.$SelectedObjectsUniqueProperty -notin $this.SelectedObjectsArray.Value.$SelectedObjectsUniqueProperty) {
                        if ($null -eq $this.SelectedObjectsArray.Value) {
                            $this.SelectedObjectsArray.Value = @()
                        }
                        if ($this.SelectedObjectsArray.Value -is [array]) {
                            $this.SelectedObjectsArray.Value += $oRow.Object
                        } else {
                            $this.SelectedObjectsArray.Value = @($this.SelectedObjectsArray.Value) + $oRow.Object
                        }
                    }    
                } else {
                    # checkbox disabled and object in array
                    if ($oRow.Object.$SelectedObjectsUniqueProperty -in $this.SelectedObjectsArray.Value.$SelectedObjectsUniqueProperty) {
                        $this.SelectedObjectsArray.Value = $this.SelectedObjectsArray.Value | Where-Object { $_.$SelectedObjectsUniqueProperty -ne $oRow.Object.$SelectedObjectsUniqueProperty }
                        if ($null -eq $this.SelectedObjectsArray.Value) {
                            $this.SelectedObjectsArray.Value = @()
                        }
                    }
                }
            }
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressKey" -Value {
        Param(
            [System.ConsoleKeyInfo]$KeyInfo
        )
        $oPressKeyResult = $this.Rows[$this.ObjectsIndex[$this.FocusedRow]].PressKey($KeyInfo)
        $oPressedKey, $oOptions = if ($oPressKeyResult -is [System.ConsoleKeyInfo]) {
            $oPressKeyResult, $null
        } else {
            $oPressKeyResult.Key, $oPressKeyResult.Options
        }
        $oButtonResult = $null
        if ($oPressedKey -is [System.ConsoleKeyInfo]) {
            if ([System.Char]::IsControl($KeyInfo.KeyChar)) {
                switch ($oPressedKey.Key) {
                    ([System.ConsoleKey]::UpArrow) { $this.PressUp($oPressedKey, $oOptions) }
                    ([System.ConsoleKey]::DownArrow) { $this.PressDown($oPressedKey, $oOptions) }
                    ([System.ConsoleKey]::Tab) { $this.PressTab($oPressedKey) }
                    ([System.ConsoleKey]::Escape) { $oButtonResult = $this.PressEscape($oPressedKey) }
                    ([System.ConsoleKey]::Enter) { $oButtonResult = $this.PressEnter($oPressedKey) }
                    ([System.ConsoleKey]::F5) {
                        if ($this.RefreshObject) {
                            $oButtonResult = $this.RefreshObject
                        } else {
                            if ($oPressedKey.Key.ToString() -in $this.AllButtons.Keys) {
                                $oButtonResult = $this.AllButtons[$oPressedKey.Key.ToString()]
                            }
                        }
                    }
                    default {
                        if ($oPressedKey.Key.ToString() -in $this.AllButtons.Keys) {
                            $oButtonResult = $this.AllButtons[$oPressedKey.Key.ToString()]
                        }
                    }
                }
            } else {
                switch ($oPressedKey.Key) {
                    ([System.ConsoleKey]::Spacebar) { $this.PressSpace($oPressedKey) }
                    default {
                        # $press.Character is a real character, not a control character
                        if ($oPressedKey.Key.ToString() -in $this.AllButtons.Keys) {
                            $oObject = $this.AllButtons[$oPressedKey.Key.ToString()]
                            if ($oObject.Type -in @("checkbox", "radiobutton")) {
                                $oObject.ToggleValue()
                            } else {
                                $oButtonResult = $oObject
                            }
                        }
                    }
                }
            }    
        } else {
            $oButtonResult = $oPressKeyResult
        }
        return $oButtonResult
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "IsValidForm" -Value {
        $bResult = $true
        foreach ($item in $this.Rows) {
            if ($item.Type -eq "textbox") {
                $bResult = $bResult -and ($item.IsValidText())
            }
        }
        return $bResult
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetErrors" -Value {
        $hErrors = [ordered]@{}
        foreach ($item in $this.Rows) {
            if (($item.Type -eq "textbox") -and (-not $item.IsValidText())) {
                $sFieldName = if ($item.FieldNameInErrorReason) {
                    $item.FieldNameInErrorReason
                } else {
                    $item.Header
                }
                $sReason = if ($item.ValidationErrorReason) {
                    $item.ValidationErrorReason
                } else {
                    "must match the following regex $($item.Regex)"
                }
                $hErrors.Add($sFieldName, $sReason)
            }
        }
        return $hErrors
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "WriteErrorMessage" -Value {
        Param(
            [string]$PropertyAlign = "Right",
            [string]$OneFieldErrorMessage = "Error: The following field has an invalid value.",
            [string]$SeveralFieldsErrorMessage = "Error: Somes fields have invalid values."
        )
        if ($this.IsValidForm()) {
            $this.RemoveKey("Errors")
        } else {
            $hErrors = [ordered]@{}
            $iMaxLength = 0
            foreach ($item in $this.Rows) {
                if (($item.Type -eq "textbox") -and (-not $item.IsValidText())) {
                    if ($item.Header.Length -gt $iMaxLength) { $iMaxLength = $item.Header.Length }
                    $sFieldName = if ($item.FieldNameInErrorReason) {
                        $item.FieldNameInErrorReason
                    } else {
                        $item.Header
                    }
                    $sReason = if ($item.ValidationErrorReason) {
                        $item.ValidationErrorReason
                    } else {
                        "must match the following regex $($item.Regex)"
                    }
                    $hErrors.Add($sFieldName, $sReason)
                }
            }
            if ($this.ValidationErrorMessage) {
                Write-Host $this.ValidationErrorMessage -ForegroundColor Red
            } else {
                if ($hErrors.Keys.Count -gt 1) {
                    Write-Host $SeveralFieldsErrorMessage -ForegroundColor Red
                } else {
                    Write-Host $OneFieldErrorMessage -ForegroundColor Red
                }    
            }
            if ($this.ValidationErrorDetails) {
                foreach ($item in $hErrors.Keys) {
                    $iAlign = if ($PropertyAlign -eq "Left") { -1 } else { 1 }
                    Write-Host ("{0,$($iMaxLength * $iAlign)} " -f $item) -ForegroundColor Red -NoNewline
                    Write-Host $hErrors[$item]
                }    
            }
            $this.Errors = $hErrors
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "Invoke" -Value {
        Param(
            [bool]$KeepValues
        )
        if (-not $KeepValues) {
            $this.Reset()
        }
        return $this._Invoke()
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "InvokeValidate" -Value {
        Param(
            [bool]$KeepValues
        )
        if (-not $KeepValues) {
            $this.Reset()
        }
        $oResult = $this._Invoke()
        while (-not $this.IsValidForm()) {
            $this.WriteErrorMessage()
            if ($this.PauseAfterErrorMessage) {
                Invoke-Pause -ReplaceByLine
            }
            $oResult = $this._Invoke()
        }
        return $oResult
    }
    
    $hResult | Add-Member -MemberType ScriptMethod -Name "_Invoke" -Value {
        $iFormHeight = $this.GetTextHeight($true)
        $oResult = $null
        $this.DrawStatic()
        try {
			[console]::CursorVisible=$false #prevents cursor flickering
			$this.DrawDynamic()
            While ($oResult -eq $null) {
				$Key = [Console]::ReadKey($true)
                $oResult = $this.PressKey($Key)
				
                $startPos = [System.Console]::CursorTop - $iFormHeight
                [System.Console]::SetCursorPosition(0, $startPos)
                $this.DrawDynamic()
			}
		}
		finally {
			[System.Console]::SetCursorPosition(0, $startPos + $iFormHeight) | Out-Null
			[System.Console]::CursorVisible = $true
		}
        if ($oResult -ne $null) {
            $hResult = @{
                Button = $oButtonResult
                Form = $this
                Type = $oButtonResult.ButtonType
                ValidForm = $this.IsValidForm()
            }
            switch ($hResult.Type) {
                { $_ -in @("Action", "Action_Scriptblock") } {
                    return New-DialogResultAction -Action $oButtonResult.Action -DialogResult $hResult -Value $oButtonResult.Object 
                }
                "Scriptblock" {
                    return New-DialogResultScriptblock -Action $oButtonResult.Action -DialogResult $hResult -Value $oButtonResult.Object
                }
                "Value" {
                    return New-DialogResultValue -Action $oButtonResult.Action -DialogResult $hResult -Value $oButtonResult.Object -SelectedProperties $oButtonResult.ObjectSelectedProperties
                }
            }
            return $hResult
        }
    }
    
    $hResult | Add-Member -MemberType ScriptMethod -Name "GetTextHeight" -Value {
        Param(
            [bool]$Dynamic = $false
        )
        $aRows = if ($Dynamic) {
            $this.DynamicRows
        } else {
            $this.Rows
        }
        $iResult = 0
        foreach ($item in $aRows) {
            $iResult += $item.GetTextHeight()
        }
        return $iResult
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "Reset" -Value {
        foreach ($item in $this.Rows) {
            if ("Reset" -in $item.PSObject.Members.Name) {
                $item.Reset()
            }
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetValue" -Value {
        Param(
            [bool]$UseName = $false
        )
        $hResult = [ordered]@{}
        foreach ($itemKey in $this.AllObjectsWithValues.Keys) {
            $item = $this.AllObjectsWithValues[$itemKey]
            if ($item.Type -eq "textbox") {
                $hResult.Add($(if ($UseName) { $item.Name } else { $item.Header}), $item.GetValue())
            }
            if ($item.Type -eq "checkbox") {
                $hResult.Add($(if ($UseName) { $item.Name } else { $item.GetText() } ), $item.GetValue())
            }
            if ($item.Type -eq "row") {
                $hResult.Add($(if ($UseName) { $item.Name } else { $item.GetText() } ), $item.GetValue())
            }
        }
        return $hResult
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetFocusedItem" -Value {
        return $this.Rows[$this.ObjectsIndex[$this.FocusedRow]]
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetCheckedObjects" -Value {
        return $this.Rows[$this.ObjectsIndex[$this.FocusedRow]]
    }
    
    return $hResult
}
