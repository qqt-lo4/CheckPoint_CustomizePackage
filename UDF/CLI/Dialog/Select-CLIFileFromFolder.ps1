function Select-CLIFileFromFolder {
    Param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string[]]$Filter,
        [switch]$ShowFile,
        [switch]$AllowOtherFile,
        [switch]$AllowNoFile,
        [switch]$AllowExit,
        [string]$SelectHeaderMessage = "Please select an item:",
        [string]$ColumnName = "Folder Name",
        [System.ConsoleColor]$HeaderColor = (Get-Host).UI.RawUI.ForegroundColor,
        [System.ConsoleColor]$SeparatorColor = (Get-Host).UI.RawUI.ForegroundColor,
        [string]$OtherFilePromptText = "Please enter a file path",
        [switch]$Recurse,
        [string]$EmptyArrayMessage = "No items in array"
    )
    # Build menu items
    $aItems = if ($Filter) {
        if ($Filter -is [array]) {
            Get-ChildItem -Path $Path -Include $Filter -Recurse:$Recurse -ErrorAction SilentlyContinue
        } else {
            Get-ChildItem -Path $Path -Filter $Filter -Recurse:$Recurse -ErrorAction SilentlyContinue
        }
    } else {
        Get-ChildItem -Path $Path -Recurse:$Recurse -ErrorAction SilentlyContinue
    } 
    $sColumn = if ($ShowFile) {
        "FullName"
    } else {
        $ColumnName
    }
    if ($sColumn -eq $ColumnName) {
        $aItems | ForEach-Object {
            $_ | Add-Member -NotePropertyName $ColumnName -NotePropertyValue $_.Directory.Name
        }
    }

    $aOtherMenuItems = @()
    if ($AllowOtherFile) {
        $aOtherMenuItems += New-CLIDialogButton -Other -Text "Select An&other File" -Object {
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
        } -AddNewLine -Keyboard O
    }
    if ($AllowNoFile) {
        $aOtherMenuItems += New-CLIDialogButton -DoNotSelect -Text "Do &not select a file" -Keyboard N -AddNewLine
    }
    if ($AllowExit) {
        $aOtherMenuItems += New-CLIDialogButton -Exit -Text "&Exit this menu" -Keyboard E -AddNewLine
    }
    return Select-CLIObjectInArray -Objects $aItems `
                                   -SelectedColumns $sColumn `
                                   -SelectHeaderMessage $SelectHeaderMessage `
                                   -OtherMenuItems $aOtherMenuItems `
                                   -HeaderTextInSeparator `
                                   -FooterMessage $null `
                                   -SeparatorColor $SeparatorColor `
                                   -HeaderColor $HeaderColor `
                                   -ItemsPerPage 8 `
                                   -EmptyArrayMessage $EmptyArrayMessage
}