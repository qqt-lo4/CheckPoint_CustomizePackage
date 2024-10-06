function Invoke-CLIDialog {
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject,
        [switch]$KeepValues,
        [switch]$Validate,
        [switch]$ErrorDetails,
        [switch]$PauseAfterErrorMessage,
        [string]$CustomErrorMessage = "",
        [string]$ErrorMessageOneField = "Error: The following field has an invalid value.",
        [string]$ErrorMessageFields = "Error: Somes fields have invalid values.",
        [ValidateSet("Right", "Left")]
        [string]$ErrorsPropertiesAlign = "Right",
        [switch]$Execute,
        [System.Management.Automation.FunctionInfo]$FunctionToRunOnValue,
        [switch]$DontSpaceAfterDialog
    )
    Begin {
        function Show {
            Param(
                [Parameter(Mandatory)]
                [object]$Dialog,
                [switch]$DontSpaceAfterDialog
            )
            $iFormHeight = $Dialog.GetTextHeight($true)
            $Dialog.SetSeparatorLocation()
            $oResult = $null
            $Dialog.DrawStatic()
            try {
                [console]::CursorVisible=$false #prevents cursor flickering
                $Dialog.DrawDynamic()
                While ($oResult -eq $null) {
                    $Key = [Console]::ReadKey($true)
                    $oResult = $Dialog.PressKey($Key)
                    
                    $startPos = [System.Console]::CursorTop - $iFormHeight
                    [System.Console]::SetCursorPosition(0, $startPos)
                    $Dialog.DrawDynamic()
                }
            } finally {
                [System.Console]::SetCursorPosition(0, $startPos + $iFormHeight) | Out-Null
                [System.Console]::CursorVisible = $true
            }
            if (-not $DontSpaceAfterDialog) {
                Write-Host ""
            }
            if ($oResult -ne $null) {
                $hResult = @{
                    Button = $oResult
                    Form = $Dialog
                    Type = $oResult.ButtonType
                    ValidForm = $Dialog.IsValidForm()
                }
                switch ($hResult.Type) {
                    { $_ -in @("Action", "Action_Scriptblock") } {
                        return New-DialogResultAction -Action $oResult.Action -DialogResult $hResult -Value $oResult.Object 
                    }
                    "Scriptblock" {
                        return New-DialogResultScriptblock -DialogResult $hResult -Value $oResult.Object
                    }
                    "Value" {
                        if ($oResult.Object) {
                            return New-DialogResultValue -DialogResult $hResult -Value $oResult.Object -SelectedProperties $oResult.ObjectSelectedProperties
                        } else {
                            return New-DialogResultValue -DialogResult $hResult -Value $hResult.Button -SelectedProperties $oResult.ObjectSelectedProperties
                        }
                    }
                }
            }
        }

        function Write-ErrorMessage {
            Param(
                [Parameter(Mandatory, ValueFromPipeline)]
                [object]$Dialog,
                [string]$PropertyAlign = "Right",
                [AllowEmptyString()]
                [string]$CustomErrorMessage,
                [string]$ErrorMessageOneField = "Error: The following field has an invalid value.",
                [string]$ErrorMessageFields = "Error: Somes fields have invalid values.",
                [switch]$Details
            )
            if ($Dialog.IsValidForm()) {
                $Dialog.RemoveKey("Errors")
            } else {
                $hErrors = [ordered]@{}
                $iMaxLength = 0
                foreach ($item in $Dialog.Rows) {
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
                if ($CustomErrorMessage) {
                    Write-Host $CustomErrorMessage -ForegroundColor Red
                } else {
                    if ($hErrors.Keys.Count -gt 1) {
                        Write-Host $ErrorMessageFields -ForegroundColor Red
                    } else {
                        Write-Host $ErrorMessageOneField -ForegroundColor Red
                    }    
                }
                if ($Details) {
                    foreach ($item in $hErrors.Keys) {
                        $iAlign = if ($PropertyAlign -eq "Left") { -1 } else { 1 }
                        Write-Host ("{0,$($iMaxLength * $iAlign)} " -f $item) -ForegroundColor Red -NoNewline
                        Write-Host $hErrors[$item]
                    }    
                }
                $Dialog.Errors = $hErrors
            }
        }
        function Invoke {
            Param(
                [Parameter(Mandatory)]
                [object]$Dialog,
                [switch]$Validate,
                [switch]$DontSpaceAfterDialog
            )
            if ($Validate) {
                $oResult = Show -Dialog $Dialog -DontSpaceAfterDialog:$DontSpaceAfterDialog
                while ((-not $Dialog.IsValidForm()) -and ($oResult.Action -ne "Cancel") -and ($oResult.Action -ne "Exit")) {
                    Write-ErrorMessage -Dialog $Dialog -Details:$ErrorDetails -CustomErrorMessage $CustomErrorMessage
                    if ($PauseAfterErrorMessage) {
                        Invoke-Pause -ReplaceByLine -LineColor Red -MessageColor White
                    }
                    $oResult = Show -Dialog $Dialog
                }
                return $oResult
            } else {
                return Show -Dialog $Dialog
            }
        }

        function Execute {
            Param(
                [Parameter(Mandatory, Position = 0)]
                [object]$Dialog,
                [switch]$Validate,
                [switch]$DontSpaceAfterDialog
            )
            
            while ($true) {
                $oDialogResult = Invoke -Dialog $Dialog -Validate:$Validate -DontSpaceAfterDialog:$DontSpaceAfterDialog
                switch -Wildcard ($oDialogResult.PSTypeNames[0]) {
                    "DialogResult.Action.Cancel" {
                        return $oDialogResult
                    }
                    "DialogResult.Action.Back" {
                        return $oDialogResult
                    }
                    "DialogResult.Action.Refresh" {
                        return $oDialogResult
                    }
                    "DialogResult.Scriptblock" {
                        $icr = Invoke-Command $oDialogResult.Value -ArgumentList $oObject
                        return $icr
                    }
                    "DialogResult.Action.*" {
                        return $oDialogResult
                    }
                    "DialogResult.Value" {
                        if ($FunctionToRunOnValue) {
                            $oValueDialogResult = . $FunctionToRunOnValue $oDialogResult.Value
                            switch -Wildcard ($oValueDialogResult.PSTypeNames[0]) {
                                "DialogResult.Action.Exit" {
                                    return $oValueDialogResult
                                }
                                "DialogResult.Action.Back" {
                                    return $oValueDialogResult
                                }
                                "DialogResult.Action.Refresh" {
                                    return $oValueDialogResult
                                }
                                "DialogResult.Action.*" {
                                    throw "Unmanaged action type"
                                }
                            }    
                        } else {
                            return $oDialogResult
                        }
                    }
                }
            }
        }
        $oDialog = if ($InputObject -is [array]) {
            New-CLIDialog -Rows $InputObject
        } else {
            $InputObject
        }
    }
    Process {
        if (-not $KeepValues) {
            $oDialog.Reset()
        }
        if ($Execute) {
            Execute -Dialog $oDialog -Validate:$Validate -DontSpaceAfterDialog:$DontSpaceAfterDialog 
        } else {
            Invoke -Dialog $oDialog -Validate:$Validate -DontSpaceAfterDialog:$DontSpaceAfterDialog
        }
    }
}
