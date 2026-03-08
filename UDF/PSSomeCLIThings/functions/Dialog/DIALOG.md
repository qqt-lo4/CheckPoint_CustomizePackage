# CLI Dialog Framework

A comprehensive PowerShell framework for building fully interactive CLI dialogs with textboxes, buttons, checkboxes, radio buttons, separators, and more. Assemble custom forms, menus, and selection dialogs entirely in the terminal.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Base Components Reference](#base-components-reference)
  - [New-CLIDialog](#new-clidialog)
  - [New-CLIDialogButton](#new-clidialogbutton)
  - [New-CLIDialogTextBox](#new-clidialogtextbox)
  - [New-CLIDialogCheckBox](#new-clidialogcheckbox)
  - [New-CLIDialogRadioButton](#new-clidialogradiobutton)
  - [New-CLIDialogObjectsRow](#new-clidialogobjectsrow)
  - [New-CLIDialogText](#new-clidialogtext)
  - [New-CLIDialogProperty](#new-clidialogproperty)
  - [New-CLIDialogSeparator](#new-clidialogseparator)
  - [New-CLIDialogSpace](#new-clidialogspace)
  - [New-CLIDialogTableItems](#new-clidialogtableitems)
- [Result Types](#result-types)
  - [DialogResult.Value](#dialogresultvalue)
  - [DialogResult.Action](#dialogresultaction)
  - [DialogResult.Scriptblock](#dialogresultscriptblock)
- [Running a Dialog](#running-a-dialog)
  - [Invoke-CLIDialog](#invoke-clidialog)
- [High-Level Dialog Functions](#high-level-dialog-functions)
  - [Invoke-YesNoCLIDialog](#invoke-yesnoclidialog)
  - [Edit-Hashtable](#edit-hashtable)
  - [Read-CLIDialogHashtable](#read-clidialoghashtable)
  - [Read-CLIDialogValidatedValue](#read-clidialogvalidatedvalue)
  - [Read-CLIDialogNumericValue](#read-clidialognumericvalue)
  - [Read-CLIDialogIP](#read-clidialogip)
  - [Read-CLIDialogConnectionInfo](#read-clidialogconnectioninfo)
  - [Read-CLIDialogCredential](#read-clidialogcredential)
  - [Find-Object](#find-object)
  - [Select-CLIDialogObjectInArray](#select-clidialogobjectinarray)
  - [Select-CLIDialogCSVFile](#select-clidialogcsvfile)
  - [Select-CLIDialogJsonFile](#select-clidialogjsonfile)
  - [Select-CLIFileFromFolder](#select-clifilefromfolder)
- [Patterns and Recipes](#patterns-and-recipes)
- [Keyboard Navigation](#keyboard-navigation)

---

## Overview

The Dialog framework lets you build interactive terminal UIs entirely in PowerShell. Instead of simple `Read-Host` prompts, you get:

- **Textboxes** with cursor navigation, inline validation (regex or scriptblock), password masking, and SecureString support
- **Buttons** with keyboard shortcuts, action types (Yes/No/Cancel/Validate/Exit/Back...), and scriptblock execution
- **Checkboxes** (`[x]`/`[ ]`) for independent multi-selection with custom object binding
- **Radio buttons** (`(x)`/`( )`) for mutually exclusive single-selection within a group
- **Separators** with pagination, centered text, and "press any key" support
- **Static text** and **properties** for display-only content with regex-based color highlighting
- **Table items** that convert object arrays into selectable rows

All components use consistent focus states with color inversion, keyboard shortcut support via `&` notation, and return structured `DialogResult` objects for clean result handling.

---

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                   Invoke-CLIDialog                       │
│           (Runtime engine: render loop + input)          │
├──────────────────────────────────────────────────────────┤
│                     New-CLIDialog                        │
│    (Orchestrator: assembles rows, manages focus,         │
│     keyboard dispatch, validation, result building)      │
├──────────────────────────────────────────────────────────┤
│                        ROWS                              │
│  ┌─────────────────────────────────────────────────┐     │
│  │  New-CLIDialogObjectsRow                        │     │
│  │  (Groups controls horizontally or vertically)   │     │
│  │  ┌──────┐ ┌────────┐ ┌──────┐ ┌───────┐         │     │
│  │  │Button│ │Checkbox│ │Radio │ │ Space │         │     │
│  │  └──────┘ └────────┘ └──────┘ └───────┘         │     │
│  └─────────────────────────────────────────────────┘     │
│  ┌──────────────┐ ┌──────────────┐ ┌─────────────┐       │
│  │   TextBox    │ │     Text     │ │  Separator  │       │
│  └──────────────┘ └──────────────┘ └─────────────┘       │
│  ┌──────────────┐ ┌──────────────┐                       │
│  │   Property   │ │  TableItems  │                       │
│  └──────────────┘ └──────────────┘                       │
├──────────────────────────────────────────────────────────┤
│                    RESULT TYPES                          │
│  DialogResult.Value  │  DialogResult.Action  │  .Script  │
└──────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Build** — Create individual controls, group them into rows, pass all rows to `New-CLIDialog`
2. **Run** — `Invoke-CLIDialog` (or `.Invoke()`) draws the dialog and processes keyboard input in a loop
3. **Return** — When a button is activated, a structured `DialogResult` object is returned
4. **Consume** — Use `switch -Wildcard` on `$result.PSTypeNames[0]` to handle different result types

### Row Classification

Rows are classified as **static** or **dynamic**:
- **Static rows** (Text, Property, Separator) are drawn once at the top
- **Dynamic rows** (TextBox, ObjectsRow with buttons/checkboxes/radiobuttons) are redrawn on every keypress

> **Important**: Once the first dynamic row is encountered, all subsequent rows (even static ones) are treated as dynamic.

---

## Quick Start

### A simple form with two fields and OK/Cancel

```powershell
# 1. Build the rows
$rows = @(
    New-CLIDialogText -Text "Please enter your information:" -AddNewLine

    New-CLIDialogTextBox -Header "Name" -Regex "^.{2,50}$" -FocusedPrefix "> " -Prefix "  "
    New-CLIDialogTextBox -Header "Email" -Regex "^[\w.]+@[\w.]+\.\w+$" -FocusedPrefix "> " -Prefix "  "

    New-CLIDialogObjectsRow -Row @(
        New-CLIDialogButton -Text "&OK" -Validate
        New-CLIDialogSpace -Length 3
        New-CLIDialogButton -Text "&Cancel" -Cancel
    )
)

# 2. Run the dialog with validation
$result = Invoke-CLIDialog -InputObject $rows -Validate -ErrorDetails

# 3. Handle the result
switch -Wildcard ($result.PSTypeNames[0]) {
    "DialogResult.Action.Validate" {
        $values = $result.DialogResult.Form.GetValue()
        Write-Host "Name: $($values.Name)"
        Write-Host "Email: $($values.Email)"
    }
    "DialogResult.Action.Cancel" {
        Write-Host "Cancelled"
    }
}
```

### A selection with checkboxes

```powershell
$services = Get-Service | Select-Object -First 10

$selectedItems = [ref]@()
$rows = @(
    New-CLIDialogSeparator -AutoLength -Text "Select services to restart" -ForegroundColor Cyan
    New-CLIDialogTableItems -Objects $services -Properties Name, Status -Checkbox `
                            -EnabledObjectsArray $selectedItems -EnabledObjectsUniqueProperty "Name"
    New-CLIDialogSeparator -AutoLength -ForegroundColor Cyan
    New-CLIDialogObjectsRow -Row @(
        New-CLIDialogButton -Text "&OK" -Validate
        New-CLIDialogButton -Text "&Cancel" -Cancel
    )
)

$dialog = New-CLIDialog -Rows $rows -SelectedObjectsArray $selectedItems -SelectedObjectsUniqueProperty "Name"
$result = Invoke-CLIDialog -InputObject $dialog
# $selectedItems.Value now contains the selected service objects
```

### Radio button selection

```powershell
$rows = @(
    New-CLIDialogText -Text "Choose output format:" -AddNewLine

    New-CLIDialogObjectsRow -Header "Format" -Row @(
        New-CLIDialogRadioButton -Text "&JSON" -Enabled $true -Object "json"
        New-CLIDialogRadioButton -Text "&XML" -Object "xml"
        New-CLIDialogRadioButton -Text "&CSV" -Object "csv"
    ) -MandatoryRadioButtonValue

    New-CLIDialogObjectsRow -Row @(
        New-CLIDialogButton -Text "&OK" -Validate
    )
)

$result = Invoke-CLIDialog -InputObject $rows
$format = $result.DialogResult.Form.GetValue().Format
# $format will be "json", "xml", or "csv"
```

---

## Base Components Reference

### New-CLIDialog

The main orchestrator that assembles a complete interactive dialog from rows of controls.

#### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `Rows` | `object[]` | *(mandatory)* | Array of row objects (text, textbox, row, separator, property, button, checkbox) |
| `EscapeObject` | `object` | Auto-detected Cancel button | Object returned on Escape key |
| `ValidateObject` | `object` | Auto-detected Validate button | Object returned on Enter key (when no button focused) |
| `RefreshObject` | `object` | Auto-detected Refresh button | Object returned on F5 key |
| `HiddenButtons` | `object[]` | — | Non-visible buttons activated via keyboard shortcuts (e.g., PageUp/PageDown) |
| `FocusedRow` | `int` | `0` | Zero-based index of initially focused row |
| `PauseAfterErrorMessage` | `bool` | `$false` | Pause after validation error display |
| `ValidationErrorMessage` | `string` | Auto-generated | Custom validation error message |
| `ValidationErrorDetails` | `bool` | `$false` | Show per-field error details |
| `SelectedObjectsArray` | `ref` | — | Reference to external array tracking checkbox selections |
| `SelectedObjectsUniqueProperty` | `string` | — | Property name for unique checkbox object matching |

#### Key Methods on the Returned Object

| Method | Description |
|---|---|
| `Invoke($KeepValues)` | Renders the dialog and waits for user interaction. Returns a `DialogResult`. If `$KeepValues` is `$false` (default), resets all fields first. |
| `InvokeValidate($KeepValues)` | Same as `Invoke()` but loops until `IsValidForm()` returns `$true` or the user cancels. |
| `GetValue($UseName)` | Returns an `[ordered]@{}` of all form values: textbox text, checkbox states, radio button selections. When `$UseName` is `$true`, uses control `.Name` as key instead of `.Header`. |
| `IsValidForm()` | Returns `$true` if all textboxes pass validation. |
| `GetErrors()` | Returns an `[ordered]@{}` of field name → error reason for invalid textboxes. |
| `Reset()` | Resets all controls to their original values. |
| `Draw()` | Renders the entire dialog (all rows). |
| `SetSeparatorLocation()` | Auto-aligns all textbox/row/property separators to the longest header. |

#### Auto-Detection

If `EscapeObject`, `ValidateObject`, or `RefreshObject` are not explicitly provided, the constructor scans all rows for the first button with `.Cancel`, `.Validate`, or `.Refresh` set to `$true`.

---

### New-CLIDialogButton

Creates an interactive button control with support for value selection, actions, scriptblock execution, and keyboard shortcuts.

#### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `Text` | `string` | *(mandatory)* | Button label. Use `&` before a character for automatic keyboard shortcut (e.g., `"&OK"` → O key, with O underlined) |
| `Keyboard` | `ConsoleKey` | Auto from `&` | Explicit keyboard shortcut |
| `Object` | `object` | — | Associated object or scriptblock returned on selection |
| `ObjectSelectedProperties` | `object` | — | Property subset for value results |
| `AddNewLine` | `switch` | — | Add newline after button |
| `NoSpace` | `switch` | — | Remove padding spaces around text |
| `Underline` | `int` | `-1` | Position of character to underline (overridden by `&` notation) |
| `Name` | `string` | — | Unique identifier |

**Action switches** (mutually exclusive parameter sets):
`-Yes`, `-No`, `-Cancel`, `-Back`, `-Exit`, `-Validate`, `-Previous`, `-Next`, `-Refresh`, `-Other`, `-DoNotSelect`, `-GoTo`

**Color parameters**: `BackgroundColor`, `ForegroundColor`, `FocusedBackgroundColor`, `FocusedForegroundColor`

#### ButtonType Logic

| Condition | ButtonType | Result |
|---|---|---|
| No action switch + `Object` is scriptblock | `"Scriptblock"` | → `DialogResult.Scriptblock` |
| No action switch + `Object` is anything else | `"Value"` | → `DialogResult.Value` |
| Action switch + `Object` is scriptblock | `"Action_Scriptblock"` | → `DialogResult.Action.<Name>` |
| Action switch + any other `Object` or null | `"Action"` | → `DialogResult.Action.<Name>` |

#### `&` Notation Example

```powershell
New-CLIDialogButton -Text "&Save"
# Renders: " Save " with S underlined
# Keyboard shortcut: S key
```

---

### New-CLIDialogTextBox

Creates an editable text input field with cursor navigation, validation, and password masking.

#### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `Header` | `string` | *(mandatory)* | Field label |
| `Text` | `object` | `""` | Initial value (string, int, or SecureString) |
| `Regex` | `string` | — | Regex validation pattern |
| `ValidationScript` | `scriptblock` | — | Custom validation scriptblock (receives text as parameter, must return truthy/falsy) |
| `ValidationErrorColor` | `ConsoleColor` | `Red` | Header color when validation fails |
| `ValidationErrorReason` | `string` | — | Custom error message for validation failure |
| `FieldNameInErrorReason` | `string` | — | Field name used in error messages |
| `PasswordChar` | `char` | — | Masking character (auto-set to `*` for SecureString input) |
| `ValueConvertFunction` | `scriptblock` | — | Converts text value on `GetValue()` (e.g., string → int) |
| `HeaderAlign` | `string` | `"Left"` | `"Left"` or `"Right"` |
| `HeaderSeparator` | `string` | `" : "` | Separator between header and input field |
| `SeparatorLocation` | `int` | — | Column position for alignment |
| `Prefix` / `FocusedPrefix` | `string` | — | Prefix before the field (e.g., `"  "` / `"> "`) |
| `Name` | `string` | `"textbox" + Header` | Unique identifier |

**Color parameters**: `TextForegroundColor`, `TextBackgroundColor`, `HeaderForegroundColor` (default Green), `HeaderBackgroundColor`, `FocusedTextForegroundColor`, `FocusedTextBackgroundColor`, `FocusedHeaderForegroundColor` (default Blue), `FocusedHeaderBackgroundColor`

#### Key Methods

| Method | Description |
|---|---|
| `GetValue()` | Returns: SecureString if `PasswordChar` is set, converted value if `ValueConvertFunction` is set, or plain text string |
| `IsValidText()` | Validates against `Regex` or `ValidationScript`. Uses caching for performance. |
| `Reset()` | Restores text to `OriginalText`, resets cursor to end |

#### Validation Modes

```powershell
# Regex validation
New-CLIDialogTextBox -Header "Port" -Regex "^\d{1,5}$"

# Scriptblock validation
New-CLIDialogTextBox -Header "Port" -ValidationScript {
    param($value)
    $port = $value -as [int]
    return ($port -ge 1 -and $port -le 65535)
}
```

> **Note**: If both `Regex` and `ValidationScript` are provided, `Regex` takes precedence.

#### Keyboard Shortcuts in TextBox

| Key | Action |
|---|---|
| Left/Right Arrow | Move cursor |
| Home / End | Jump to start / end |
| Backspace | Delete character before cursor |
| Delete | Delete character at cursor |
| Any printable character | Insert at cursor position |
| Up/Down/Tab/Enter/Escape | Passed to parent dialog |

---

### New-CLIDialogCheckBox

Creates a checkbox control (`[x]`/`[ ]`) for independent multi-selection.

#### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `Text` | `string` | *(mandatory)* | Label text (supports `&` for shortcut) |
| `Enabled` | `bool` | `$false` | Initial checked state |
| `Object` | `object` | — | Associated object (added/removed from dialog's `SelectedObjectsArray` on toggle) |
| `Keyboard` | `ConsoleKey` | Auto from `&` | Keyboard shortcut |
| `Name` | `string` | Auto | Unique identifier |
| `AddNewLine` | `switch` | — | Add newline after checkbox |
| `Underline` | `int` | `-1` | Character position to underline |
| `NoSpace` | `switch` | — | Remove padding spaces |

**Color parameters**: `BackgroundColor`, `ForegroundColor`, `FocusedBackgroundColor`, `FocusedForegroundColor`

#### Key Methods

| Method | Description |
|---|---|
| `ToggleValue()` | Flips `Enabled` state |
| `GetValue()` | Returns current `Enabled` boolean |
| `Reset()` | Restores to `OriginalEnabled` |

#### Object Association

When `Object` is set and the checkbox is toggled, the dialog's `SelectedObjectsArray` is automatically updated (objects are added/removed based on `SelectedObjectsUniqueProperty` matching).

---

### New-CLIDialogRadioButton

Creates a radio button control (`(x)`/`( )`) for single-selection within a group.

#### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `Text` | `string` | *(mandatory)* | Label text (supports `&` for shortcut) |
| `Enabled` | `bool` | `$false` | Initially selected |
| `Object` | `object` | — | Associated value returned by `GetValue()` on the parent row |
| `Keyboard` | `ConsoleKey` | Auto from `&` | Keyboard shortcut |
| `Name` | `string` | Auto | Unique identifier |
| `Underline` | `int` | `-1` | Character position to underline |

**Color parameters**: `BackgroundColor`, `ForegroundColor`, `FocusedBackgroundColor`, `FocusedForegroundColor`

#### Mutual Exclusion

Radio buttons must be placed inside a `New-CLIDialogObjectsRow`. The dialog constructor wires each radio button's `.Row` property to its parent row, enabling mutual exclusion:

- **Selecting** a radio button automatically deselects all siblings in the same row
- **Deselecting** is prevented when `MandatoryRadioButtonValue` is set on the parent row

#### Getting the Selected Value

```powershell
$values = $dialog.GetValue()
# For a row named "Format" with radio buttons:
$values.Format  # Returns the .Object of the selected radio button, or its text if no Object is set
```

---

### New-CLIDialogObjectsRow

Groups multiple interactive controls (buttons, checkboxes, radio buttons, spaces) in a horizontal or vertical layout.

#### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `Row` | `object[]` | *(mandatory)* | Array of controls to arrange |
| `FocusedItem` | `int` | `0` | Initially focused control index |
| `Header` | `string` | `""` | Label before row content (alias: `Text`) |
| `HeaderAlign` | `string` | `"Left"` | `"Left"` or `"Right"` |
| `HeaderSeparator` | `string` | `" : "` | Separator between header and content |
| `SeparatorLocation` | `int` | — | Column position for alignment |
| `Prefix` / `FocusedPrefix` | `string` | `""` | Prefix strings |
| `Name` | `string` | Auto | Unique identifier |
| `MandatoryRadioButtonValue` | `switch` | — | At least one radio button must remain selected |
| `InvisibleHeader` | `switch` | — | Reserve header space without displaying text |
| `Vertical` | `switch` | — | Stack controls vertically instead of horizontally |

**Color parameters**: `HeaderForegroundColor` (default Green), `HeaderBackgroundColor`, `FocusedHeaderForegroundColor` (default Blue), `FocusedHeaderBackgroundColor`

#### Layout Modes

**Horizontal** (default): Controls rendered left-to-right. Left/Right arrows navigate within the row. Up/Down arrows navigate between rows.

**Vertical** (`-Vertical`): Controls stacked top-to-bottom with indentation. Up/Down arrows navigate within the row.

```powershell
# Horizontal: [ Yes ] [ No ] [ Cancel ]
New-CLIDialogObjectsRow -Row @(
    New-CLIDialogButton -Text "&Yes" -Yes
    New-CLIDialogButton -Text "&No" -No
    New-CLIDialogButton -Text "&Cancel" -Cancel
)

# Vertical:
# ( ) Option A
# ( ) Option B
# ( ) Option C
New-CLIDialogObjectsRow -Row @(
    New-CLIDialogRadioButton -Text "Option &A" -Enabled $true
    New-CLIDialogRadioButton -Text "Option &B"
    New-CLIDialogRadioButton -Text "Option &C"
) -Vertical -MandatoryRadioButtonValue
```

---

### New-CLIDialogText

Creates a static or dynamic text display element.

#### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `Text` | `string` | — | Static text content. Supports `\n` for multi-line. |
| `TextFunction` | `scriptblock` | — | Dynamic text generator (evaluated at draw time, takes precedence over `Text`) |
| `TextFunctionArguments` | `object` | — | Arguments splatted to `TextFunction` |
| `AddNewLine` | `switch` | — | Add trailing newline |

**Color parameters**: `BackgroundColor`, `ForegroundColor`

#### Dynamic Text Example

```powershell
# Live-updating counter
$counter = [ref]@(0)
New-CLIDialogText -TextFunctionArguments @{ Counter = $counter } -TextFunction {
    param([ref]$Counter)
    return "Selected: $($Counter.Value.Count) items"
}
```

---

### New-CLIDialogProperty

Creates a read-only labeled property display with optional regex highlighting.

#### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `Header` | `string` | *(mandatory)* | Property label |
| `Text` | `string[]` | `""` | Value text (array for multi-line, each line auto-indented) |
| `Pattern` | `string` | — | Regex for color highlighting |
| `ColorGroups` | `string[]` | `@("0")` | Regex groups to colorize |
| `AllMatches` | `switch` | — | Highlight all matches |
| `HeaderAlign` | `string` | `"Left"` | `"Left"` or `"Right"` |
| `HeaderSeparator` | `string` | `" : "` | Separator string |
| `SeparatorLocation` | `int` | — | Column position for alignment |
| `Prefix` | `string` | `""` | Indentation prefix |
| `Name` | `string` | Auto | Unique identifier |

**Color parameters**: `TextForegroundColor`, `TextBackgroundColor`, `MatchTextForegroundColor` (default Blue), `MatchTextBackgroundColor`, `HeaderForegroundColor` (default Green), `HeaderBackgroundColor`

#### Example

```powershell
New-CLIDialogProperty -Header "Status" -Text "Running" -Pattern "Running" -MatchTextForegroundColor Green
# Displays: Status : Running   (with "Running" in green)
```

---

### New-CLIDialogSeparator

Creates a visual separator line with optional pagination and centered text.

#### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `Char` | `string` | `"-"` | Character for the line |
| `Length` | `int` | — | Fixed length (ParameterSet: `Length`) |
| `AutoLength` | `switch` | — | Auto-adjust to dialog width (ParameterSet: `Auto`, default) |
| `Text` | `string` | — | Centered text in the separator |
| `DrawPageNumber` | `switch` | — | Display page numbers |
| `DrawArrows` | `switch` | — | Display `<--` / `-->` navigation arrows |
| `PageNumber` | `int` | — | Current page (0-based input, stored as 1-based) |
| `PageCount` | `int` | — | Total pages |
| `LeftArrow` / `RightArrow` | `string` | `"<--"` / `"-->"` | Arrow text |
| `ForegroundColor` | `ConsoleColor` | Console fg | Line color |
| `PressKeyToContinue` | `switch` | — | Wait for keypress (one-time) |
| `PressKeyToContinueMessage` | `string` | `"Press any key..."` | Waiting message |
| `Prefix` | `string` | `""` | String prefix |

#### Examples

```powershell
# Simple separator
New-CLIDialogSeparator -AutoLength -ForegroundColor Blue
# Output: ────────────────────────────────────────

# With centered text
New-CLIDialogSeparator -AutoLength -Text "Results" -ForegroundColor Cyan
# Output: ──────────── Results ────────────────

# With pagination
New-CLIDialogSeparator -AutoLength -DrawPageNumber -DrawArrows -PageNumber 1 -PageCount 5 -ForegroundColor Yellow
# Output: <-- ─────────── 2 / 5 ─────────── -->
```

---

### New-CLIDialogSpace

Creates a horizontal spacer element used inside rows.

#### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `Length` | `int` | `1` | Number of space characters (minimum: 1) |
| `Color` | `ConsoleColor` | Console bg | Background color |

```powershell
# Add 5 spaces between buttons
New-CLIDialogObjectsRow -Row @(
    New-CLIDialogButton -Text "&OK" -Validate
    New-CLIDialogSpace -Length 5
    New-CLIDialogButton -Text "&Cancel" -Cancel
)
```

---

### New-CLIDialogTableItems

Generates dialog rows displaying objects in a formatted table layout. This is a **generator function** that returns an array of controls (a Text header + Button or Checkbox rows).

#### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `Objects` | `object[]` | *(mandatory)* | Array of objects to display |
| `Properties` | `object` | All properties | Property names or hashtable definitions for column formatting |
| `Checkbox` | `switch` | — | Render as checkboxes instead of buttons |
| `EnabledObjectsArray` | `ref` | — | Reference to pre-checked items array |
| `EnabledObjectsUniqueProperty` | `string` | — | Property for matching pre-selected objects |
| `Space` | `switch` | — | Add space prefix before rows |

#### What It Returns

An array containing:
1. **Element [0]**: `New-CLIDialogText` — the formatted table header row
2. **Elements [1..n]**: `New-CLIDialogCheckBox` (if `-Checkbox`) or `New-CLIDialogButton` — one per object, with `.Object` set to the source object

Each item's `Text` is a pre-formatted table line generated by `Format-TableCustom`.

---

## Result Types

All dialog interactions return a structured `DialogResult` object. Use `switch -Wildcard` on `$result.PSTypeNames[0]` for clean dispatching.

### DialogResult.Value

Returned when a value button is selected (no action switch used).

| Property | Description |
|---|---|
| `Type` | `"Value"` |
| `Value` | The selected object(s) |
| `SelectedProperties` | Property name array (or `$null`) |
| `DialogResult` | Full dialog state (`{ Button, Form, Type, ValidForm }`) |

**Script Method**: `ValueCount()` — Returns 0 if null, `Count` if array, 1 otherwise.

```powershell
switch -Wildcard ($result.PSTypeNames[0]) {
    "DialogResult.Value" {
        Write-Host "Selected: $($result.Value)"
    }
}
```

### DialogResult.Action

Returned when an action button is activated. The PSTypeName includes the action name for fine-grained matching.

| Property | Description |
|---|---|
| `Type` | `"Action"` |
| `Action` | Action name: `"Yes"`, `"No"`, `"Cancel"`, `"Validate"`, `"Exit"`, `"Back"`, `"Previous"`, `"Next"`, `"Refresh"`, `"Other"`, `"DoNotSelect"`, `"GoTo"` |
| `Value` | Optional associated value/scriptblock |
| `Depth` | Only for `"Back"` action (set to 0) |
| `DialogResult` | Full dialog state |

```powershell
switch -Wildcard ($result.PSTypeNames[0]) {
    "DialogResult.Action.Yes"      { Write-Host "Confirmed" }
    "DialogResult.Action.No"       { Write-Host "Declined" }
    "DialogResult.Action.Cancel"   { Write-Host "Cancelled" }
    "DialogResult.Action.Validate" {
        $formData = $result.DialogResult.Form.GetValue()
        # Process validated form data
    }
    "DialogResult.Action.*"        { Write-Host "Other action: $($result.Action)" }
}
```

### DialogResult.Scriptblock

Returned when a scriptblock button is selected. The scriptblock is **not** auto-executed — the caller must invoke it.

| Property | Description |
|---|---|
| `Type` | `"Scriptblock"` |
| `Value` | The scriptblock to execute |
| `DialogResult` | Full dialog state |

```powershell
if ($result.Type -eq "Scriptblock") {
    & $result.Value  # Execute the scriptblock
}
```

---

## Running a Dialog

### Invoke-CLIDialog

The runtime engine that renders a dialog and processes keyboard input.

#### Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `InputObject` | `object` | *(mandatory, pipeline)* | Dialog object or array of rows (auto-wrapped with `New-CLIDialog`) |
| `Validate` | `switch` | — | Loop until form is valid or user cancels |
| `ErrorDetails` | `switch` | — | Show per-field validation error details |
| `PauseAfterErrorMessage` | `switch` | — | Pause after showing errors |
| `CustomErrorMessage` | `string` | — | Custom error message |
| `Execute` | `switch` | — | Execution mode for menu systems (loops indefinitely, dispatches results) |
| `FunctionToRunOnValue` | `scriptblock` | — | Function called for `DialogResult.Value` results in Execute mode |
| `KeepValues` | `switch` | — | Preserve form values between invocations |
| `DontSpaceAfterDialog` | `switch` | — | Suppress blank line after dialog |

#### Three Invocation Modes

**Simple** (default): Display dialog once, return result.
```powershell
$result = Invoke-CLIDialog -InputObject $dialog
```

**Validate** (`-Validate`): Loop until form is valid or user cancels/exits.
```powershell
$result = Invoke-CLIDialog -InputObject $dialog -Validate -ErrorDetails
```

**Execute** (`-Execute`): Loop indefinitely, processing results (for menu systems, wizards).
```powershell
$result = Invoke-CLIDialog -InputObject $dialog -Execute -FunctionToRunOnValue {
    param($selectedItem)
    # Process item, return a DialogResult to continue the loop
}
```

#### Two Ways to Run a Dialog

```powershell
# Via Invoke-CLIDialog (recommended)
$result = Invoke-CLIDialog -InputObject $rows -Validate

# Direct invocation on the dialog object
$dialog = New-CLIDialog -Rows $rows
$result = $dialog.Invoke()
# or
$result = $dialog.InvokeValidate()
```

---

## High-Level Dialog Functions

These functions demonstrate the full power of the dialog framework. Each one assembles a complete dialog from base components.

### Invoke-YesNoCLIDialog

Simple Yes/No/Cancel confirmation dialog.

```powershell
# Yes/No only
$answer = Invoke-YesNoCLIDialog -Message "Delete all files?" -YN
# Returns: "Yes" or "No"

# Yes/No/Cancel with recommended default
$answer = Invoke-YesNoCLIDialog -Message "Save changes?" -Recommended "Yes"
# Returns: "Yes", "No", or "Cancel"

# Vertical layout with custom button text
$answer = Invoke-YesNoCLIDialog -Message "Choose action:" -YNC -Vertical `
    -YesButtonText "&Save" -NoButtonText "&Discard" -CancelButtonText "&Cancel"
```

### Edit-Hashtable

Interactive editor for hashtable values.

```powershell
$config = [ordered]@{
    Server   = "localhost"
    Port     = "8080"
    Database = "mydb"
}
$updated = Edit-Hashtable -Hashtable $config -HeaderQuestion "Edit connection settings:"
# Returns: updated ordered hashtable, or $null if cancelled
```

### Read-CLIDialogHashtable

Schema-driven form with per-field validation.

```powershell
$schema = [ordered]@{
    Username = @{ Regex = "^[a-zA-Z]\w{2,20}$"; Text = "" }
    Password = @{ Regex = "^.{8,}$"; Text = "" }
    Email    = @{ Regex = "^[\w.]+@[\w.]+\.\w+$"; Text = "" }
}
$result = Read-CLIDialogHashtable -Properties $schema `
    -Header "Create new account" `
    -AllowCancel
# Returns: hashtable with Username, Password, Email keys, or $null
```

### Read-CLIDialogValidatedValue

Single-field input with regex or scriptblock validation.

```powershell
# Regex validation
$name = Read-CLIDialogValidatedValue -Header "Enter server name" `
    -PropertyName "Server" -ValidationMethod "^[a-zA-Z][\w.-]+$"

# Scriptblock validation with default value
$port = Read-CLIDialogValidatedValue -Header "Enter port" `
    -PropertyName "Port" -DefaultValue 8080 `
    -ValidationMethod { param($v); $p = $v -as [int]; $p -ge 1 -and $p -le 65535 }
```

### Read-CLIDialogNumericValue

Specialized numeric input with range validation.

```powershell
# Integer with range
$port = Read-CLIDialogNumericValue -Header "Server Configuration" -PropertyName "Port" -Min 1 -Max 65535

# Decimal with default
$threshold = Read-CLIDialogNumericValue -Header "Alert Settings" -PropertyName "CPU %" `
    -Decimal -Min 0 -Max 100 -DefaultValue 80.5

# With cancel button
$count = Read-CLIDialogNumericValue -Header "Batch Size" -PropertyName "Items" -Min 1 -AllowCancel
```

### Read-CLIDialogIP

IP address input with optional CIDR mask.

```powershell
$ip = Read-CLIDialogIP                                    # Any IPv4
$ip = Read-CLIDialogIP -MandatoryMask                     # Must include /24 style mask
$ip = Read-CLIDialogIP -MaskForbidden -AllowCancel         # No CIDR allowed
```

### Read-CLIDialogConnectionInfo

Multi-field connection information dialog.

```powershell
$conn = Read-CLIDialogConnectionInfo -Server -Port -Credential `
    -DefaultServer "db.example.com" -DefaultPort 5432 `
    -HeaderAppName "PostgreSQL"
# Returns: PSCustomObject with Server, Port, Username, Password properties
# and a GetCredential() method
```

### Read-CLIDialogCredential

Simplified credential prompt.

```powershell
$cred = Read-CLIDialogCredential -Message "Enter admin credentials:"
# Returns: PSCredential or $null

$cred = Read-CLIDialogCredential -Credential $existingCred
# Asks: "Do you want to keep these credentials?"
```

### Find-Object

Dynamic search dialog with real-time filtering.

```powershell
$result = Find-Object -SearchFunction {
    param($InputString)
    Get-ADUser -Filter "Name -like '$InputString'" -Properties DisplayName, Department
} -SelectedColumns DisplayName, Department, SamAccountName `
  -MultiSelect -SelectedObjectsUniqueProperty SamAccountName `
  -Confirm -ConfirmMessage "Add %count% user(s)?"
```

### Select-CLIDialogObjectInArray

Paginated object selection with single or multi-select.

```powershell
# Single selection
$service = Get-Service | Select-CLIDialogObjectInArray `
    -SelectedColumns Name, Status, DisplayName `
    -Sort Name -ItemsPerPage 15

# Multi-selection with confirmation
$items = Get-Process | Select-CLIDialogObjectInArray `
    -SelectedColumns Name, Id, CPU `
    -MultiSelect -SelectedObjectsUniqueProperty Id `
    -Confirm -ConfirmMessage "Stop %count% process(es)?" `
    -ShowBackButton
```

### Select-CLIDialogCSVFile

CSV file selector with header validation and preview.

```powershell
$csv = Select-CLIDialogCSVFile -Folder "C:\Imports" `
    -Headers @("Name", "Email", "Department") `
    -PreviewLines 5
# Returns: DialogResult with CSV data, headers, and file path
```

### Select-CLIDialogJsonFile

JSON file selector from a folder.

```powershell
$config = Select-CLIDialogJsonFile -JsonFolder "C:\Configs" `
    -JsonColumn Description, Version `
    -DisplaySelectedItem
# Returns: DialogResult with parsed JSON content
```

### Select-CLIFileFromFolder

Generic file selector.

```powershell
$file = Select-CLIFileFromFolder -Path "C:\Scripts" -Filter "*.ps1" `
    -Recurse -AllowOtherFile -AllowNoFile
# Returns: FileInfo object or DialogResult for special actions
```

---

## Patterns and Recipes

### Pattern 1: Row Array Assembly

Build an array of rows, append components with `+=`, pass to `New-CLIDialog` or `Invoke-CLIDialog`.

```powershell
$rows = @()
$rows += New-CLIDialogText -Text "Header" -AddNewLine
$rows += New-CLIDialogTextBox -Header "Field1"
$rows += New-CLIDialogTextBox -Header "Field2"
$rows += New-CLIDialogObjectsRow -Row @(
    New-CLIDialogButton -Text "&OK" -Validate
    New-CLIDialogButton -Text "&Cancel" -Cancel
)

# Pass raw rows (auto-wrapped):
$result = Invoke-CLIDialog -InputObject $rows

# Or build dialog explicitly:
$dialog = New-CLIDialog -Rows $rows
$result = Invoke-CLIDialog -InputObject $dialog
```

### Pattern 2: Splatting Common Properties

```powershell
$commonProps = @{
    HeaderForegroundColor = [ConsoleColor]::Cyan
    FocusedHeaderForegroundColor = [ConsoleColor]::Yellow
    Prefix = "  "
    FocusedPrefix = "> "
    HeaderAlign = "Right"
}
$rows += New-CLIDialogTextBox @commonProps -Header "Server"
$rows += New-CLIDialogTextBox @commonProps -Header "Port" -Regex "^\d+$"
$rows += New-CLIDialogTextBox @commonProps -Header "Username"
```

### Pattern 3: Dialog Recreation for Pagination

For paginated/dynamic dialogs, rebuild the entire dialog each time instead of mutating.

```powershell
function New-MyPageDialog($Page, $Data) {
    $pageData = $Data | Select-Object -Skip ($Page * 10) -First 10
    return @(
        New-CLIDialogTableItems -Objects $pageData -Properties Name, Status
        New-CLIDialogSeparator -AutoLength -DrawPageNumber -PageNumber $Page -PageCount $totalPages
        New-CLIDialogObjectsRow -Row @(
            New-CLIDialogButton -Text "&Previous" -Previous
            New-CLIDialogButton -Text "&Next" -Next
        )
    )
}

$page = 0
while ($true) {
    $result = Invoke-CLIDialog -InputObject (New-MyPageDialog -Page $page -Data $allData)
    switch ($result.Action) {
        "Previous" { $page-- }
        "Next"     { $page++ }
        default    { return $result }
    }
}
```

### Pattern 4: Hidden Buttons for Extra Shortcuts

```powershell
$hidden = @(
    New-CLIDialogButton -Text "Prev" -Keyboard PageUp -Previous
    New-CLIDialogButton -Text "Next" -Keyboard PageDown -Next
)
$dialog = New-CLIDialog -Rows $rows -HiddenButtons $hidden
```

### Pattern 5: Dynamic Text with `[ref]` for Live Updates

```powershell
$selectedItems = [ref]@()

New-CLIDialogText -TextFunctionArguments @{ Items = $selectedItems } -TextFunction {
    param([ref]$Items)
    return "Selected: $($Items.Value.Count) items"
}
```

### Pattern 6: InvisibleHeader for Button Alignment

```powershell
# Buttons aligned under textboxes without a visible label
New-CLIDialogObjectsRow -Row @(
    New-CLIDialogButton -Text "&OK" -Validate
    New-CLIDialogButton -Text "&Cancel" -Cancel
) -InvisibleHeader
```

### Pattern 7: Accessing Form Values After Validation

```powershell
$result = Invoke-CLIDialog -InputObject $rows -Validate -ErrorDetails

if ($result.Action -eq "Validate") {
    # Method 1: GetValue() on the form
    $values = $result.DialogResult.Form.GetValue()
    $name = $values.Name
    $email = $values.Email

    # Method 2: GetValue($true) uses Name property instead of Header
    $values = $result.DialogResult.Form.GetValue($true)

    # Method 3: Access individual rows directly
    $nameRow = $result.DialogResult.Form.Rows | Where-Object { $_.Type -eq "textbox" -and $_.Header -eq "Name" }
    $nameValue = $nameRow.GetValue()
}
```

---

## Keyboard Navigation

### Global Keys (handled by New-CLIDialog)

| Key | Action |
|---|---|
| **Up Arrow** | Move focus to previous row |
| **Down Arrow** | Move focus to next row |
| **Tab** | Move focus to next row (wraps to first) |
| **Shift+Tab** | Move focus to previous row (wraps to last) |
| **Enter** | Activate focused button, or trigger `ValidateObject` |
| **Escape** | Trigger `EscapeObject` (usually Cancel) |
| **F5** | Trigger `RefreshObject` |
| **Space** | Toggle focused checkbox/radio button, or activate focused button |
| **Letter keys** | Activate button with matching `&` shortcut |

### Within ObjectsRow (Horizontal)

| Key | Action |
|---|---|
| **Left/Right Arrow** | Move focus between controls in the row |
| **Up/Down Arrow** | Passed to dialog (navigate between rows) |

### Within ObjectsRow (Vertical)

| Key | Action |
|---|---|
| **Up/Down Arrow** | Move focus between controls in the row |

### Within TextBox

| Key | Action |
|---|---|
| **Left/Right Arrow** | Move cursor |
| **Home / End** | Jump to start / end of text |
| **Backspace** | Delete character before cursor |
| **Delete** | Delete character at cursor |
| **Printable characters** | Insert at cursor position |

### Smart Row Navigation

When navigating between two button rows with Up/Down arrows, the dialog calculates the horizontal midpoint of the current button and maps it to the closest button in the destination row, preserving horizontal position.
