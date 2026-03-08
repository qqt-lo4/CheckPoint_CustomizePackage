function Select-CLIDialogObjectInArray {
    <#
    .SYNOPSIS
        Displays an interactive dialog to select one or more objects from an array with pagination.

    .DESCRIPTION
        This function is a comprehensive merger of Select-CLIObjectInArray and Select-CLIDialogObject,
        providing a unified interface for object selection with extensive customization options.

        Key features:
        - Automatic pagination with configurable items per page
        - Single or multi-selection modes with checkboxes
        - Optional confirmation dialogs with variable substitution
        - Complete UI customization (colors, messages, separators)
        - Keyboard navigation (PageUp/PageDown, letters for buttons)
        - Custom menu items with scriptblock support
        - Auto-selection for single items (optional)
        - Empty array handling with custom messages
        - Pre-selection support for multi-select mode
        - Sorting by property(ies)
        - Pipeline input support
        - Back/Exit navigation actions

    .PARAMETER Objects
        Array of objects to display. This parameter is mandatory and accepts pipeline input.
        Can be $null or empty, in which case EmptyArrayMessage is displayed.

    .PARAMETER SelectedColumns
        Properties of objects to display in the table. If not specified, all properties are shown.
        Example: @("Name", "Status", "CPU")

    .PARAMETER Sort
        Property or properties to sort objects by before display.
        Example: "Name" or @{Expression="CPU"; Descending=$true}

    .PARAMETER SelectHeaderMessage
        Header message displayed at the top of the dialog. Default: "Please select an item:"
        Can be displayed in the separator (with -HeaderTextInSeparator) or as regular text.

    .PARAMETER HeaderColor
        Color of the header text. Default: Current console foreground color.

    .PARAMETER FooterMessage
        Footer message displayed at the bottom of the dialog, after all buttons.
        If not specified, no footer is displayed.

    .PARAMETER FooterColor
        Color of the footer text. Default: Current console foreground color.

    .PARAMETER EmptyArrayMessage
        Message displayed when the Objects array is empty or null. Default: "No items in array"
        Displayed in yellow color to draw attention.

    .PARAMETER OtherMenuItems
        Array of additional menu items (buttons) to display in the navigation area.
        Items can be CLIDialogButton objects or menu items that will be converted to buttons.
        Supports scriptblock objects for dynamic actions.

    .PARAMETER OtherMenuItemsHeader
        Header text for the other menu items section. If not specified, items are displayed
        without a header or with an invisible header (see OtherMenuItemsInvisibleHeader).

    .PARAMETER OtherMenuItemsInvisibleHeader
        Switch parameter. When specified, displays other menu items with an invisible header
        (maintains layout alignment without visible text). Only used when OtherMenuItemsHeader
        is not specified.

    .PARAMETER AutoSelectWhenOneItem
        Switch parameter. When specified and the array contains exactly one item, automatically
        selects that item and returns it without displaying the dialog. Useful for simplified
        user experience when only one option is available.

    .PARAMETER ShowOnlyOnePage
        Switch parameter. When specified, limits display to a single page regardless of the
        number of items. Not currently implemented in the main loop logic.

    .PARAMETER NoEmptyLineAfterItems
        Switch parameter. When specified, removes the empty line typically displayed after
        the items list. Not currently implemented in the rendering logic.

    .PARAMETER ItemsPerPage
        Number of items to display per page. Must be at least 1. Default: 10
        Determines pagination behavior and page count calculation.

    .PARAMETER SeparatorColor
        Color of the separator lines drawn between sections. Default: Current console foreground color.

    .PARAMETER HeaderTextInSeparator
        Switch parameter. When specified, displays the header message inside the top separator
        line instead of as a separate text line. Creates a more compact layout.

    .PARAMETER Space
        Switch parameter. When specified, adds extra spacing between table columns for improved
        readability. Passed to New-CLIDialogTableItems.

    .PARAMETER DontShowPageNumberWhenOnlyOnePage
        Switch parameter. When specified and there is only one page, hides the page number
        indicator in the separator. Reduces visual clutter for small datasets.

    .PARAMETER MultiSelect
        Switch parameter. Enables multiple selection mode with checkboxes next to each item.
        When enabled, users can select/deselect multiple items and must press a Validate button
        to confirm their selection. Requires SelectedObjectsUniqueProperty for tracking selections.

    .PARAMETER SelectedObjectsUniqueProperty
        Property name to use as unique identifier for selected objects in multi-select mode.
        Required when MultiSelect is enabled. If not specified with MultiSelect, defaults to
        the first property in SelectedColumns. Used to track which objects are selected.

    .PARAMETER SelectedObjects
        Array of pre-selected object identifiers (values of SelectedObjectsUniqueProperty).
        Only applicable in MultiSelect mode. Allows initializing the dialog with some objects
        already selected. Example: @("Server1", "Server3") if using "Name" as unique property.

    .PARAMETER Confirm
        Switch parameter. Enables confirmation dialog after selection. When specified, displays
        a Yes/No/Cancel dialog asking the user to confirm their selection before returning.
        Works with both single and multi-select modes.

    .PARAMETER ConfirmMessage
        Confirmation message to display in the confirmation dialog. Supports variable substitution:
        - %count%: Replaced with the number of selected items
        - %name%: Replaced with the name property of the selected item
        Example: "Do you want to process %count% item(s)?"

    .PARAMETER YesButtonText
        Text for the "Yes" button in the confirmation dialog. Supports same variable substitution
        as ConfirmMessage. If not specified, uses default "Yes" text.

    .PARAMETER NoButtonText
        Text for the "No" button in the confirmation dialog. Supports same variable substitution
        as ConfirmMessage. If not specified, uses default "No" text. Selecting "No" returns to
        the selection dialog.

    .PARAMETER CancelButtonText
        Text for the "Cancel" button in the confirmation dialog. Supports same variable substitution
        as ConfirmMessage. If not specified, uses default "Cancel" text. Selecting "Cancel" returns
        a DialogResult.Action.Cancel result.

    .PARAMETER ShowBackButton
        Switch parameter. When specified, displays a "Back" button in the navigation menu.
        Allows users to return to a previous screen in multi-level menu systems.

    .PARAMETER UseArrayPageExtractor
        Switch parameter. When specified, uses the ArrayPageExtractor object for pagination instead
        of manual page calculation. Provides a more object-oriented approach to pagination with
        built-in navigation methods. More modern but requires ArrayPageExtractor availability.

    .PARAMETER ValueColumnName
        Name of the column to display when using simple type arrays (strings, numbers, booleans).
        Default: "Value". This parameter allows customizing the column header for better user experience.
        Example: For a list of server names, use "Server" instead of the default "Value".

    .OUTPUTS
        Returns a DialogResult object with one of the following PSTypeNames:
        - DialogResult.Value: User selected an item (contains .Value property with selected object(s))
        - DialogResult.Action.Back: User selected Back button
        - DialogResult.Action.Exit: User selected Exit button
        - DialogResult.Action.Cancel: User cancelled in confirmation dialog
        - DialogResult.Action.Other: User selected a scriptblock menu item (contains .Value with scriptblock result)

        For single selection: .Value contains the selected object
        For multi-selection: .Value contains an array of selected objects

    .EXAMPLE
        $services = Get-Service
        $result = $services | Select-CLIDialogObjectInArray -SelectedColumns Name,Status -Sort Status
        $selectedService = $result.Value

        Basic single selection with pipeline input, displaying specific columns and sorting by Status.

    .EXAMPLE
        $result = Get-Process | Select-CLIDialogObjectInArray `
            -SelectedColumns Name,CPU,WorkingSet `
            -Sort @{Expression="CPU"; Descending=$true} `
            -ItemsPerPage 15 `
            -SelectHeaderMessage "Select a process to inspect" `
            -HeaderTextInSeparator `
            -Space

        Advanced single selection with sorted columns, custom page size, header in separator, and spaced columns.

    .EXAMPLE
        $servers = Get-ADComputer -Filter * | Select-Object Name,OperatingSystem
        $result = $servers | Select-CLIDialogObjectInArray `
            -SelectedColumns Name,OperatingSystem `
            -MultiSelect `
            -SelectedObjectsUniqueProperty Name `
            -SelectedObjects @("Server01", "Server02") `
            -Confirm `
            -ConfirmMessage "Deploy updates to %count% server(s)?" `
            -YesButtonText "Yes, deploy" `
            -NoButtonText "No, reselect"

        Multi-selection with pre-selected items, confirmation dialog with custom messages.

    .EXAMPLE
        $items = @()
        $result = $items | Select-CLIDialogObjectInArray `
            -SelectedColumns Name `
            -EmptyArrayMessage "No items found in the database" `
            -ShowBackButton

        Handling empty arrays with custom message and Back button for navigation.

    .EXAMPLE
        $customMenuItems = @(
            New-CLIDialogButton -Text "&Refresh" -Object { Get-UpdatedData } -AddNewLine
            New-CLIDialogButton -Text "&Settings" -Object { Show-Settings } -AddNewLine
        )
        $result = Get-Data | Select-CLIDialogObjectInArray `
            -SelectedColumns Name,Value `
            -OtherMenuItems $customMenuItems `
            -OtherMenuItemsHeader "Actions"

        Including custom menu items with scriptblocks and a header.

    .EXAMPLE
        $files = Get-ChildItem -Path C:\Temp
        if ($files.Count -eq 1) {
            $result = $files | Select-CLIDialogObjectInArray `
                -SelectedColumns Name,Length,LastWriteTime `
                -AutoSelectWhenOneItem
            # Dialog not shown, single file automatically selected
        }

        Automatic selection when only one item is present.

    .EXAMPLE
        $result = Get-Service | Select-CLIDialogObjectInArray `
            -SelectedColumns Name,Status `
            -UseArrayPageExtractor `
            -ItemsPerPage 20 `
            -DontShowPageNumberWhenOnlyOnePage

        Using modern ArrayPageExtractor for pagination with custom page size.

    .EXAMPLE
        $servers = @("Server01", "Server02", "Server03", "Server04")
        $result = $servers | Select-CLIDialogObjectInArray -ValueColumnName "Server Name"
        $selectedServer = $result.Value

        Using a string array with a custom column name for better readability.

    .NOTES
        Module: CLIDialog
        Author: Loïc Ade
        Created: 2025-10-25
        Version: 1.1.0
        Dependencies: New-CLIDialog, New-CLIDialogButton, New-CLIDialogSeparator, New-CLIDialogText,
                     New-CLIDialogTableItems, New-CLIDialogObjectsRow, Invoke-CLIDialog,
                     New-DialogResultValue, New-DialogResultAction, Invoke-YesNoCLIDialog,
                     Read-NumericValue, New-ArrayPageExtractor (optional)

        This function represents a comprehensive solution for object selection in PowerShell CLI
        environments, merging the best features of two previous implementations while maintaining
        backward compatibility and adding new capabilities.

        SELECTION MODES:
        - Single Selection (default): User selects one item by pressing its number or clicking
        - Multi-Selection (-MultiSelect): User toggles checkboxes with Space, confirms with Validate button

        PAGINATION MODES:
        - Manual (default): Uses simple page number arithmetic and Get-ArrayPage helper
        - ArrayPageExtractor (-UseArrayPageExtractor): Uses object-oriented pagination with built-in methods

        NAVIGATION:
        - Previous/Next Page buttons (P/N keys)
        - PageUp/PageDown keyboard shortcuts (hidden buttons)
        - Go to Page button (G key) for direct page navigation
        - Back button (B key) when ShowBackButton is specified
        - Exit button (E key) always available

        CONFIRMATION WORKFLOW:
        With -Confirm:
        1. User selects item(s) in main dialog
        2. Confirmation dialog displays with Yes/No/Cancel options
        3. "Yes" returns selected items
        4. "No" returns to selection dialog
        5. "Cancel" returns Cancel action result

        VARIABLE SUBSTITUTION:
        In ConfirmMessage, YesButtonText, NoButtonText, CancelButtonText:
        - %count%: Number of selected items (works with both single and multi-select)
        - %name%: Value of the "name" property of the selected object

        INTERNAL HELPER FUNCTIONS:
        - Format-CustomTable: Formats objects for single-item auto-select display
        - New-CLIObjectListPage: Builds and displays a single page of the dialog
        - Convert-OnlyItem: Converts single item to dialog result for auto-select
        - Replace-StringVar: Replaces %count% and %name% variables in strings
        - Get-ArrayPage: Extracts a page slice from the objects array

        RESULT HANDLING:
        The function returns different result types based on user action:
        - Value result: Contains selected object(s), normal completion
        - Action results: Back, Exit, Cancel, Other (scriptblock execution)
        - The calling code should check PSTypeNames[0] to determine result type

        EMPTY ARRAY BEHAVIOR:
        When Objects is null or empty:
        - Displays EmptyArrayMessage in yellow
        - Shows separator and navigation buttons (Exit, optionally Back)
        - Page count is set to 1 to prevent division by zero
        - Navigation buttons (Previous/Next) are hidden

        SCRIPTBLOCK MENU ITEMS:
        When OtherMenuItems contains buttons with scriptblock objects:
        - Scriptblock is executed when button is selected
        - Result is wrapped in DialogResult.Action.Other
        - Useful for dynamic actions like refresh, settings, custom operations

        CHANGELOG:

        Version 1.1.0 - 2025-11-22 - Loïc Ade
            - Added support for simple type arrays (strings, numbers, booleans)
            - Added ValueColumnName parameter to customize column header for simple types

        Version 1.0.0 - 2025-10-25 - Loïc Ade
            - Initial release merging Select-CLIObjectInArray and Select-CLIDialogObject
            - Single and multi-selection modes
            - Optional confirmation dialogs with variable substitution
            - Complete UI customization (colors, messages, layout)
            - Keyboard navigation with PageUp/PageDown support
            - Custom menu items with scriptblock execution
            - Auto-selection for single items
            - Empty array handling
            - Pre-selection support in multi-select mode
            - Object sorting before display
            - Pipeline input support
            - Manual and ArrayPageExtractor pagination modes
            - Back/Exit navigation actions
            - Selection counter for multi-select mode
            - Flexible header display (in separator or as text)
            - Custom menu items header options (visible, invisible, or none)
            - Page number visibility control
            - Comprehensive parameter documentation
            - Extensive examples covering all major use cases
    #>
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [array]$Objects,
        [object[]]$SelectedColumns,
        [object]$Sort,
        [string]$SelectHeaderMessage = "Please select an item:",
        [System.ConsoleColor]$HeaderColor = (Get-Host).UI.RawUI.ForegroundColor,
        [AllowNull()]
        [string]$FooterMessage, # = "Please type item number",
        [System.ConsoleColor]$FooterColor = (Get-Host).UI.RawUI.ForegroundColor,
        [AllowEmptyString()]
        [string]$EmptyArrayMessage = "No items in array",
        [object[]]$OtherMenuItems,
        [string]$OtherMenuItemsHeader,
        [switch]$OtherMenuItemsInvisibleHeader,
        [switch]$AutoSelectWhenOneItem,
        [switch]$ShowOnlyOnePage,
        [switch]$NoEmptyLineAfterItems,
        [ValidateScript({$_ -ge 1})]
        [int]$ItemsPerPage = 10,
        [System.ConsoleColor]$SeparatorColor = (Get-Host).UI.RawUI.ForegroundColor,
        [switch]$HeaderTextInSeparator,
        [switch]$Space,
        [switch]$DontShowPageNumberWhenOnlyOnePage,
        [switch]$MultiSelect,
        [string]$SelectedObjectsUniqueProperty,
        [string[]]$SelectedObjects,
        [switch]$Confirm,
        [string]$ConfirmMessage,
        [string]$YesButtonText,
        [string]$NoButtonText,
        [string]$CancelButtonText,
        [switch]$ShowBackButton,
        [switch]$UseArrayPageExtractor,
        [string]$ValueColumnName = "Value"
    )

    Begin {
        function Format-CustomTable {
            Param(
                [Parameter(Position = 0)]
                [object[]]$Property,
                [Parameter(ValueFromPipeline)]
                [object[]]$InputObject,
                [switch]$HideTableHeaders
            )
            Begin {
                $aItems = @()
            }
            Process {
                $aItems += $InputObject
            }
            End {
                $hSettings = @{
                    HideTableHeaders = $HideTableHeaders.IsPresent
                }
                if ($Property) {
                    $hSettings.Property = $Property
                }
                $result = $aItems | Format-Table @hSettings | Out-String
                $aResult = ($result.Split("`r`n") | Where-Object { $_.Trim() -ne "" })
                return $aResult
            }
        }

        function New-CLIObjectListPage {
            Param(
                [AllowNull()]
                [object[]]$Objects,
                [int]$PageNumber,
                [int]$PageCount,
                [int]$ItemsPerPage,
                [object[]]$OtherMenuItems,
                [string]$OtherMenuItemsHeader,
                [switch]$OtherMenuItemsInvisibleHeader,
                [object[]]$SelectedColumns,
                [System.ConsoleColor]$SeparatorColor = (Get-Host).UI.RawUI.ForegroundColor,
                [switch]$MultiSelect,
                [ref]$SelectedObjectsArray,
                [string]$SelectedObjectsUniqueProperty,
                [switch]$ShowBackButton
            )
            $aCLIObject = @()

            # Header
            if ($SelectHeaderMessage) {
                if ($HeaderTextInSeparator) {
                    $aCLIObject += New-CLIDialogSeparator -Text $SelectHeaderMessage -ForegroundColor $SeparatorColor -AutoLength
                } else {
                    $aCLIObject += New-CLIDialogText -Text $SelectHeaderMessage -ForegroundColor $HeaderColor -AddNewLine
                }
            }

            # Content
            if ($Objects) {
                if ($MultiSelect -and $SelectedObjectsArray) {
                    $aCLIObject += New-CLIDialogTableItems -Objects $Objects -Properties $SelectedColumns -Checkbox:$MultiSelect -EnabledObjectsArray $SelectedObjectsArray -EnabledObjectsUniqueProperty $SelectedObjectsUniqueProperty -Space:$Space
                } else {
                    $aCLIObject += New-CLIDialogTableItems -Objects $Objects -Properties $SelectedColumns -Checkbox:$MultiSelect -Space:$Space
                }
            } else {
                $aCLIObject += New-CLIDialogText -Text $EmptyArrayMessage -ForegroundColor Yellow -AddNewLine
            }

            # Separator with page info
            if ($Objects) {
                if ($DontShowPageNumberWhenOnlyOnePage -and $PageCount -eq 1) {
                    $aCLIObject += New-CLIDialogSeparator -AutoLength -ForegroundColor $SeparatorColor
                } else {
                    $aCLIObject += New-CLIDialogSeparator -AutoLength -DrawArrows -DrawPageNumber -PageNumber $PageNumber -PageCount $PageCount -ForegroundColor $SeparatorColor
                }
            } else {
                $aCLIObject += New-CLIDialogSeparator -AutoLength -ForegroundColor $SeparatorColor
            }

            # Selection counter (MultiSelect only)
            if ($MultiSelect -and $SelectedObjectsArray) {
                $aCLIObject += New-CLIDialogObjectsRow -Header "Selection" -HeaderSeparator " :  " -HeaderForegroundColor (Get-Host).UI.RawUI.ForegroundColor -Row @(
                    New-CLIDialogText -TextFunctionArguments @{SelectedObjectsArray = $SelectedObjectsArray} -TextFunction {
                        Param([ref]$SelectedObjectsArray)
                        if ($SelectedObjectsArray.Value -eq $null) {
                            return "0 selected objects"
                        } elseif ($SelectedObjectsArray.Value -is [array]) {
                            if ($SelectedObjectsArray.Value.Count -eq 1) {
                                return "1 selected object"
                            } else {
                                return "$($SelectedObjectsArray.Value.Count) selected objects"
                            }
                        } else {
                            return "1 selected object"
                        }
                    }
                )
            }

            # Navigation buttons
            $aHiddenButtons = @()
            $aNavigationButtons = @()

            if ($ShowBackButton) {
                $aNavigationButtons += New-CLIDialogButton -Text "&Back" -Keyboard B -Back
            }

            if ($PageCount -gt 1) {
                if ($PageNumber -ne 0) {
                    $aNavigationButtons += New-CLIDialogButton -Text "&Previous page" -Keyboard P -Previous
                    $aHiddenButtons += New-CLIDialogButton -Text "Previous page" -Keyboard PageUp -Previous
                }
                $aNavigationButtons += New-CLIDialogButton -Text "&Go to page" -Keyboard G -GoTo
                if ($PageNumber -ne ($PageCount - 1)) {
                    $aNavigationButtons += New-CLIDialogButton -Text "&Next page" -Keyboard N -Next
                    $aHiddenButtons += New-CLIDialogButton -Text "Next page" -Keyboard PageDown -Next
                }
            }

            if ($aNavigationButtons.Count -gt 0) {
                $aCLIObject += New-CLIDialogObjectsRow -Row $aNavigationButtons -Header "Navigate to" -HeaderSeparator " : "
            }

            # Other menu items
            if ($OtherMenuItems) {
                if ($OtherMenuItems[0].Type -eq "row") {
                    $aCLIObject += $OtherMenuItems
                } else {
                    $aOtherMenuItems = @()
                    foreach ($item in $OtherMenuItems) {
                        if ($item.Type -like "menu*") {
                            $aOtherMenuItems += $item.ConvertToButton()
                        } else {
                            $aOtherMenuItems += $item
                        }
                    }
                    if ($OtherMenuItemsHeader) {
                        $aCLIObject += New-CLIDialogObjectsRow -Row $aOtherMenuItems -Header $OtherMenuItemsHeader
                    } elseif ($OtherMenuItemsInvisibleHeader) { 
                        $aCLIObject += New-CLIDialogObjectsRow -Row $aOtherMenuItems -InvisibleHeader
                    } else {
                        $aCLIObject += New-CLIDialogObjectsRow -Row $aOtherMenuItems
                    }
                }
            }

            # Footer
            if ($FooterMessage) {
                $aCLIObject += New-CLIDialogText -Text $FooterMessage -ForegroundColor $FooterColor -AddNewLine
            }

            # Create dialog with Validate button for MultiSelect
            $hDialogParams = @{
                Rows = $aCLIObject
            }
            if ($aHiddenButtons.Count -gt 0) {
                $hDialogParams.HiddenButtons = $aHiddenButtons
            }
            if ($MultiSelect -and $SelectedObjectsArray) {
                $hDialogParams.ValidateObject = New-CLIDialogButton -Text "Ok" -Validate
                $hDialogParams.SelectedObjectsArray = $SelectedObjectsArray
                $hDialogParams.SelectedObjectsUniqueProperty = $SelectedObjectsUniqueProperty
            }

            $oDialog = New-CLIDialog @hDialogParams
            $oDialogResult = Invoke-CLIDialog -InputObject $oDialog

            return $oDialogResult
        }

        function Convert-OnlyItem {
            Param(
                [object]$Object,
                [object]$SelectedColumns
            )
            $aSelectedColumnObjects = if ($SelectedColumns) {
                $Object | Select-Object -Property $SelectedColumns
            } else {
                $Object
            }
            $aSelectedColumnObjectsToString = $aSelectedColumnObjects | Format-CustomTable
            $oButtonResult = New-CLIDialogButton -Text $aSelectedColumnObjectsToString[2] -Object $Object -ObjectSelectedProperties $aSelectedColumnObjects -AddNewLine

            $hResult = @{
                Button = $oButtonResult
                Form = $this
                Type = "Value"
                Object = $Object
                ObjectSelectedProperties = $aSelectedColumnObjects
            }

            return $hResult
        }

        function Replace-StringVar {
            Param(
                [Parameter(Mandatory, Position = 0)]
                [string]$InputString,
                [object]$Result
            )
            $sResult = $InputString
            if ($sResult -like "*%count%*") {
                if ($Result.Value -is [array]) {
                    $sResult = $sResult.Replace("%count%", $Result.Value.Count)
                } else {
                    $sResult = $sResult.Replace("%count%", 1)
                }
            }
            if ($sResult -like "*%name%*") {
                $sResult = $sResult.Replace("%name%", $Result.Value.name)
            }
            return $sResult
        }

        function Get-ArrayPage {
            Param(
                [object[]]$Objects,
                [int]$Page,
                [int]$ItemsPerPage
            )
            $iStart = $Page * $ItemsPerPage
            $iEnd = [Math]::Min($iStart + $ItemsPerPage - 1, $Objects.Count - 1)
            if ($iStart -gt $iEnd) {
                return @()
            }
            return $Objects[$iStart..$iEnd]
        }

        function Convert-SimpleTypeResult {
            Param(
                [object]$Value,
                [bool]$IsSimpleTypeArray,
                [string]$PropertyName = "Value"
            )
            if (-not $IsSimpleTypeArray) {
                return $Value
            }
            if ($Value -is [array]) {
                return $Value | ForEach-Object { $_.$PropertyName }
            } else {
                return $Value.$PropertyName
            }
        }

        $aObjects = @()
    }

    Process {
        foreach ($o in $Objects) {
            $aObjects += $o
        }
    }

    End {
        # Convert simple types (strings, numbers) to objects with a Value property
        $bIsSimpleTypeArray = $false
        if ($aObjects.Count -gt 0) {
            $firstItem = $aObjects[0]
            if ($firstItem -is [string] -or $firstItem -is [int] -or $firstItem -is [double] -or $firstItem -is [bool]) {
                $bIsSimpleTypeArray = $true
                $aObjects = $aObjects | ForEach-Object {
                    $obj = [PSCustomObject]@{}
                    $obj | Add-Member -MemberType NoteProperty -Name $ValueColumnName -Value $_
                    $obj
                }
                if (-not $SelectedColumns) {
                    $SelectedColumns = @($ValueColumnName)
                }
            }
        }

        # Sort objects if requested
        if ($Sort) {
            $aObjects = $aObjects | Sort-Object -Property $Sort
        }
        $aObjects = @() + $aObjects

        # Auto-select if only one item
        if (($aObjects.Count -eq 1) -and ($AutoSelectWhenOneItem -eq $true)) {
            $oDialogValue = Convert-OnlyItem $aObjects[0] -SelectedColumns $SelectedColumns
            $convertedValue = Convert-SimpleTypeResult -Value $oDialogValue.Object -IsSimpleTypeArray $bIsSimpleTypeArray -PropertyName $ValueColumnName
            return New-DialogResultValue -Value $convertedValue
        }

        # Initialize pagination
        $iPageNumber = 0
        $iPageCount = if ($aObjects.Count -eq 0) { 1 } else { [Math]::Floor(($aObjects.Count - 1) / $ItemsPerPage) + 1 }

        # Initialize selected objects for MultiSelect
        $aSelectedObjects = if ($MultiSelect -and $SelectedObjects) {
            $sProperty = if ($SelectedObjectsUniqueProperty) { $SelectedObjectsUniqueProperty } else { $SelectedColumns[0] }
            $aObjects | Where-Object { $_.$sProperty -in $SelectedObjects }
        } else {
            @()
        }

        # Initialize ArrayPageExtractor if requested
        $ArrayPageSelector = if ($UseArrayPageExtractor) {
            New-ArrayPageExtractor -Objects $aObjects -ItemsPerPage $ItemsPerPage
        } else {
            $null
        }

        # Main dialog loop
        $oResult = $null
        while ($true) {
            # Get current page
            $aPage = if ($UseArrayPageExtractor) {
                $ArrayPageSelector.GetCurrentPage()
            } elseif ($aObjects) {
                Get-ArrayPage -Objects $aObjects -Page $iPageNumber -ItemsPerPage $ItemsPerPage
            } else {
                $null
            }

            # Build dialog parameters
            $hDialogParams = @{
                Objects = $aPage
                PageNumber = if ($UseArrayPageExtractor) { $ArrayPageSelector.Page } else { $iPageNumber }
                PageCount = if ($UseArrayPageExtractor) { $ArrayPageSelector.PageCount } else { $iPageCount }
                ItemsPerPage = $ItemsPerPage
                OtherMenuItems = $OtherMenuItems
                SelectedColumns = $SelectedColumns
                SeparatorColor = $SeparatorColor
                ShowBackButton = $ShowBackButton
            }

            if ($MultiSelect) {
                $sProperty = if ($SelectedObjectsUniqueProperty) { $SelectedObjectsUniqueProperty } else { $SelectedColumns[0] }
                $hDialogParams.MultiSelect = $true
                $hDialogParams.SelectedObjectsArray = [ref]$aSelectedObjects
                $hDialogParams.SelectedObjectsUniqueProperty = $sProperty
            }

            if ($OtherMenuItems) {
                if ($OtherMenuItemsHeader) {
                    $hDialogParams.OtherMenuItemsHeader = $OtherMenuItemsHeader
                }
                if ($OtherMenuItemsInvisibleHeader) {
                    $hDialogParams.OtherMenuItemsInvisibleHeader = $OtherMenuItemsInvisibleHeader
                }
            }

            # Display dialog
            $oResult = New-CLIObjectListPage @hDialogParams

            # Handle result
            switch ($oResult.PSTypeNames[0]) {
                "DialogResult.Action.Back" {
                    return $oResult
                }
                "DialogResult.Action.Exit" {
                    return $oResult
                }
                "DialogResult.Action.Previous" {
                    if ($UseArrayPageExtractor) {
                        $ArrayPageSelector.GoToPreviousPage()
                    } else {
                        if ($iPageNumber -gt 0) {
                            $iPageNumber--
                        }
                    }
                }
                "DialogResult.Action.Next" {
                    if ($UseArrayPageExtractor) {
                        $ArrayPageSelector.GoToNextPage()
                    } else {
                        if ($iPageNumber -lt ($iPageCount - 1)) {
                            $iPageNumber++
                        }
                    }
                }
                "DialogResult.Action.GoTo" {
                    if ($UseArrayPageExtractor) {
                        $drNewPage = Read-CLIDialogNumericValue -header "Go to page number" -min 1 -max $ArrayPageSelector.PageCount -errorMessage "Page number invalid" -PropertyName "Page" -AllowCancel
                        if ($drNewPage.Type -eq "Value") {
                            $iNewPage = $drNewPage.Value - 1
                            $ArrayPageSelector.GoToPage($iNewPage)
                        }
                    } else {
                        $drNewPage = Read-CLIDialogNumericValue -header "Go to page number" -min 1 -max $iPageCount -errorMessage "Page number invalid" -PropertyName "Page"
                        if ($drNewPage.Type -eq "Value") {
                            $iPageNumber = $drNewPage.Value - 1
                        }   
                    }
                }
                "DialogResult.Action.Other" {
                    if ($oResult.Value -is [scriptblock]) {
                        $oScriptResult = . $oResult.Value
                        Return New-DialogResultAction -Action "Other" -Value $oScriptResult
                    }
                }
                "DialogResult.Action.Validate" {
                    # Handle MultiSelect validation
                    if ($Confirm) {
                        # Confirmation dialog
                        $convertedValue = Convert-SimpleTypeResult -Value $aSelectedObjects -IsSimpleTypeArray $bIsSimpleTypeArray -PropertyName $ValueColumnName
                        $oConfirmResult = New-DialogResultValue -Value $convertedValue -DialogResult $oResult
                        $sConfirmMessage = Replace-StringVar -InputString $ConfirmMessage -Result $oConfirmResult
                        $sYesButtonText = Replace-StringVar -InputString $YesButtonText -Result $oConfirmResult
                        $sNoButtonText = Replace-StringVar -InputString $NoButtonText -Result $oConfirmResult
                        $sCancelButtonText = Replace-StringVar -InputString $CancelButtonText -Result $oConfirmResult

                        if ($oConfirmResult.Value) {
                            $oConfirmAnswer = Invoke-YesNoCLIDialog -Message $sConfirmMessage `
                                                                    -YesButtonText $sYesButtonText `
                                                                    -NoButtonText $sNoButtonText `
                                                                    -CancelButtonText $sCancelButtonText `
                                                                    -Vertical
                        } else {
                            $oConfirmAnswer = Invoke-YesNoCLIDialog -NC -Message $sConfirmMessage `
                                                                    -NoButtonText $sNoButtonText `
                                                                    -CancelButtonText $sCancelButtonText `
                                                                    -Vertical
                        }

                        if ($oConfirmAnswer -eq "Yes") {
                            return $oConfirmResult
                        } elseif ($oConfirmAnswer -eq "Cancel") {
                            return New-DialogResultAction -Action "Cancel"
                        }
                        # If "No", continue loop
                    } else {
                        # Direct validation without confirmation
                        $convertedValue = Convert-SimpleTypeResult -Value $aSelectedObjects -IsSimpleTypeArray $bIsSimpleTypeArray -PropertyName $ValueColumnName
                        return New-DialogResultValue -Value $convertedValue -DialogResult $oResult
                    }
                }
                "DialogResult.Value" {
                    # Single selection
                    if ($Confirm) {
                        # Confirmation dialog
                        $convertedValue = Convert-SimpleTypeResult -Value $oResult.Value -IsSimpleTypeArray $bIsSimpleTypeArray -PropertyName $ValueColumnName
                        $oConvertedResult = New-DialogResultValue -Value $convertedValue -DialogResult $oResult
                        $sConfirmMessage = Replace-StringVar -InputString $ConfirmMessage -Result $oConvertedResult
                        $sYesButtonText = Replace-StringVar -InputString $YesButtonText -Result $oConvertedResult
                        $sNoButtonText = Replace-StringVar -InputString $NoButtonText -Result $oConvertedResult
                        $sCancelButtonText = Replace-StringVar -InputString $CancelButtonText -Result $oConvertedResult

                        $oConfirmAnswer = Invoke-YesNoCLIDialog -Message $sConfirmMessage `
                                                                -YesButtonText $sYesButtonText `
                                                                -NoButtonText $sNoButtonText `
                                                                -CancelButtonText $sCancelButtonText `
                                                                -Vertical

                        if ($oConfirmAnswer -eq "Yes") {
                            return $oConvertedResult
                        } elseif ($oConfirmAnswer -eq "Cancel") {
                            return New-DialogResultAction -Action "Cancel"
                        }
                        # If "No", continue loop
                    } else {
                        # Direct return without confirmation
                        $convertedValue = Convert-SimpleTypeResult -Value $oResult.Value -IsSimpleTypeArray $bIsSimpleTypeArray -PropertyName $ValueColumnName
                        return New-DialogResultValue -Value $convertedValue -DialogResult $oResult
                    }
                }
            }
        }
    }
}
