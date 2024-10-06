function Select-CLIObjectInArray {
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [array]$Objects,
        [object[]]$SelectedColumns,
        [object[]]$Sort,
        [string]$SelectHeaderMessage = "Please select an item:",
        [System.ConsoleColor]$HeaderColor = (Get-Host).UI.RawUI.ForegroundColor,
        [AllowNull()]
        [string]$FooterMessage = "Please type item number",
        [System.ConsoleColor]$FooterColor = (Get-Host).UI.RawUI.ForegroundColor,
        [AllowEmptyString()]
        [string]$EmptyArrayMessage = "No items in array",
        [object[]]$OtherMenuItems,
        [switch]$AutoSelectWhenOneItem,
        [switch]$ShowOnlyOnePage,
        [switch]$NoEmptyLineAfterItems,
        [ValidateScript({$_ -ge 1})]
        [int]$ItemsPerPage = 10,
        [System.ConsoleColor]$SeparatorColor = (Get-Host).UI.RawUI.ForegroundColor,
        [switch]$HeaderTextInSeparator
    )
    Begin {
        function Format-CustomTable {
            Param(
                [Parameter(Position = 0)]
                [object[]]$Property,
                [Parameter(ValueFromPipeline)]
                [object[]]$InputObject,
                [switch]$HideTableHeaders
            )
            Begin {
                $aItems = @()
            }
            Process {
                $aItems += $InputObject
            }
            End {
                $hSettings = @{
                    HideTableHeaders = $HideTableHeaders.IsPresent
                }
                if ($Property) {
                    $hSettings.Property = $Property
                }
                $result = $aItems | Format-Table @hSettings | Out-String
                $aResult = ($result.Split("`r`n") | Where-Object { $_.Trim() -ne "" })
                return $aResult
            }
        }

        function New-CLIObjectListPage {
            Param(
                [AllowNull()]
                [object[]]$Objects,
                [int]$PageNumber,
                [int]$PageCount,
                [int]$ItemsPerPage,
                [object[]]$OtherMenuItems,
                [object[]]$SelectedColumns,
                [System.ConsoleColor]$SeparatorColor = (Get-Host).UI.RawUI.ForegroundColor,
                [switch]$MultiSelect
            )
            $aCLIObject = @()
            # Header
            if ($SelectHeaderMessage) {
                if ($HeaderTextInSeparator) {
                    $aCLIObject += New-CLIDialogSeparator -Text $SelectHeaderMessage -ForegroundColor $SeparatorColor -AutoLength
                } else {
                    $aCLIObject += New-CLIDialogText -Text $SelectHeaderMessage -ForegroundColor $HeaderColor -AddNewLine
                }
            }
            # Content
            if ($Objects) {
                $aCLIObject += New-CLIDialogTableItems -Objects $Objects -Properties $SelectedColumns -Checkbox:$MultiSelect
            } else {
                $aCLIObject += New-CLIDialogText -Text $EmptyArrayMessage -ForegroundColor Yellow -AddNewLine
            }
            # Separator
            if ($Objects) {
                $aCLIObject += New-CLIDialogSeparator -AutoLength -DrawArrows -DrawPageNumber -PageNumber $PageNumber -PageCount $PageCount -ForegroundColor $SeparatorColor
            } else {
                $aCLIObject += New-CLIDialogSeparator -AutoLength -ForegroundColor $SeparatorColor
            }
            # Prepare navigation buttons
            $aHiddenButtons = @()
            if ($PageCount -gt 1) {
                $aNavigationButtons = @()
                if ($PageNumber -ne 0) {
                    $aNavigationButtons += New-CLIDialogButton -Text "&Previous page" -Keyboard P -Previous
                    $aHiddenButtons += New-CLIDialogButton -Text "Previous page" -Keyboard PageUp -Previous
                }
                $aNavigationButtons += New-CLIDialogButton -Text "&Go to page" -Keyboard G -GoTo
                if ($PageNumber -ne ($PageCount - 1)) {
                    $aNavigationButtons += New-CLIDialogButton -Text "&Next page" -Keyboard N -Next
                    $aHiddenButtons += New-CLIDialogButton -Text "Next page" -Keyboard PageDown -Next
                }
                $aCLIObject += New-CLIDialogObjectsRow -Row $aNavigationButtons -Header "Navigate to" -HeaderSeparator " : "
            }
            # Add Other menu items
            if ($OtherMenuItems) {
                $aOtherMenuItems = @()
                foreach ($item in $OtherMenuItems) {
                    if ($item.Type -like "menu*") {
                        $item.AddNewLine = $true
                        $aOtherMenuItems += $item.ConvertToDialog()
                    } else {
                        $aOtherMenuItems += $item
                    }
                }
                $aCLIObject += $aOtherMenuItems #New-CLIDialogObjectsRow -Row $aOtherMenuItems -Header "Go to" -HeaderSeparator " : "
            }
            if ($FooterMessage) {
                $aCLIObject += New-CLIDialogText -Text $FooterMessage -ForegroundColor $FooterColor -AddNewLine
            }
            $oDialog = New-CLIDialog -Rows $aCLIObject -HiddenButtons $aHiddenButtons
            $oDialogResult = Invoke-CLIDialog -InputObject $oDialog
            #$oDialogResultType = $oDialogResult.PSTypeNames[0]
            return $oDialogResult
        }

        function Convert-OnlyItem {
            Param(
                [object]$Object,
                [object]$SelectedColumns
            )      
            $aSelectedColumnObjects = if ($SelectedColumns) {
                $Object | Select-Object -Property $SelectedColumns
            } else {
                $Object
            }
            $aSelectedColumnObjectsToString = $aSelectedColumnObjects | Format-CustomTable
            $oButtonResult = New-CLIDialogButton -Text $aSelectedColumnObjectsToString[2] -Object $Objects -ObjectSelectedProperties $aSelectedColumnObjects -AddNewLine

            $hResult = @{
                Button = $oButtonResult
                Form = $this
                Type = "Value"
                Object = $Object
                ObjectSelectedProperties = $aSelectedColumnObjects
            }
            
            return $hResult
        }

        $aObjects = @()
    }
    Process {
        foreach ($o in $Objects) {
            $aObjects += $o
        }
    }
    End {
        #if ($aObjects) {
            $iPageNumber = 0
            $iPageCount = [Math]::Floor(($aObjects.Count -1) / $ItemsPerPage) + 1
            if ($Sort) {
                $aObjects = $aObjects | Sort-Object -Property $Sort
            }
            $aObjects = @() + $aObjects
            if (($aObjects.Count -eq 1) -and ($AutoSelectWhenOneItem -eq $true)) {
                $oDialogValue = Convert-OnlyItem $aObjects[0] -SelectedColumns $SelectedColumns
                return New-DialogResultValue -Value $oDialogValue.Object
            }
            $oResult = $null
            while ($true) {
                $aPage = if ($aObjects) {Get-ArrayPage -Objects $aObjects -Page $iPageNumber -ItemsPerPage $ItemsPerPage} else { $null }
                $oResult = New-CLIObjectListPage -Objects $aPage -PageNumber $iPageNumber -PageCount $iPageCount -ItemsPerPage $ItemsPerPage -OtherMenuItems $OtherMenuItems -SelectedColumns $SelectedColumns -SeparatorColor $SeparatorColor
                switch ($oResult.PSTypeNames[0]) {
                    "DialogResult.Action.Back" {
                        return $oResult
                    }
                    "DialogResult.Action.Exit" {
                        return $oResult
                    }
                    "DialogResult.Action.Previous" {
                        if ($iPageNumber -gt 0) {
                            $iPageNumber--
                        }
                    }
                    "DialogResult.Action.Next" {
                        if ($iPageNumber -lt ($iPageCount - 1)) {
                            $iPageNumber++
                        }
                    }
                    "DialogResult.Action.GoTo" {
                        $iPageNumber = (Read-NumericValue -header "Go to page number" -min 1 -max $iPageCount -errorMessage "Page number invalid") - 1
                    }
                    "DialogResult.Action.Other" {
                        if ($oResult.Value -is [scriptblock]) {
                            $oScriptResult = . $oResult.Value
                            Return New-DialogResultAction -Action "Other" -Value $oScriptResult
                        }
                    }
                    "DialogResult.Value" {
                        return $oResult
                    }
                }
            }
            return $oResult    
        # } else {
        #     if ($EmptyArrayMessage -ne "") {
        #         if ($AllowOtherFile) {
        #             $aDialogRows = @(
        #                 New-CLIDialogSeparator -Text $SelectHeaderMessage -ForegroundColor $SeparatorColor
        #                 New-CLIDialogText -Text $EmptyArrayMessage -ForegroundColor Yellow
        #                 New-CLIDialogSeparator -ForegroundColor $SeparatorColor

        #             )
                    
        #         } else {
        #             Write-Host $EmptyArrayMessage -ForegroundColor Yellow
        #         }
        #     }
        # }
    }
}
