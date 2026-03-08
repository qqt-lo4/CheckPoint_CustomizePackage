function Select-CLIFileFromFolder {
    <#
    .SYNOPSIS
        Displays an interactive dialog to select a file from a folder with optional filtering and custom actions.

    .DESCRIPTION
        This function scans a folder for files matching specified filter patterns and displays an interactive
        selection dialog. It provides flexible options including recursive scanning, custom column display,
        manual file path entry, and "no file" selection. The function returns a FileInfo object for the
        selected file or a DialogResult for special actions.

        Key features:
        - File filtering with wildcards (single pattern or array of patterns)
        - Recursive or non-recursive folder scanning
        - Custom column display (folder name or full path)
        - "Select another file" option with manual path entry
        - "Do not select a file" option for optional file scenarios
        - "Exit" option for cancellation
        - Automatic quote removal from pasted paths
        - Empty folder handling with custom message
        - Path validation for manually entered files

        The workflow:
        1. Scan Path for files matching Filter patterns
        2. Display selection dialog with found files
        3. Optional: Allow manual file path entry
        4. Validate manually entered paths
        5. Return selected file or action result

    .PARAMETER Path
        Path to the folder to scan for files. This parameter is mandatory.
        The folder must exist or Get-ChildItem will return no results.
        Example: "C:\Logs", ".\Config", "D:\Documents"

    .PARAMETER Filter
        File filter pattern(s) to match files in the folder. This parameter is mandatory.
        Supports single pattern or array of patterns.

        Single pattern (uses -Filter parameter of Get-ChildItem):
        Example: "*.log", "report*.txt"

        Array of patterns (uses -Include parameter of Get-ChildItem):
        Example: @("*.log", "*.txt"), @("*.json", "*.jsonc", "*.config")

    .PARAMETER ShowFile
        Switch parameter. When set, displays the full file path (FullName property) instead of
        just the folder name. Useful when files have the same name in different folders or when
        users need to see the complete path.

    .PARAMETER AllowOtherFile
        Switch parameter. When set, adds an "Select Another File" button that allows users to
        manually enter a file path. The path is validated and must point to an existing file.
        Supports paths with or without quotes (quotes are automatically removed).

    .PARAMETER AllowNoFile
        Switch parameter. When set, adds a "Do not select a file" button that returns a
        DialogResult.Action.DoNotSelect result. Useful for optional file selection scenarios.

    .PARAMETER AllowExit
        Switch parameter. When set, adds an "Exit this menu" button that returns a
        DialogResult.Action.Exit result. Allows users to cancel the operation.

    .PARAMETER SelectHeaderMessage
        Header message displayed at the top of the selection dialog.
        Default: "Please select an item:"

    .PARAMETER ColumnName
        Name of the custom column to display when ShowFile is not set. The column shows the
        parent directory name of each file. Default: "Folder Name"
        Example: "Location", "Directory", "Source Folder"

    .PARAMETER HeaderColor
        Color of the header message text. Default: Current console foreground color

    .PARAMETER SeparatorColor
        Color of the separator lines in the dialog. Default: Current console foreground color

    .PARAMETER OtherFilePromptText
        Prompt text displayed when user selects "Select Another File" option.
        Default: "Please enter a file path"
        Example: "Enter custom log file path:"

    .PARAMETER Recurse
        Switch parameter. When set, scans the folder and all subfolders recursively.
        Without this switch, only the top-level folder is scanned.

    .PARAMETER EmptyArrayMessage
        Message displayed when no files are found matching the filter.
        Default: "No items in array"
        Example: "No log files found in the specified folder"

    .PARAMETER ItemsPerPage
        Number of items to display per page in the selection dialog.
        Default: 8
        Example: 10, 15, 20

    .OUTPUTS
        Returns one of the following based on user selection:

        FileInfo object: When a file is selected (from list or manual entry)
        - Properties: FullName, Directory, Name, Extension, Length, LastWriteTime, etc.

        DialogResult.Action.Other: When "Select Another File" is chosen and file is entered
        - .Value contains the FileInfo object for the manually entered file

        DialogResult.Action.DoNotSelect: When "Do not select a file" is chosen
        - Indicates user opted not to select any file

        DialogResult.Action.Exit: When "Exit this menu" is chosen
        - Indicates user cancelled the operation

    .EXAMPLE
        $logFile = Select-CLIFileFromFolder -Path "C:\Logs" -Filter "*.log"
        if ($logFile) {
            Get-Content $logFile.FullName
        }

        Selects a log file from a folder and displays its content.

    .EXAMPLE
        $result = Select-CLIFileFromFolder -Path ".\Reports" `
                                          -Filter @("*.pdf", "*.docx") `
                                          -ShowFile `
                                          -Recurse

        Scans for PDF and Word documents recursively, showing full paths.

    .EXAMPLE
        $result = Select-CLIFileFromFolder -Path "C:\Config" `
                                          -Filter "*.json" `
                                          -AllowOtherFile `
                                          -AllowNoFile `
                                          -OtherFilePromptText "Enter custom config file:"

        Allows selecting from folder, entering custom path, or choosing no file.

    .EXAMPLE
        $file = Select-CLIFileFromFolder -Path "D:\Backups" `
                                        -Filter "backup_*.zip" `
                                        -SelectHeaderMessage "Select backup to restore:" `
                                        -ColumnName "Backup Location" `
                                        -AllowExit

        Custom header, column name, and exit option for backup selection.

    .EXAMPLE
        $result = Select-CLIFileFromFolder -Path ".\Templates" `
                                          -Filter @("*.xml", "*.json") `
                                          -Recurse `
                                          -ShowFile `
                                          -EmptyArrayMessage "No template files found"

        Recursive scan with custom empty message and full path display.

    .NOTES
        Author: Loïc Ade
        Created: 2024-09-16
        Version: 1.2.0

        This function is designed for scenarios where users need to select a file from a folder
        interactively, with options for manual path entry and optional file selection.

        FILTER PARAMETER BEHAVIOR:
        - Single pattern (string): Uses Get-ChildItem -Filter (faster, simpler wildcards)
        - Array of patterns: Uses Get-ChildItem -Include (supports multiple patterns)

        The -Include parameter requires -Recurse or -Path with wildcard to work properly,
        which is why the function handles arrays differently.

        GET-CHILDITEM ERROR HANDLING:
        The function uses -ErrorAction SilentlyContinue on Get-ChildItem, which means:
        - Non-existent paths: Returns empty array (shows EmptyArrayMessage)
        - Access denied: Silently skips inaccessible files/folders
        - No matching files: Returns empty array

        COLUMN DISPLAY:
        Two display modes:
        1. ShowFile NOT set: Shows ColumnName with parent directory name
        2. ShowFile set: Shows FullName with complete file path

        When ShowFile is not set, the function adds a NoteProperty called ColumnName
        to each file object containing the parent directory name.

        MANUAL FILE PATH ENTRY:
        When AllowOtherFile is set and user selects "Select Another File":
        1. Prompts user for file path
        2. Automatically removes surrounding quotes if present (e.g., "C:\file.txt" → C:\file.txt)
        3. Validates path points to an existing file (not folder)
        4. Repeats prompt if validation fails
        5. Returns FileInfo object when valid path is entered

        PATH QUOTE REMOVAL:
        The function handles paths like: "C:\Program Files\file.txt"
        Windows Explorer and many apps copy paths with quotes, which are automatically removed.

        RESULT TYPE DETECTION:
        To handle different result types:
        ```powershell
        $result = Select-CLIFileFromFolder -Path $path -Filter $filter -AllowNoFile -AllowExit

        switch ($result.PSTypeNames[0]) {
            "DialogResult.Action.DoNotSelect" {
                Write-Host "User chose not to select a file"
            }
            "DialogResult.Action.Exit" {
                Write-Host "User exited"
                return
            }
            "DialogResult.Action.Other" {
                # Manually entered file
                $file = $result.Value
            }
            default {
                # Direct file selection from list
                $file = $result.Value
            }
        }
        ```

        ITEMS PER PAGE:
        The function displays a configurable number of items per page (default: 8).
        This can be adjusted via the ItemsPerPage parameter to suit different screen sizes
        and user preferences.

        FOOTER MESSAGE:
        The footer is explicitly set to $null to hide the "Please type item number" message,
        creating a cleaner interface focused on file selection.

        COMMON USE CASES:
        - Log file selection for analysis
        - Configuration file selection
        - Backup file selection for restore
        - Template file selection
        - Report file selection
        - Script file selection for execution
        - Import file selection for data processing
        - Certificate file selection

        EXAMPLE FILTER PATTERNS:
        ```powershell
        # Single extension
        -Filter "*.log"

        # Multiple extensions
        -Filter @("*.log", "*.txt")

        # Specific prefix
        -Filter "backup_*.zip"

        # Complex pattern
        -Filter "report_2024*.pdf"

        # Multiple patterns
        -Filter @("*.json", "*.jsonc", "*.config")
        ```

        COMPARISON WITH OTHER FUNCTIONS:
        - Select-CLIFileFromFolder: Specialized for file selection with filtering (this function)
        - Select-CLIDialogJsonFile: Specialized for JSON files with content parsing
        - Select-CLIDialogObjectInArray: Generic object selection
        - Get-ChildItem | Out-GridView: GUI-based file selection (not pure CLI)

        ERROR SCENARIOS:
        - Path doesn't exist: Shows EmptyArrayMessage
        - No files match filter: Shows EmptyArrayMessage
        - Access denied to folder: Silently skips, may show EmptyArrayMessage
        - Invalid manual path: Repeats prompt with red error message
        - User cancels manual entry: Needs Ctrl+C (no built-in cancel for Read-Host)

        CHANGELOG:

        Version 1.2.0 - 2026-03-08 - Loïc Ade
            - Added AllowBack parameter to display a Back button

        Version 1.1.0 - 2025-11-22 - Loïc Ade
            - Added ItemsPerPage parameter to allow configurable number of items per page

        Version 1.0.0 - 2024-09-16 - Loïc Ade
            - Initial release
            - File filtering with single or multiple patterns
            - Recursive folder scanning
            - Custom column display (folder name or full path)
            - Manual file path entry with validation
            - Optional "no file" selection
            - Optional exit button
            - Automatic quote removal from paths
            - Empty folder handling
            - Integration with Select-CLIObjectInArray
            - 8 items per page (default)
            - Custom header and separator colors
    #>
    Param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string[]]$Filter,
        [switch]$ShowFile,
        [switch]$AllowOtherFile,
        [switch]$AllowNoFile,
        [switch]$AllowBack,
        [switch]$AllowExit,
        [string]$SelectHeaderMessage = "Please select an item:",
        [string]$ColumnName = "Folder Name",
        [System.ConsoleColor]$HeaderColor = (Get-Host).UI.RawUI.ForegroundColor,
        [System.ConsoleColor]$SeparatorColor = (Get-Host).UI.RawUI.ForegroundColor,
        [string]$OtherFilePromptText = "Please enter a file path",
        [switch]$Recurse,
        [string]$EmptyArrayMessage = "No items in array",
        [int]$ItemsPerPage = 8
    )
    # Build menu items
    $aItems = if ($Filter) {
        foreach ($sFilter in $Filter) {
            Get-ChildItem -Path $Path -Filter $sFilter -Recurse:$Recurse -ErrorAction SilentlyContinue
        }
    } else {
        Get-ChildItem -Path $Path -Recurse:$Recurse -ErrorAction SilentlyContinue
    } 
    $sColumn = if ($ShowFile) {
        "FullName"
    } else {
        $ColumnName
    }
    $aItems = $aItems | Sort-Object -Property $sColumn

    if ($sColumn -eq $ColumnName) {
        $aItems | ForEach-Object {
            if ($ColumnName -inotin $_.PSObject.Properties.name) {
                $_ | Add-Member -NotePropertyName $ColumnName -NotePropertyValue $_.Directory.Name
            }
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
        }
    }
    if ($AllowNoFile) {
        $aOtherMenuItems += New-CLIDialogButton -DoNotSelect -Text "Do &not select a file"
    }
    if ($AllowBack) {
        $aOtherMenuItems += New-CLIDialogButton -Back -Text "&Back"
    }
    if ($AllowExit) {
        $aOtherMenuItems += New-CLIDialogButton -Exit -Text "&Exit"
    }
    $hSelectObjectArgs = @{
        Objects = $aItems
        SelectedColumns = $sColumn
        SelectHeaderMessage = $SelectHeaderMessage
        OtherMenuItems = $aOtherMenuItems
        HeaderTextInSeparator = $true
        FooterMessage = $null
        SeparatorColor = $SeparatorColor
        HeaderColor = $HeaderColor
        ItemsPerPage = $ItemsPerPage
        EmptyArrayMessage = $EmptyArrayMessage
    }
    if ($aOtherMenuItems.Count -gt 0) {
        $hSelectObjectArgs.OtherMenuItemsInvisibleHeader = $true
    }
    return Select-CLIDialogObjectInArray @hSelectObjectArgs
}