function Invoke-YesNoCLIDialog {
    [CmdletBinding(DefaultParameterSetName = "YNC")]
    Param(
        [Parameter(Mandatory)]
        [string]$Message,
        [Parameter(ParameterSetName = "YNC")]
        [switch]$YNC,
        [Parameter(ParameterSetName = "NC")]
        [switch]$NC,
        [Parameter(ParameterSetName = "YN")]
        [switch]$YN,
        [string]$YesButtonText = "&Yes",
        [System.ConsoleKey]$YesKeyboard = ([System.ConsoleKey]::Y),
        [string]$NoButtonText = "&No",
        [System.ConsoleKey]$NoKeyboard = ([System.ConsoleKey]::N),
        [string]$CancelButtonText = "&Cancel",
        [System.ConsoleKey]$CancelKeyboard = ([System.ConsoleKey]::C),
        [switch]$Vertical,
        [uint16]$SpaceBefore = 5,
        [System.ConsoleColor]$HeaderForegroundColor = [System.ConsoleColor]::Green,
        [System.ConsoleColor]$HeaderBackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [System.ConsoleColor]$ButtonForegroundColor = (Get-Host).UI.RawUI.ForegroundColor,
        [System.ConsoleColor]$ButtonBackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [System.ConsoleColor]$FocusedButtonForegroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [System.ConsoleColor]$FocusedButtonBackgroundColor = (Get-Host).UI.RawUI.ForegroundColor
    )
    $aCliDialogRows = @(New-CLIDialogText -Text $Message -ForegroundColor $HeaderForegroundColor -BackgroundColor $HeaderBackgroundColor -AddNewLine)
    if ($Vertical) {
        if ($PSCmdlet.ParameterSetName.Contains("Y")) {
            $aCliDialogRows += if ($SpaceBefore -gt 0) {
                New-CLIDialogObjectsRow -Row @(
                    New-CLIDialogSpace -Length $SpaceBefore
                    New-CLIDialogButton -Text $YesButtonText -Keyboard $YesKeyboard -Yes
                )
            } else {
                New-CLIDialogObjectsRow -Row @(New-CLIDialogButton -Text $YesButtonText -Keyboard $YesKeyboard -Yes)
            }    
        }
        $aCliDialogRows += if ($SpaceBefore -gt 0) {
            New-CLIDialogObjectsRow -Row @(
                New-CLIDialogSpace -Length $SpaceBefore
                New-CLIDialogButton -Text $NoButtonText -Keyboard $NoKeyboard -No
            )
        } else {
            New-CLIDialogObjectsRow -Row @(New-CLIDialogButton -Text $NoButtonText -Keyboard $NoKeyboard -No)
        }
        if ($PSCmdlet.ParameterSetName.Contains("C")) {
            $aCliDialogRows += if ($SpaceBefore -gt 0) {
                New-CLIDialogObjectsRow -Row @(
                    New-CLIDialogSpace -Length $SpaceBefore
                    New-CLIDialogButton -Text $CancelButtonText -Keyboard $CancelKeyboard -Cancel
                )
            } else {
                New-CLIDialogObjectsRow -Row @(New-CLIDialogButton -Text $CancelButtonText -Keyboard $CancelKeyboard -Cancel)
            }
        }
    } else {
        $oRow = @()
        if ($SpaceBefore -gt 0) {
            $oRow += New-CLIDialogSpace -Length $SpaceBefore
        }
        if ($PSCmdlet.ParameterSetName.Contains("Y")) {
            $oRow += New-CLIDialogButton -Text $YesButtonText -Keyboard $YesKeyboard -Yes
        }
        $oRow += New-CLIDialogButton -Text $NoButtonText -Keyboard $NoKeyboard -No
        if ($PSCmdlet.ParameterSetName.Contains("C")) {
            $oRow += New-CLIDialogButton -Text $CancelButtonText -Keyboard $CancelKeyboard -Cancel
        }
        $aCliDialogRows += New-CLIDialogObjectsRow -Row $oRow
    }
    $hDialogArgs = @{
        Rows = $aCliDialogRows
    }
    if ($PSCmdlet.ParameterSetName.Contains("C")) {
        $hDialogArgs.EscapeObject = New-CLIDialogButton -Text $CancelButtonText -Keyboard $CancelKeyboard -Cancel
    }
    $oDialog = New-CLIDialog -Rows $aCliDialogRows
    $oDialogResult = Invoke-CLIDialog $oDialog
    return $oDialogResult.Action
}
