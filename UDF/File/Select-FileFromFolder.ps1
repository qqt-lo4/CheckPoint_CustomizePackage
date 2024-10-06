function Select-FileFromFolder {
    Param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string[]]$Filter,
        [switch]$ShowFile,
        [switch]$AllowOtherFile,
        [char]$OtherFileMenuNumber = "o",
        [string]$OtherFileMenuItemText = "Select another file",
        [string]$OtherFilePromptText = "Please enter a file path",
        [switch]$AllowNoFile,
        [char]$NoFileItemNumber = "n",
        [string]$NoFileMenuItemText = "Do not select a file",
        [switch]$AllowExit,
        [char]$ExitMenuItemNumber = "e",
        [string]$ExitMenuItemText = "Exit this menu",
        [string]$SelectHeaderMessage = "Please select an item:",
        [string]$FooterMessage = "Please type item number"
    )
    # Build menu items
    $aItems = if ($Filter) {
        if ($Filter -is [array]) {
            Get-ChildItem -Path $Path -Include $Filter -Recurse
        } else {
            Get-ChildItem -Path $Path -Filter $Filter -Recurse
        }
    } else {
        Get-ChildItem -Path $Path -Recurse
    }
    $aMenuItems = @()
    $i = 1
    foreach ($item in $aItems) {
        $sMenuItemText = if ($ShowFile.IsPresent) {
            $item.FullName
        } else {
            $sPath = if ($Path -match "^(.*)\\$") {
                $Matches.1
            } else {
                $Path
            }
            $item.FullName.Substring($sPath.Length + 1).Split("\")[0]
        }
        $item | Add-Member -NotePropertyName "MenuText" -NotePropertyValue $sMenuItemText
        $item | Add-Member -NotePropertyName "MenuIndex" -NotePropertyValue $i 
        $i += 1
        $aMenuItems += $item
    }
    if ($AllowOtherFile.IsPresent) {
        $newItem = [PSCustomObject]@{
            MenuText = $OtherFileMenuItemText
            MenuIndex = $OtherFileMenuNumber
        }
        $aMenuItems += $newItem
    }
    if ($AllowExit.IsPresent) {
        $newItem = [PSCustomObject]@{
            MenuText = $OtherFileMenuItemText
            MenuIndex = $OtherFileMenuNumber
        }
        $aMenuItems += $newItem
    }
    # Write menu
    $validAnswer = $false
    while (-not $validAnswer) {
        Write-Host $SelectHeaderMessage
        foreach ($item in $aMenuItems) {
            Write-Host $($item.MenuIndex.ToString() + "`t" + $item.MenuText)
        }
        $selectedItem = Read-Host $FooterMessage
        if ($selectedItem -in $aMenuItems.MenuIndex) {
            $sAnswerType = switch -regex ($selectedItem) {
                "^[0-9]+$" { "Value" }
                "^$OtherFileMenuNumber$" { "OtherFile" }
                "^$NoFileItemNumber$" {"NoFile" }
                "^$ExitMenuItemNumber$" { "Exit" }
            }
            $oSelectedFile = switch ($sAnswerType) {
                "OtherFile" {
                    $validOtherFile = $false
                    while (-not $validOtherFile) {
                        $sOtherFilePath = Read-Host -Prompt $OtherFilePromptText
                        if ($sOtherFilePath -match "^\""(.+)\""$") {
                            $sOtherFilePath = $Matches.1
                        }
                        $validOtherFile = Test-Path -Path $sOtherFilePath -PathType Leaf
                        if (-not $validOtherFile) {
                            Write-Host "File path is not valid" -ForegroundColor Red
                        }
                    }
                    Get-Item -Path $sOtherFilePath
                }
                "Value" {
                    $aMenuItems | Where-Object { $_.MenuIndex -eq $selectedItem }
                }
                default {
                    $null
                }
            }
            $sFileName = if ($null -ne $oSelectedFile) {
                Split-Path -Path $oSelectedFile.FullName -Leaf
            } else {
                $null
            }
            $sParent = if ($null -ne $oSelectedFile) {
                Split-Path -Path (Split-Path -Path $oSelectedFile.FullName -Parent) -Leaf
            } else {
                $null
            }
            return [PSCustomObject]@{
                AnswerType = $sAnswerType
                ItemSelected = $selectedItem
                ItemMenu = ($aMenuItems | Where-Object { $_.MenuIndex -eq $selectedItem}).MenuText
                FileSelected = $oSelectedFile
                Parent = $sParent
                FileName = $sFileName
            }
        }
        if (-not $validAnswer) {
            Write-Host "The value you typed is not valid. Please chose another value." -ForegroundColor Red
        }
    }
}