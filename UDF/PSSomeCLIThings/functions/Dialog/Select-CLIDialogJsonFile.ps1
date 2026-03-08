function Select-CLIDialogJsonFile {
    <#
    .SYNOPSIS
        Displays an interactive dialog to select a JSON file from a folder and returns its parsed content.

    .DESCRIPTION
        This function scans a specified folder for JSON files, parses them, and displays an interactive
        selection dialog showing specified properties from each JSON file. The user can select one file,
        and the function returns the parsed JSON content as a PowerShell object.

        Key features:
        - Automatic JSON file discovery in a folder
        - Multiple file filter patterns (*.json, *.jsonc)
        - Optional filtering via custom filter function
        - Auto-selection when only one file exists (optional)
        - Display selected item details after selection
        - Customizable columns for display and sorting
        - Error handling for empty folders

        The workflow:
        1. Scan JsonFolder for JSON files matching Filter patterns
        2. Parse all JSON files and extract specified JsonColumn properties
        3. Apply optional FilterFunction to filter results
        4. Display selection dialog (or auto-select if only one item and AlwaysAskUser is false)
        5. Optionally display selected item details
        6. Return parsed JSON content

    .PARAMETER JsonFolder
        Path to the folder containing JSON files to scan. This parameter is mandatory and can be
        used at position 0. The folder must exist or an error will be thrown.
        Example: "C:\Config", ".\Settings"

    .PARAMETER JsonColumn
        Array of property names to display in the selection table. These properties are extracted
        from each parsed JSON file. Default: @("Description")
        Example: @("Name", "Version", "Description")

    .PARAMETER Sort
        Property name(s) to sort the files by before displaying. Default: @("Description")
        Can be a single property or array of properties for multi-level sorting.

    .PARAMETER SelectHeaderMessage
        Header message displayed at the top of the selection dialog.
        Default: "Please select an item:"

    .PARAMETER HeaderColor
        Color of the header message text. Default: Current console foreground color

    .PARAMETER FooterMessage
        Footer message displayed at the bottom of the selection dialog.
        Default: "Please type item number"
        Can be set to $null to hide the footer.

    .PARAMETER FooterColor
        Color of the footer message text. Default: Current console foreground color

    .PARAMETER ErrorMessage
        Custom error message to display when no JSON files are found in the folder.
        If not specified, a DirectoryNotFoundException is thrown with default message.

    .PARAMETER FilterFunction
        Name of a filter function to apply to the JSON objects after loading.
        The function receives the array of JSON objects and FilteredValue as parameters.
        Example: "Filter-ByEnvironment"

    .PARAMETER FilteredValue
        Value to pass to the FilterFunction. Can be any object type that the filter
        function expects. Ignored if FilterFunction is not specified.

    .PARAMETER AlwaysAskUser
        Switch parameter. When set, always displays the selection dialog even if only
        one JSON file is found. Without this switch, a single file is auto-selected.

    .PARAMETER Filter
        Array of file filter patterns to match JSON files in the folder.
        Default: @("*.json", "*.jsonc")
        Supports standard wildcard patterns.

    .PARAMETER SeparatorColor
        Color of the separator lines in the dialog. Default: Current console foreground color

    .PARAMETER HeaderTextInSeparator
        Switch parameter. When set, displays the header text inside the separator line
        instead of as a separate text line. Creates a more compact layout.

    .PARAMETER DisplaySelectedItem
        Switch parameter. When set, displays a formatted table of the selected item's
        properties after selection and before returning the result.

    .PARAMETER SelectedItemText
        Text to display above the selected item table when DisplaySelectedItem is set.
        Default: "Selected item:"
        The text is displayed with underline formatting.

    .OUTPUTS
        Returns a DialogResult object with PSTypeName "DialogResult.Value".
        The .Value property contains the parsed JSON content as a PowerShell object (hashtable/PSCustomObject).

    .EXAMPLE
        $config = Select-CLIDialogJsonFile -JsonFolder "C:\Config\Environments"
        $serverUrl = $config.Value.ServerUrl
        $apiKey = $config.Value.ApiKey

        Selects a JSON configuration file and accesses its properties.

    .EXAMPLE
        $result = Select-CLIDialogJsonFile -JsonFolder ".\Settings" `
                                          -JsonColumn @("Name", "Environment", "Version") `
                                          -Sort @("Environment", "Name") `
                                          -DisplaySelectedItem

        Displays multiple columns, sorts by Environment then Name, and shows selected item details.

    .EXAMPLE
        $profile = Select-CLIDialogJsonFile -JsonFolder "C:\Profiles" `
                                           -Filter @("*.json") `
                                           -AlwaysAskUser `
                                           -SelectHeaderMessage "Select deployment profile:"

        Forces selection dialog even for single file, custom header, only *.json files.

    .EXAMPLE
        function Filter-Production {
            param($items, $env)
            return $items | Where-Object { $_.Environment -eq $env }
        }

        $config = Select-CLIDialogJsonFile -JsonFolder ".\Configs" `
                                          -FilterFunction "Filter-Production" `
                                          -FilteredValue "Production" `
                                          -ErrorMessage "No production configs found"

        Uses custom filter function to show only production environment configs.

    .EXAMPLE
        $result = Select-CLIDialogJsonFile -JsonFolder "C:\Templates" `
                                          -JsonColumn @("Title", "Category") `
                                          -HeaderTextInSeparator `
                                          -SeparatorColor Cyan `
                                          -SelectedItemText "Selected template:"

        Custom colors and compact header layout with selected item display.

    .NOTES
        Module: CLIDialog
        Author: Loïc Ade
        Created: 2024-09-21
        Version: 1.1.0
        Dependencies: Get-JSONFileList, Select-CLIDialogObjectInArray, Format-TableCustom, Set-StringFormat

        This function is designed for configuration management scenarios where JSON files are used
        to store settings, profiles, or templates, and users need to select one interactively.

        JSON FILE REQUIREMENTS:
        - Files must be valid JSON or JSONC (JSON with comments)
        - Files must be parseable by PowerShell's JSON parser
        - JsonColumn properties must exist in the JSON files
        - If a property doesn't exist, it will be shown as empty in the table

        GET-JSONFILELIST FUNCTION:
        This function relies on Get-JSONFileList which:
        - Scans the specified folder for files matching Filter patterns
        - Parses each JSON file
        - Extracts the specified JsonColumn properties
        - Returns an array of objects with file content and metadata

        FILTER FUNCTION:
        The FilterFunction is executed as a scriptblock:
        ```powershell
        $filteredArray = & $FilterFunction $arrayJson $FilteredValue
        ```

        Example filter function:
        ```powershell
        function Filter-ByProperty {
            param($jsonArray, $value)
            return $jsonArray | Where-Object { $_.PropertyName -eq $value }
        }
        ```

        AUTO-SELECTION BEHAVIOR:
        - If only 1 file exists and AlwaysAskUser is NOT set: Auto-selects the file
        - If only 1 file exists and AlwaysAskUser IS set: Shows selection dialog
        - If 0 files exist: Throws DirectoryNotFoundException with ErrorMessage
        - If multiple files exist: Always shows selection dialog

        DISPLAY SELECTED ITEM:
        When DisplaySelectedItem is set, displays:
        1. Underlined text: "Selected item:" (or SelectedItemText)
        2. Formatted table with JsonColumn properties
        3. Blank line
        Then returns the result

        RETURN VALUE:
        The function returns a DialogResult from Select-CLIDialogObjectInArray:
        ```powershell
        @{
            PSTypeName = "DialogResult.Value"
            Type = "Value"
            Value = [PSCustomObject]@{
                # Parsed JSON content from the selected file
                Property1 = "value1"
                Property2 = "value2"
                ...
            }
        }
        ```

        ERROR HANDLING:
        - Folder doesn't exist: Get-JSONFileList will throw an error
        - No JSON files found: Throws DirectoryNotFoundException
        - Invalid JSON: Get-JSONFileList parsing will fail
        - FilterFunction not found: PowerShell will throw CommandNotFoundException
        - User cancels selection: Returns DialogResult.Action.Exit or Back

        JSONC SUPPORT:
        The default Filter includes "*.jsonc" which supports JSON with comments.
        This is useful for configuration files that need inline documentation.

        COMMON USE CASES:
        - Environment configuration selection (dev, test, prod)
        - Deployment profile selection
        - Template selection
        - Connection string selection
        - User preference selection
        - API endpoint configuration
        - Database schema selection

        EXAMPLE JSON FILE STRUCTURE:
        ```json
        {
            "Description": "Production Environment",
            "Environment": "Production",
            "ServerUrl": "https://api.prod.example.com",
            "ApiKey": "prod-key-12345",
            "MaxRetries": 3
        }
        ```

        COMPARISON WITH OTHER FUNCTIONS:
        - Select-CLIDialogJsonFile: Specialized for JSON file selection (this function)
        - Select-CLIDialogObjectInArray: Generic object array selection
        - Find-Object: Search-based object selection
        - Get-ChildItem + Select: Manual file selection without JSON parsing

        CHANGELOG:

        Version 1.1.0 - 2024-09-21 - Loïc Ade
            - Added Filter parameter to filter files in JsonFolder
            - Support for multiple file patterns (*.json, *.jsonc)

        Version 1.0.0 - Initial Release
            - First release
            - JSON file scanning and parsing
            - Interactive selection dialog
            - Auto-selection for single file
            - Custom filter function support
            - Display selected item option
            - Customizable columns and sorting
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$JsonFolder,
        [string[]]$JsonColumn = "Description",
        [string[]]$Sort = "Description",
        [string]$SelectHeaderMessage = "Please select an item:",
        [System.ConsoleColor]$HeaderColor = (Get-Host).UI.RawUI.ForegroundColor,
        [AllowNull()]
        [string]$FooterMessage = "Please type item number",
        [System.ConsoleColor]$FooterColor = (Get-Host).UI.RawUI.ForegroundColor,
        [string]$ErrorMessage,
        [string]$FilterFunction,
        $FilteredValue,
        [switch]$AlwaysAskUser,
        [string[]]$Filter = @("*.json", "*.jsonc"),
        [System.ConsoleColor]$SeparatorColor = (Get-Host).UI.RawUI.ForegroundColor,
        [switch]$HeaderTextInSeparator,
        [switch]$DisplaySelectedItem,
        [string]$SelectedItemText = "Selected item:"
    )
    $arrayJson = Get-JSONFileList -JsonFolder $JsonFolder -JsonColumn $JsonColumn -Filter $Filter
    if ($filterFunction) {
        $arrayJson = $(&$filterFunction $arrayJson $filteredValue)
    }
    if ($arrayJson.Count -eq 0) {
        throw [System.IO.DirectoryNotFoundException] $errorMessage
    }
    $selectedJson = if ($AlwaysAskUser.IsPresent -or ($arrayJson.Count -gt 1)) {
        Select-CLIDialogObjectInArray -Objects $arrayJson -SelectedColumns $JsonColumn -Sort $Sort -SelectHeaderMessage $SelectHeaderMessage -FooterMessage $FooterMessage -HeaderColor $HeaderColor -FooterColor $FooterColor -HeaderTextInSeparator:$HeaderTextInSeparator -SeparatorColor $SeparatorColor
    } else { #$arrayJson.Count -eq 1
        Select-CLIDialogObjectInArray -Objects $arrayJson -SelectedColumns $JsonColumn -Sort $Sort -SelectHeaderMessage $SelectHeaderMessage -FooterMessage $FooterMessage -HeaderColor $HeaderColor -FooterColor $FooterColor -HeaderTextInSeparator:$HeaderTextInSeparator -SeparatorColor $SeparatorColor -AutoSelectWhenOneItem
    }
    if ($DisplaySelectedItem) {
        Write-Host (Set-StringFormat $SelectedItemText -Underline)
        Format-TableCustom -InputObject $selectedJson.Value -Property $JsonColumn -HeaderColor Green
        Write-Host ""
    }
    return $selectedJson
}