function Invoke-Menu {
    <#
    .SYNOPSIS
        Displays and executes an interactive menu with support for nested sub-menus.

    .DESCRIPTION
        Renders a menu object and handles user interaction through a CLI dialog interface.
        Supports hierarchical menu structures, menu item execution, sub-menu navigation,
        and menu actions (Back, Exit). Tracks recursion depth for proper navigation.

    .PARAMETER Menu
        Menu object created with New-Menu. Must have Type = "menu".

    .PARAMETER Depth
        Current depth level in menu hierarchy. Default: 0 (root menu).
        Used internally for recursive sub-menu navigation.

    .EXAMPLE
        $menu = New-Menu -Text "Main Menu" -Content @(
            New-MenuItem -Text "Option 1" -Content { Write-Host "Selected" }
        ) -OtherMenuItems @(New-MenuAction -Text "Exit" -Exit)
        Invoke-Menu -Menu $menu

    .NOTES
        Author: Loïc Ade
        Created: 2025-11-22
        Version: 1.0.0
        Module: CLIDialog
        Dependencies: New-CLIDialogSeparator, New-CLIDialog, Invoke-CLIDialog, New-DialogResultAction
    #>
    Param(
        [Parameter(Position = 0)]
        [object]$Menu,
        [int]$Depth = 0
    )
    Begin {
        if ($Menu.Type -ne "menu") {
            throw "Object is not a menu"
        }
        $aDialogLines = @()
        if ($Menu.Text) {
            $aDialogLines += New-CLIDialogSeparator -Text ($Menu.Text -replace "&", "") -AutoLength -ForegroundColor $Menu.SeparatorColor 
        }
        $iRecommended = 0
        $i = 0
        foreach ($menuitem in $Menu.Content) {
            $oNewButton = $menuitem.ConvertToButton()
            if ($menuitem.Recommended) {
                $iRecommended = $i
            }
            $oNewButton.AddNewLine = $true
            $aDialogLines += $oNewButton
            $i++
        }
        if ($Menu.OtherMenuItems) {
            $aDialogLines += New-CLIDialogSeparator -AutoLength -ForegroundColor $Menu.SeparatorColor
            foreach ($menuitem in $Menu.OtherMenuItems) {
                $oNewButton = $menuitem.ConvertToButton()
                $oNewButton.AddNewLine = $true
                $aDialogLines += $oNewButton
            }
        }
        $aDialogLines += New-CLIDialogSeparator -AutoLength -ForegroundColor $Menu.SeparatorColor    
        $oDialog = New-CLIDialog -Rows $aDialogLines
        $oDialog.FocusedRow = $iRecommended
    }
    Process {
        while ($true) {
            $oDialogItem = Invoke-CLIDialog -InputObject $oDialog -Execute
            $oDialogResult = switch ($oDialogItem.Value.PSObject.TypeNames[0]) {
                "MenuAction" {
                    $sAction = $oDialogItem.Action
                    if ($sAction -eq "Exit") {
                        New-DialogResultAction -Action "Exit" -DialogResult $oDialogItem.Value
                    } else {
                        New-DialogResultAction -Action "Back" -DialogResult $oDialogItem.Value
                    }
                }
                "MenuItem" {
                    Invoke-Command -ScriptBlock $oDialogItem.Value.Content
                }
                "Menu" {
                    Invoke-Menu -Menu $oDialogItem.Value -Depth ($Depth + 1)
                }
            }
            switch ($oDialogResult.PSObject.TypeNames[0]) {
                "DialogResult.Action.Exit" {
                    if ($Depth -eq 0) {
                        Exit
                    } else {
                        return $oDialogResult
                    }
                }
                "DialogResult.Action.Back" {
                    if ($oDialogResult.Depth -eq 0) {
                        $oDialogResult.Depth += 1
                        return $oDialogResult
                    }
                }
                default {
                    return $oDialogResult
                }
            }
            #return $oDialogResult
        }
    }
}