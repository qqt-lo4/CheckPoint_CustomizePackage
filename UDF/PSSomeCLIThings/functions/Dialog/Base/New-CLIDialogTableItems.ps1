function New-CLIDialogTableItems {
    <#
    .SYNOPSIS
        Creates a table display of objects for CLI dialog interfaces with optional checkboxes or buttons.

    .DESCRIPTION
        This function generates CLI dialog rows displaying objects in a formatted table layout.
        Each object can be rendered as either a checkbox or a button, making it ideal for selection
        menus or interactive lists. The function automatically formats the table headers and content,
        adjusting to console width and supporting pre-selected items via checkboxes.

    .PARAMETER Objects
        An array of objects to display in the table. This parameter is mandatory.
        Each object will be rendered as a row with either a checkbox or button.

    .PARAMETER Properties
        Specifies which properties of the objects to display in the table columns.
        Can be an array of property names or a hashtable with custom formatting.
        If null, all properties will be displayed.

    .PARAMETER Checkbox
        Switch parameter. If specified, each row will be rendered as a checkbox instead of a button.
        Useful for multi-selection scenarios.

    .PARAMETER EnabledObjectsArray
        A reference to an array containing objects that should be pre-checked (enabled).
        Only used when -Checkbox is specified. Objects are matched using the property specified
        in EnabledObjectsUniqueProperty.

    .PARAMETER EnabledObjectsUniqueProperty
        The property name used to uniquely identify objects when matching against EnabledObjectsArray.
        For example, "Id", "Name", or any unique identifier property.

    .PARAMETER Space
        Switch parameter. If specified, adds a space prefix before each row (except checkboxes which
        have their own spacing). Useful for indentation and visual hierarchy.

    .OUTPUTS
        Returns an array of CLI dialog row objects (New-CLIDialogText, New-CLIDialogCheckBox, or
        New-CLIDialogButton objects) that can be used with New-CLIDialog.

    .EXAMPLE
        $servers = @(
            [PSCustomObject]@{ Name = "Server1"; IP = "192.168.1.1"; Status = "Online" }
            [PSCustomObject]@{ Name = "Server2"; IP = "192.168.1.2"; Status = "Offline" }
        )
        $rows = New-CLIDialogTableItems -Objects $servers

        Creates button rows for each server object.

    .EXAMPLE
        $users = @(
            [PSCustomObject]@{ Id = 1; Name = "Alice"; Role = "Admin" }
            [PSCustomObject]@{ Id = 2; Name = "Bob"; Role = "User" }
        )
        $rows = New-CLIDialogTableItems -Objects $users -Checkbox

        Creates checkbox rows for user selection.

    .EXAMPLE
        $selected = @([PSCustomObject]@{ Id = 1; Name = "Alice" })
        $allUsers = @(
            [PSCustomObject]@{ Id = 1; Name = "Alice"; Role = "Admin" }
            [PSCustomObject]@{ Id = 2; Name = "Bob"; Role = "User" }
        )
        $rows = New-CLIDialogTableItems -Objects $allUsers -Checkbox `
            -EnabledObjectsArray ([ref]$selected) -EnabledObjectsUniqueProperty "Id"

        Creates checkbox rows with Alice pre-selected based on Id matching.

    .EXAMPLE
        $items = Get-Process | Select-Object -First 5
        $rows = New-CLIDialogTableItems -Objects $items -Properties @("Name", "Id", "CPU") -Space

        Creates button rows showing only Name, Id, and CPU properties with spacing.

    .NOTES
        Module: CLIDialog
        Author: Loïc Ade
        Created: 2025-10-20
        Version: 1.0.0
        Dependencies: Format-TableCustom, New-CLIDialogText, New-CLIDialogCheckBox, New-CLIDialogButton

        This function is part of the CLI Dialog framework and depends on:
        - Format-TableCustom: For table formatting
        - New-CLIDialogText: For header display
        - New-CLIDialogCheckBox: For checkbox rows
        - New-CLIDialogButton: For button rows

        The function automatically adjusts content width based on console size, reserving
        4 characters for checkbox spacing when checkboxes are enabled.

        CHANGELOG:

        Version 1.0.0 - 2025-10-20 - Loïc Ade
            - Initial release
            - Support for checkbox and button modes
            - Pre-selection support via EnabledObjectsArray
            - Automatic console width adjustment
            - Custom property selection
            - Optional spacing support
    #>
    Param(
        [Parameter(Mandatory)]
        [Object[]]$Objects,
        [AllowNull()]
        [object]$Properties,
        [switch]$Checkbox,
        [ref]$EnabledObjectsArray,
        [string]$EnabledObjectsUniqueProperty,
        [switch]$Space
    )
    $ContentMaxWidth = if ($Checkbox) {
        (Get-Host).UI.RawUI.WindowSize.Width - 4
    } else {
        (Get-Host).UI.RawUI.WindowSize.Width
    }
    $aFormatTableItems = $Objects | Format-TableCustom -ToString -HeaderColor Green -Property $Properties -ContentMaxWidth $ContentMaxWidth
    $aFormRows = @(
        # First line containing array headers
        $sFirstRowText = if ($Checkbox) {
            "    $($aFormatTableItems[0])"
        } else {
            if ($Space) {
                " " + $aFormatTableItems[0]
            } else {
                $aFormatTableItems[0]
            }
        }
        New-CLIDialogText -Text $sFirstRowText -ForegroundColor Green -AddNewLine
    )
    for ($i = 1; $i -lt $aFormatTableItems.Count; $i++) {
        $hParams = @{
            Text = $aFormatTableItems[$i]
            Object = $Objects[$i - 1] 
            AddNewLine = $true 
            NoSpace = -not $Space
        }
        $aFormRows += if ($Checkbox) {
            if ($EnabledObjectsArray) {
                if ($EnabledObjectsArray.Value | Where-Object { $_.$EnabledObjectsUniqueProperty -eq $Objects[$i - 1].$EnabledObjectsUniqueProperty }) {
                    New-CLIDialogCheckBox @hParams -Enabled $true
                } else {
                    New-CLIDialogCheckBox @hParams -Enabled $false
                }
            } else {
                New-CLIDialogCheckBox @hParams
            }
        } else {
            New-CLIDialogButton @hParams
        }
    }
    return $aFormRows
}
