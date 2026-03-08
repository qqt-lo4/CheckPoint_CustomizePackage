function New-MenuAction {
    <#
    .SYNOPSIS
        Creates a menu action button (Back, Exit, Yes, No, etc.) for menu navigation.

    .DESCRIPTION
        Constructs a menu action object representing navigation or confirmation actions.
        Uses parameter sets to ensure only one action type is specified. Supports
        keyboard shortcuts and custom colors.

    .PARAMETER Text
        Button text displayed in the menu.

    .PARAMETER Yes/No/Cancel/Back/Exit/Validate/Previous/Next/Refresh/Other/DoNotSelect/GoTo
        Action type (mutually exclusive). Only one can be specified.

    .PARAMETER Keyboard
        Keyboard shortcut key for this action.

    .PARAMETER BackgroundColor/ForegroundColor
        Button colors when not focused. Default: console colors.

    .PARAMETER FocusedBackgroundColor/FocusedForegroundColor
        Button colors when focused. Default: inverted console colors.

    .PARAMETER Underline
        Character position to underline. Default: -1 (none).

    .EXAMPLE
        New-MenuAction -Text "&Back" -Back -Keyboard B

    .EXAMPLE
        New-MenuAction -Text "E&xit" -Exit -ForegroundColor Red

    .NOTES
        Author: Loïc Ade
        Created: 2025-11-22
        Version: 1.0.0
        Module: CLIDialog
        Dependencies: New-CLIDialogButton
    #>
    Param(
        [string]$Text,
        [Parameter(ParameterSetName = "Yes")]
        [switch]$Yes,
        [Parameter(ParameterSetName = "No")]
        [switch]$No,
        [Parameter(ParameterSetName = "Cancel")]
        [switch]$Cancel,
        [Parameter(ParameterSetName = "Back")]
        [switch]$Back,
        [Parameter(ParameterSetName = "Exit")]
        [switch]$Exit,
        [Parameter(ParameterSetName = "Validate")]
        [switch]$Validate,
        [Parameter(ParameterSetName = "Previous")]
        [switch]$Previous,
        [Parameter(ParameterSetName = "Next")]
        [switch]$Next,
        [Parameter(ParameterSetName = "Refresh")]
        [switch]$Refresh,
        [Parameter(ParameterSetName = "Other")]
        [switch]$Other,
        [Parameter(ParameterSetName = "DoNotSelect")]
        [switch]$DoNotSelect,
        [Parameter(ParameterSetName = "GoTo")]
        [switch]$GoTo,
        [System.ConsoleKey]$Keyboard,
        [System.ConsoleColor]$BackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [System.ConsoleColor]$ForegroundColor = (Get-Host).UI.RawUI.ForegroundColor,
        [System.ConsoleColor]$FocusedBackgroundColor = (Get-Host).UI.RawUI.ForegroundColor,
        [System.ConsoleColor]$FocusedForegroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [int]$Underline = -1
    )
    $hResult = @{
        Text = $Text
        Type = "menuaction"
        Content = $PSCmdlet.ParameterSetName
        Keyboard = $Keyboard
        Underline = $Underline
        BackgroundColor = $BackgroundColor
        ForegroundColor = $ForegroundColor
        FocusedBackgroundColor = $FocusedBackgroundColor 
        FocusedForegroundColor = $FocusedForegroundColor
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "ConvertToButton" -Value {
        Param(
            [bool]$AddNewLine = $true
        )
        $hNewCLIButtonArgs = @{
            Text = $this.Text
            BackgroundColor = $this.BackgroundColor
            ForegroundColor = $this.ForegroundColor
            FocusedBackgroundColor = $this.FocusedBackgroundColor
            FocusedForegroundColor = $this.FocusedForegroundColor
            Object = $this
            $($this.Content) = $true
            Underline = $this.Underline
            AddNewLine = $AddNewLine
        }
        if ($this.Keyboard) { $hNewCLIButtonArgs.Keyboard = $this.Keyboard }
        return New-CLIDialogButton @hNewCLIButtonArgs    
    }

    $hResult.psobject.TypeNames.Insert(0, "MenuAction")

    return $hResult
}
