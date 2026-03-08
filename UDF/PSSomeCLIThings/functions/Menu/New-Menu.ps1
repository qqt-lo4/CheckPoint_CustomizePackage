function New-Menu {
    <#
    .SYNOPSIS
        Creates a menu object for interactive CLI navigation with main and secondary items.

    .DESCRIPTION
        Constructs a menu structure that can contain menu items, sub-menus, and actions.
        Supports pagination, keyboard shortcuts, enter/exit actions, and customizable styling.
        Can be used as a sub-menu within another menu or as a standalone root menu.

    .PARAMETER Text
        Menu title displayed in the separator. Mandatory.

    .PARAMETER Content
        Array of menu items (MenuItem, Menu, or MenuAction objects). Mandatory.
        Alias: Subitems

    .PARAMETER OtherMenuItems
        Secondary menu items (Help, Settings, Exit, etc.) shown after a separator.
        Alias: OtherItems

    .PARAMETER EnterMenuAction
        Scriptblock executed when entering this menu.

    .PARAMETER ExitMenuAction
        Scriptblock executed when leaving this menu.

    .PARAMETER MenuItemCount
        Maximum items per page for pagination. Default: 15.

    .PARAMETER PaginatedSeparator
        Enable paginated separators for long menus.

    .PARAMETER SeparatorColor
        Color of menu separators. Default: current foreground color.

    .PARAMETER Keyboard
        Keyboard shortcut key to access this menu. Alias: Item

    .PARAMETER Underline
        Character position to underline in menu text. Default: -1 (none).

    .EXAMPLE
        $menu = New-Menu -Text "Main Menu" -Content @(
            New-MenuItem -Text "Action 1" -Content { Do-Something }
        ) -OtherMenuItems @(New-MenuAction -Text "Exit" -Exit)

    .NOTES
        Author: Loïc Ade
        Created: 2025-11-22
        Version: 1.0.0
        Module: CLIDialog
        Dependencies: New-CLIDialogButton
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Text,
        [Parameter(Mandatory, Position = 1)]
        [Alias("Subitems")]
        [object]$Content,
        [Parameter(Position = 2)]
        [Alias("OtherItems")]
        [object]$OtherMenuItems,
        [scriptblock]$EnterMenuAction,
        [scriptblock]$ExitMenuAction,
        [int]$MenuItemCount = 15,
        [switch]$PaginatedSeparator,
        [System.ConsoleColor]$SeparatorColor = (Get-Host).UI.RawUI.ForegroundColor,
        [Alias("Item")]
        [System.ConsoleKey]$Keyboard,
        [int]$Underline = -1
    )
    $hResult = @{
        Text = $Text
        Type = "menu"
        Content = $Content
    	OtherMenuItems = $OtherMenuItems
    	EnterMenuAction = $EnterMenuAction
    	ExitMenuAction = $ExitMenuAction
        MenuItemCount = $MenuItemCount
        PaginatedSeparator = $PaginatedSeparator
        SeparatorColor = $SeparatorColor
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "ConvertToButton" -Value {
        Param(
            [bool]$AddNewLine = $true
        )
        $hNewCLIButtonArgs = @{
            Text = $this.Text
            Object = $this
            AddNewLine = $AddNewLine
        }
        if ($this.Keyboard) { $hNewCLIButtonArgs.Keyboard = $this.Keyboard }
        return New-CLIDialogButton @hNewCLIButtonArgs
    }

    $hResult.psobject.TypeNames.Insert(0, "Menu")

    return $hResult
}
