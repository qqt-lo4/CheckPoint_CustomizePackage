# PSSomeCLIThings

A PowerShell module for building interactive CLI interfaces: dialog system with forms, menus, console formatting, string utilities, and process helpers.

## Features

### Dialog System
Build interactive CLI dialogs with textboxes, buttons, checkboxes, radio buttons, and more. See the [full Dialog documentation](Dialog/DIALOG.md) for architecture details, component reference, patterns, and examples.

#### Base Components

| Function | Description |
|---|---|
| `New-CLIDialog` | Main orchestrator that assembles a complete interactive dialog from rows of controls. Handles keyboard navigation, focus management, validation, and result collection. |
| `New-CLIDialogButton` | Creates an interactive button control with support for value selection, action types (Yes, No, Cancel, Exit, Back, etc.), scriptblock execution, and keyboard shortcuts via "&" notation. |
| `New-CLIDialogCheckBox` | Creates a checkbox control for independent multi-selection. Displays as `[x]`/`[ ]` with keyboard shortcut support and custom object association. |
| `New-CLIDialogRadioButton` | Creates a radio button control for single selection within a group. Displays as `(x)`/`( )` with automatic mutual exclusion. |
| `New-CLIDialogTextBox` | Creates an editable text input field with cursor navigation, regex or scriptblock validation, password masking, SecureString support, and visual error feedback. |
| `New-CLIDialogObjectsRow` | Container row that groups multiple controls in horizontal or vertical layouts with keyboard navigation, labeled headers, and radio button mutual exclusion. |
| `New-CLIDialogProperty` | Read-only property display element showing labeled information with regex pattern highlighting and aligned layouts. |
| `New-CLIDialogText` | Text display element supporting static or dynamic content via scriptblock, multi-line text, and custom colors. |
| `New-CLIDialogSeparator` | Visual separator line with customizable character, pagination indicators, centered text, and "press any key" functionality. |
| `New-CLIDialogSpace` | Horizontal space element for creating gaps between controls in a row. |
| `New-CLIDialogTableItems` | Generates dialog rows displaying objects in a formatted table layout as checkboxes or buttons. |
| `New-DialogResultAction` | Creates a structured DialogResult object for action-type button results (Yes, No, Cancel, Validate, Exit, Back, etc.). |
| `New-DialogResultScriptblock` | Creates a structured DialogResult object for scriptblock-type button results. |
| `New-DialogResultValue` | Creates a structured DialogResult object for value/object selection button results. |

#### High-Level Dialogs

| Function | Description |
|---|---|
| `Invoke-CLIDialog` | Primary entry point for displaying and interacting with dialogs. Supports simple display, validation loops, and execution mode for nested menus/wizards. |
| `Invoke-YesNoCLIDialog` | Convenience function for Yes/No/Cancel confirmation dialogs with customizable button text, layouts, and keyboard shortcuts. |
| `Find-Object` | Dynamic interactive search dialog with real-time filtering, paginated results, single/multi-select modes, and confirmation support. |
| `Edit-Hashtable` | Interactive dialog for editing hashtable values with labeled textboxes for each key-value pair. |
| `Read-CLIDialogConnectionInfo` | Prompts for connection information (server, port, username, password) with regex validation and credential reuse support. |
| `Read-CLIDialogCredential` | Simplified credential prompt (username/password) returning a PSCredential object. Wrapper around Read-CLIDialogConnectionInfo. |
| `Read-CLIDialogHashtable` | Dynamic form dialog from a hashtable schema with per-field regex validation and optional Cancel button. |
| `Read-CLIDialogIP` | IP address input dialog with IPv4 validation and optional CIDR mask support. |
| `Read-CLIDialogNumericValue` | Numeric value input dialog with integer/decimal support, min/max range validation, and default values. |
| `Read-CLIDialogValidatedValue` | Generic single-field validation dialog accepting regex or scriptblock validation. Building block for specialized input functions. |
| `Select-CLIDialogCSVFile` | Interactive CSV file selector with header validation and content preview. |
| `Select-CLIDialogJsonFile` | JSON file selector that parses and displays file metadata with optional filtering and auto-selection. |
| `Select-CLIDialogObjectInArray` | Comprehensive paginated object selection dialog with single/multi-select, confirmation, custom menu items, and navigation. |
| `Select-CLIFileFromFolder` | File selector from a folder with recursive scanning, manual path entry, and file validation. |

### Menu Builder
Create interactive navigable menus with sub-menus, actions, and scriptblock execution.

| Function | Description |
|---|---|
| `Invoke-Menu` | Displays and executes an interactive menu with nested sub-menu support, scriptblock execution, and depth tracking. |
| `New-Menu` | Creates a menu object with items, sub-menus, pagination, keyboard shortcuts, and enter/exit actions. |
| `New-MenuItem` | Creates an executable menu item that runs a scriptblock when selected, with keyboard shortcut and recommended flag. |
| `New-MenuAction` | Creates a menu action button for navigation (Back, Exit, Yes, No, Cancel, Validate, Previous, Next, Refresh, etc.). |
| `New-MenuRow` | Creates a grouped menu row with a header label and content items for organizing related elements. |

### Console Formatting
Custom formatting utilities for tables and lists with color support.

| Function | Description |
|---|---|
| `Format-TableCustom` | Advanced table formatter with custom column widths, colored headers, content truncation, ANSI color support, and string output mode. |
| `Format-CustomHeaderTable` | Formats objects as a table with colored and optionally underlined header row. |
| `Format-ListCustom` | Custom list formatter (like `Format-List`) with colored property names, alignment control, and regex-based value highlighting. |
| `Format-PropertyToList` | Renders a single property-value pair in list format with colored output and multi-value array support. |
| `Format-ArrayHashtable` | Converts an array of hashtables into PSCustomObjects and displays as a formatted table. |
| `Get-ColumnFormat` | Analyzes object properties to determine optimal column formatting metadata (alignment, width, type). |

### String Utilities
ANSI text formatting and underline support.

| Function | Description |
|---|---|
| `Set-StringFormat` | Applies ANSI text formatting (underline, bold, italic, blink) to a string or substring with support for ranges and single positions. |
| `Set-StringUnderline` | Convenience wrapper for `Set-StringFormat` that applies underline formatting. |

### Other Utilities
Miscellaneous CLI helper functions.

| Function | Description |
|---|---|
| `Write-ColoredString` | Writes a string to the console with regex-based color highlighting for matching and non-matching portions. |
| `Write-Separator` | Writes a separator line with optional pagination indicators (arrows, page numbers). |
| `Invoke-Pause` | Pauses script execution until a key is pressed, with customizable message and replacement behavior. |
| `Invoke-Process` | Launches an external process capturing stdout, stderr, and exit code with configurable output levels. |
| `Convert-ConsoleColorToInt` | Converts ConsoleColor enum values to ANSI escape sequence numeric codes (foreground/background). |
| `Wait-ProgressBar` | Displays a countdown progress bar for a specified duration in seconds. |
| `Read-Array` | Reads a multi-line list from user input via Read-Host with optional regex-based grouping. |

## Requirements

- **PowerShell** 5.1 or later
- **Windows** operating system (uses `System.Console` and `Write-Host` for rendering)

## Installation

```powershell
# Clone or copy the module to a PowerShell module path
Copy-Item -Path ".\PSSomeCLIThings" -Destination "$env:USERPROFILE\Documents\PowerShell\Modules\PSSomeCLIThings" -Recurse

# Or import directly
Import-Module ".\PSSomeCLIThings\PSSomeCLIThings.psd1"
```

## Quick Start

### Simple Yes/No dialog
```powershell
$answer = Invoke-YesNoCLIDialog -Message "Do you want to continue?" -YN
# Returns "Yes" or "No"
```

### Build a form dialog
```powershell
# Collect user information via a hashtable form
$schema = [ordered]@{
    Name     = @{ Regex = "^.{2,50}$"; Text = "" }
    Email    = @{ Regex = "^[\w.]+@[\w.]+\.\w+$"; Text = "" }
    Age      = @{ Regex = "^\d{1,3}$"; Text = "" }
}
$result = Read-CLIDialogHashtable -Properties $schema -Header "Please enter your information"
```

### Interactive object selection
```powershell
# Select a service from a paginated list
$service = Get-Service | Select-CLIDialogObjectInArray -SelectedColumns Name, Status, DisplayName `
                                                       -Sort Name `
                                                       -ItemsPerPage 15
```

### Build a menu
```powershell
$menu = New-Menu -Text "Main Menu" -Content @(
    New-MenuItem -Text "&List Services" -Content { Get-Service | Format-Table }
    New-MenuItem -Text "&Disk Usage" -Content { Get-PSDrive -PSProvider FileSystem | Format-Table }
    New-Menu -Text "&Sub Menu" -Content @(
        New-MenuItem -Text "&Option 1" -Content { Write-Host "Option 1 selected" }
        New-MenuItem -Text "&Option 2" -Content { Write-Host "Option 2 selected" }
    )
)
Invoke-Menu -Menu $menu
```

### Custom formatted table
```powershell
Get-Process | Select-Object -First 10 | Format-TableCustom -Property Name, Id, CPU -HeaderColor Cyan -HeaderUnderline
```

### Colored string output
```powershell
"Error: File not found at C:\Temp\file.txt" | Write-ColoredString -Pattern "Error" -MatchForegroundColor Red
```

## Module Structure

```
PSSomeCLIThings/
├── PSSomeCLIThings.psd1          # Module manifest
├── PSSomeCLIThings.psm1          # Module loader (dot-sources all .ps1 files)
├── README.md                     # This file
├── LICENSE                       # PolyForm Noncommercial License 1.0.0
├── Dialog/
│   ├── Base/                     # Core dialog building blocks (14 functions)
│   └── *.ps1                     # High-level dialog functions (14 functions)
├── Format/                       # Console formatting utilities (6 functions)
├── Menu/                         # Menu builder (5 functions)
├── Other/                        # Miscellaneous CLI helpers (7 functions)
└── String/                       # String formatting utilities (2 functions)
```

## Author

**Loïc Ade**

## License

This project is licensed under the [PolyForm Noncommercial License 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/). See the [LICENSE](LICENSE) file for details.

In short:
- **Non-commercial use only** — You may use, modify, and distribute this software for any non-commercial purpose.
- **Attribution required** — You must include a copy of the license terms with any distribution.
- **No warranty** — The software is provided as-is.
