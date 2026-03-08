function Edit-Hashtable {
<#
.SYNOPSIS
    Displays an interactive dialog to edit hashtable values.

.DESCRIPTION
    This function creates an interactive CLI dialog that allows users to edit the values
    of a hashtable. Each key-value pair is presented as an editable text box, and users
    can navigate through the fields and update values before confirming or canceling.

.PARAMETER Hashtable
    The hashtable object to edit. This parameter is mandatory.

.PARAMETER HeadersColor
    The color used for displaying property headers. Default is Green.

.PARAMETER SelectedItemColor
    The color used for the currently selected/focused item. Default is Blue.

.PARAMETER HeaderQuestion
    The header text displayed at the top of the dialog. Default is "Please fill the form:".

.PARAMETER HeaderQuestionColor
    The color used for the header question text. Default is the current console foreground color.

.PARAMETER PropertyAlign
    The alignment of property names. Valid values are "Left" or "Right". Default is "Left".

.PARAMETER FooterMessage
    Optional footer message displayed at the bottom of the dialog.

.PARAMETER FooterMessageColor
    The color used for the footer message. Default is the current console foreground color.

.PARAMETER Prefix
    The prefix string displayed before unfocused items. Default is "  ".

.PARAMETER FocusedPrefix
    The prefix string displayed before the focused item. Default is "> ".

.OUTPUTS
    Returns an ordered hashtable with the updated values if OK is pressed, or $null if Cancel is pressed.

.EXAMPLE
    $config = @{ Name = "John"; Age = "30"; City = "Paris" }
    $result = Edit-Hashtable -Hashtable $config
    if ($result) {
        Write-Host "Updated values: $($result | Out-String)"
    }

.EXAMPLE
    $settings = [ordered]@{ Server = "localhost"; Port = "8080" }
    $updated = Edit-Hashtable -Hashtable $settings -HeadersColor Yellow -HeaderQuestion "Configure server settings:"

.NOTES
    Module: CLIDialog
    Author: Loïc Ade
    Created: 2025-10-20
    Version: 1.0.0
    Dependencies: New-CLIDialog, New-CLIDialogTextBox, New-CLIDialogObjectsRow, New-CLIDialogButton, Invoke-CLIDialog

    This function requires the New-CLIDialog and related CLI dialog functions to be available.

    CHANGELOG:

    Version 1.0.0 - 2025-10-20 - Loïc Ade
        - Initial release
        - Basic hashtable editing functionality
        - Support for customizable colors and prefixes
        - OK/Cancel button navigation
#>
    Param (
		[Parameter(Mandatory, Position = 0)]
		[object]$Hashtable,
		[System.ConsoleColor]$HeadersColor = [System.ConsoleColor]::Green,
        [System.ConsoleColor]$SelectedItemColor = [System.ConsoleColor]::Blue,
        [string]$HeaderQuestion = "Please fill the form:",
        [System.ConsoleColor]$HeaderQuestionColor = (Get-Host).UI.RawUI.ForegroundColor,
        [ValidateSet("Left", "Right")]
        [string]$PropertyAlign = "Left",
		[string]$FooterMessage = "",
		[System.ConsoleColor]$FooterMessageColor = (Get-Host).UI.RawUI.ForegroundColor,
        [string]$Prefix = "  ",
        [string]$FocusedPrefix = "> "
	)
    $iLongestProperty = 0
    foreach ($p in $Hashtable.Keys) {
        if ($p.Length -gt $iLongestProperty) {
            $iLongestProperty = $p.Length
        }
    }
    $hDialog = @(
        New-CLIDialogText -Text $HeaderQuestion -ForegroundColor $HeaderQuestionColor -AddNewLine
    )
    foreach ($p in $Hashtable.Keys) {
        $hDialog += New-CLIDialogTextBox -Header $p -HeaderAlign $PropertyAlign -HeaderForegroundColor $HeadersColor -FocusedHeaderForegroundColor $SelectedItemColor -Text $Hashtable[$p] -Prefix $Prefix -FocusedPrefix $FocusedPrefix
    }
    if ($FooterMessage) {
        $hDialog += New-CLIDialogText -Text $FooterMessage -ForegroundColor $FooterMessageColor
    }
    $hDialog += New-CLIDialogObjectsRow -Row @(
        New-CLIDialogSpace -Length ($iLongestProperty + $FocusedPrefix.Length)
        New-CLIDialogButton -Text "&OK" -Validate
        New-CLIDialogSpace -Length 3
        New-CLIDialogButton -Text "&Cancel" -Cancel
    ) -Prefix $Prefix -FocusedPrefix $FocusedPrefix
    $oResult = (New-CLIDialog -Rows $hDialog).Invoke()
    if ($oResult.Button.Cancel) {
        return $null
    } else {
        $hResult = [ordered]@{}
        foreach ($prop in $($oResult.Form.Rows | Where-Object { $_.Type -eq "textbox" })) {
            $hResult.$($prop.Header) = $prop.GetValue()
        }
        return $hResult
    }
}
