function Find-Object{
    <#
    .SYNOPSIS
        Displays an interactive search dialog to find and select objects using a custom search function.

    .DESCRIPTION
        This function provides a dynamic search interface where users can type search terms and see
        filtered results in real-time via a custom SearchFunction scriptblock. It combines text input
        with paginated object selection, supporting both single and multi-select modes. The function
        displays results in a table format with customizable columns, pagination controls, and optional
        confirmation dialogs. It's designed for scenarios where users need to search through large
        datasets or query external data sources interactively.

        The search workflow:
        1. User enters search text in a textbox
        2. SearchFunction is called with the search text
        3. Results are displayed in a paginated table below the search field
        4. User can refine search or select item(s)
        5. Optional confirmation before returning selection

    .PARAMETER HeaderString
        Header text displayed in the top separator of the dialog. Default: "Please find an Object"

    .PARAMETER StarForbidden
        Switch parameter. When set, prevents users from using wildcard (*) in searches and hides
        the "You can use * to find more results" hint text.

    .PARAMETER InputString
        Pre-populated search text to display in the search textbox on initial load. Useful for
        providing default search terms or resuming previous searches.

    .PARAMETER SeparatorColor
        Color of the separator lines between dialog sections. Default: Blue

    .PARAMETER SelectedColumns
        Array of property names to display as table columns. If not specified, SearchFunction
        results determine which properties are shown. Example: @("Name", "Status", "CPU")

    .PARAMETER ItemsPerPage
        Number of items to display per page. Must be at least 1. Default: 10

    .PARAMETER Sort
        Property name to sort results by after SearchFunction returns them. Results are sorted
        ascending, with null values filtered out. Default: "name"

    .PARAMETER SearchFunction
        Scriptblock that performs the search operation. This parameter is mandatory. The scriptblock
        receives the search text via -InputString parameter and must return an array of objects.
        Example: { Param($InputString) Get-Process | Where-Object Name -like "*$InputString*" }

    .PARAMETER SearchFunctionParameters
        Hashtable of additional parameters to pass to SearchFunction via splatting. Useful for
        passing configuration, credentials, or other context to the search operation.
        Example: @{Server="db01"; Database="inventory"}

    .PARAMETER MultiSelect
        Switch parameter. Enables multiple selection mode with checkboxes. Users can select multiple
        items and must press OK/Validate button to confirm selection. Requires SelectedObjectsUniqueProperty.

    .PARAMETER SelectedObjectsUniqueProperty
        Property name to use as unique identifier for selected objects in multi-select mode.
        Required when MultiSelect is enabled. Used to track which objects are selected across pages.
        Example: "Id" or "Name"

    .PARAMETER Confirm
        Switch parameter. Enables confirmation dialog after selection. When set, displays a Yes/No/Cancel
        dialog asking the user to confirm their selection before returning results.

    .PARAMETER ConfirmMessage
        Message displayed in the confirmation dialog. Supports variable substitution:
        - %count%: Replaced with number of selected items
        - %name%: Replaced with the name property of selected item
        Example: "Delete %count% item(s)?"

    .PARAMETER YesButtonText
        Text for the "Yes" button in confirmation dialog. Supports same variable substitution as
        ConfirmMessage. If not specified, uses default "Yes" text.

    .PARAMETER NoButtonText
        Text for the "No" button in confirmation dialog. Supports same variable substitution as
        ConfirmMessage. Selecting "No" returns to search dialog for new selection.

    .PARAMETER CancelButtonText
        Text for the "Cancel" button in confirmation dialog. Supports same variable substitution as
        ConfirmMessage. Selecting "Cancel" returns a DialogResult.Action.Cancel result.

    .OUTPUTS
        Returns a DialogResult object with one of the following PSTypeNames:
        - DialogResult.Value: User selected item(s) (contains .Value property with selected object(s))
        - DialogResult.Action.Back: User pressed Back button (when search text is empty)
        - DialogResult.Action.Exit: User pressed Exit button
        - DialogResult.Action.Cancel: User cancelled in confirmation dialog

        For single selection: .Value contains the selected object
        For multi-selection: .Value contains an array of selected objects

    .EXAMPLE
        $searchFunction = { Param($InputString) Get-Process | Where-Object Name -like "*$InputString*" }
        $result = Find-Object -SearchFunction $searchFunction -SelectedColumns Name,CPU,WorkingSet
        if ($result.Type -eq "Value") {
            $selectedProcess = $result.Value
            Stop-Process -InputObject $selectedProcess
        }

        Search for processes by name and stop the selected process.

    .EXAMPLE
        $searchFunc = { Param($InputString) Get-ADUser -Filter "Name -like '*$InputString*'" }
        $result = Find-Object -SearchFunction $searchFunc `
                             -HeaderString "Find Active Directory User" `
                             -SelectedColumns Name,SamAccountName,Department `
                             -Sort "SamAccountName"

        Search Active Directory users with custom header and sorted results.

    .EXAMPLE
        $searchFunc = {
            Param($InputString, $Server)
            Invoke-SqlCmd -ServerInstance $Server -Query "SELECT * FROM Users WHERE Name LIKE '%$InputString%'"
        }
        $result = Find-Object -SearchFunction $searchFunc `
                             -SearchFunctionParameters @{Server="sql01"} `
                             -SelectedColumns UserId,UserName,Email `
                             -StarForbidden

        Search database with additional parameters and without wildcard support.

    .EXAMPLE
        $result = Find-Object -SearchFunction { Param($InputString)
                                 Get-Service | Where-Object DisplayName -like "*$InputString*"
                             } `
                             -MultiSelect `
                             -SelectedObjectsUniqueProperty Name `
                             -Confirm `
                             -ConfirmMessage "Restart %count% service(s)?" `
                             -YesButtonText "Yes, restart" `
                             -NoButtonText "No, reselect"

        Multi-select services with confirmation dialog before restarting.

    .EXAMPLE
        $result = Find-Object -SearchFunction { Param($InputString)
                                 Get-ChildItem -Path C:\Logs -Filter "*$InputString*.log"
                             } `
                             -InputString "error" `
                             -HeaderString "Find Log Files" `
                             -SelectedColumns Name,Length,LastWriteTime `
                             -ItemsPerPage 15

        Pre-populate search with "error" and display file results with custom page size.

    .NOTES
        Module: CLIDialog
        Author: Loïc Ade
        Created: 2024-05-01
        Version: 1.0.0
        Dependencies: New-CLIDialog, New-CLIDialogButton, New-CLIDialogSeparator, New-CLIDialogTextBox,
                     New-CLIDialogText, New-CLIDialogTableItems, New-CLIDialogObjectsRow, Invoke-CLIDialog,
                     New-DialogResultValue, New-DialogResultAction, Invoke-YesNoCLIDialog,
                     Get-PaginatedArrayBoundaries, Set-StringFormat

        This function provides dynamic search capabilities with immediate feedback, making it ideal for
        interactive data exploration and selection workflows in PowerShell CLI applications.

        SEARCHFUNCTION REQUIREMENTS:
        The SearchFunction scriptblock must:
        - Accept an -InputString parameter containing the search text
        - Return an array of objects (or $null for no results)
        - Be quick enough for interactive use (consider caching or optimization for large datasets)
        - Handle wildcards appropriately if StarForbidden is not set

        SEARCHFUNCTION EXAMPLES:
        ```powershell
        # Simple local search
        { Param($InputString) Get-Process | Where-Object Name -like "*$InputString*" }

        # Remote search with parameters
        { Param($InputString, $Server, $Database)
          Invoke-SqlCmd -ServerInstance $Server -Database $Database `
                        -Query "SELECT * FROM Items WHERE Name LIKE '%$InputString%'"
        }

        # REST API search
        { Param($InputString)
          Invoke-RestMethod -Uri "https://api.example.com/search?q=$InputString"
        }

        # File system search
        { Param($InputString)
          Get-ChildItem -Path C:\ -Recurse -Filter "*$InputString*" -ErrorAction SilentlyContinue
        }
        ```

        INTERNAL HELPER FUNCTIONS:
        - New-FindObjectDialog: Builds the search dialog with textbox, results table, and navigation
        - Get-Object: Main loop handling search execution, pagination, and selection
        - Replace-StringVar: Replaces %count% and %name% variables in confirmation messages

        SEARCH WORKFLOW:
        1. Dialog displays with search textbox (optionally pre-filled with InputString)
        2. User types search text and presses Enter on textbox
        3. SearchFunction is called with the search text
        4. Results are sorted by Sort property and displayed in paginated table BELOW the search field
        5. User can:
           - Refine search (modify textbox text, press Enter)
           - Navigate pages (Previous/Next, PageUp/PageDown)
           - Select item(s) (click or press number for single; checkboxes for multi)
           - Exit or go Back
        6. If Confirm is set, confirmation dialog appears
        7. Result is returned

        KEY FEATURE - PERSISTENT SEARCH FIELD:
        Unlike other selection dialogs, Find-Object keeps the search textbox visible at all times,
        allowing users to iteratively refine their search without returning to a separate screen.
        Results appear dynamically below the search field as the user searches.

        PAGINATION:
        - Results are divided into pages of ItemsPerPage items
        - Page navigation via Previous Page (P), Next Page (N), PageUp, PageDown
        - Page indicator shows current page and total pages
        - Focus automatically moves to results table after successful search

        MULTI-SELECT BEHAVIOR:
        - Checkbox appears next to each item
        - Space bar toggles selection
        - Selection counter shows "X selected objects"
        - Selection persists across pages
        - OK/Validate button confirms selection
        - SelectedObjectsUniqueProperty tracks selections (must be unique across all objects)

        CONFIRMATION DIALOG:
        With -Confirm parameter:
        - Yes: Returns selected items
        - No: Returns to search dialog (selection is kept)
        - Cancel: Returns DialogResult.Action.Cancel

        VARIABLE SUBSTITUTION IN CONFIRMATION:
        - %count%: Number of items selected (1 for single select, N for multi-select)
        - %name%: Value of the .name property of selected object(s)
        - Substitution works in ConfirmMessage, YesButtonText, NoButtonText, CancelButtonText

        EMPTY SEARCH BEHAVIOR:
        - When search textbox is empty and user presses Enter, nothing happens
        - Back button appears even when no search has been performed
        - Results section not displayed until first search

        NO RESULTS BEHAVIOR:
        - "No results for [search text]" message in yellow
        - Separator displayed without page numbers
        - Search field remains visible for refinement

        KEYBOARD NAVIGATION:
        - Enter on search textbox: Execute search
        - Tab/Shift+Tab: Move between fields
        - B: Back button
        - P: Previous Page
        - N: Next Page
        - E: Exit
        - PageUp/PageDown: Navigate pages (hidden buttons)
        - Numbers/letters: Select item in single-select mode
        - Space: Toggle checkbox in multi-select mode

        CHANGELOG:

        Version 1.0.0 - 2024-05-01 - Loïc Ade
            - Initial release
            - Dynamic search with custom SearchFunction scriptblock
            - Single and multi-selection modes
            - Paginated results display
            - Optional confirmation dialogs with variable substitution
            - Wildcard support with optional disable
            - Pre-populated search text support
            - Custom column selection
            - Sorting by property
            - SearchFunction parameter passing via hashtable
            - Real-time result filtering
            - Persistent search field with results displayed below
            - Integration with CLI Dialog framework
    #>
    Param(
        [string]$HeaderString = "Please find an Object",
        [switch]$StarForbidden,
        [string]$InputString,
        [System.ConsoleColor]$SeparatorColor = ([System.ConsoleColor]::Blue),
        [object[]]$SelectedColumns,
        [int]$ItemsPerPage = 10,
        [string]$Sort = "name",
        [Parameter(Mandatory)]
        [scriptblock]$SearchFunction,
        [hashtable]$SearchFunctionParameters,
        [switch]$MultiSelect,
        [string]$SelectedObjectsUniqueProperty,
        [switch]$Confirm,
        [string]$ConfirmMessage,
        [string]$YesButtonText,
        [string]$NoButtonText,
        [string]$CancelButtonText
    )
    function New-FindObjectDialog {
        Param(
            [string]$Search,
            [object[]]$Results,
            [object[]]$SelectedColumns,
            [int]$Page = -1,
            [int]$PageCount = -1,
            [int]$ItemsPerPage,
            [switch]$StarForbidden,
            [switch]$Checkbox,
            [ref]$SelectedObjectsArray,
            [string]$SelectedObjectsUniqueProperty
        )
        $aDialogLines = @()
        $aDialogLines += New-CLIDialogSeparator -AutoLength -Text $HeaderString -ForegroundColor $SeparatorColor
        $aDialogLines += if ($Search) {
            New-CLIDialogTextBox -Header "Search" -Name "Search" -HeaderSeparator " :  " -Text $Search
        } else {
            New-CLIDialogTextBox -Header "Search" -Name "Search" -HeaderSeparator " :  "
        }        
        if (-not $StarForbidden) {
            $aDialogLines += New-CLIDialogText -Text (Set-StringFormat "You can use * to find more results" -Italic) -ForegroundColor Gray -AddNewLine
        }
        if ($Search) {
            $aDialogLines += New-CLIDialogSeparator -AutoLength -ForegroundColor $SeparatorColor -Text "Results"
            if ($Results) {
                $oPageBoundaries = Get-PaginatedArrayBoundaries -Objects $Results -Page $Page -ItemsPerPage $ItemsPerPage
                $aPageResults = $Results[$oPageBoundaries.PageFirstItemIndex..$oPageBoundaries.PageLastItemIndex]
                if ($SelectedObjectsArray) {
                    $aDialogLines += New-CLIDialogTableItems -Objects $aPageResults -Properties $SelectedColumns -Checkbox:$Checkbox -EnabledObjectsArray $SelectedObjectsArray -EnabledObjectsUniqueProperty $SelectedObjectsUniqueProperty
                } else {
                    $aDialogLines += New-CLIDialogTableItems -Objects $aPageResults -Properties $SelectedColumns -Checkbox:$Checkbox
                }
                $aDialogLines += New-CLIDialogSeparator -AutoLength -ForegroundColor $SeparatorColor -PageNumber $Page -PageCount $PageCount -DrawPageNumber
            } else {
                $aDialogLines += New-CLIDialogText -Text "No results for $Search" -ForegroundColor Yellow -AddNewLine
                $aDialogLines += New-CLIDialogSeparator -AutoLength -ForegroundColor $SeparatorColor
            }            
        } else {
            $aDialogLines += New-CLIDialogSeparator -AutoLength -ForegroundColor $SeparatorColor
        }
        if ($SelectedObjectsArray) {
            $aDialogLines += New-CLIDialogObjectsRow -Header "Selection" -HeaderSeparator " :  " -HeaderForegroundColor (Get-Host).UI.RawUI.ForegroundColor -Row @(
                New-CLIDialogText -TextFunctionArguments @{SelectedObjectsArray = $SelectedObjectsArray} -TextFunction {
                    Param(
                        [ref]$SelectedObjectsArray
                    )
                    if ($SelectedObjectsArray.Value -is [array]) {
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
        $aGoToRowItems = @()
        $aGoToRowItems += New-CLIDialogButton -Text "Back" -Keyboard B -Back -Underline 0
        $aHiddenButtons = @()
        if ($Search -and $Results) {
            # If can go to previous page, then add button
            if ($Page -gt $oPageBoundaries.FirstPage) {
                $aGoToRowItems += New-CLIDialogButton -Text "Previous Page" -Keyboard P -Previous -Underline 0
                $aHiddenButtons += New-CLIDialogButton -Text "Previous Page" -Keyboard PageUp -Previous -Underline 0
            }
            # If can go to next page, then add button
            if ($Page -lt $oPageBoundaries.LastPage) {
                $aGoToRowItems += New-CLIDialogButton -Text "Next Page" -Keyboard N -Next -Underline 0
                $aHiddenButtons += New-CLIDialogButton -Text "Next Page" -Keyboard PageDown -Next -Underline 0
            }
        }
        $aGoToRowItems += New-CLIDialogButton -Text "Exit" -Keyboard E -Exit -Underline 0
        $aDialogLines += New-CLIDialogObjectsRow -Header "Go to" -Row $aGoToRowItems
        $oResult = if ($SelectedObjectsArray) {
            New-CLIDialog -Rows $aDialogLines -ValidateObject (New-CLIDialogButton -Text "Ok" -Validate) -HiddenButtons $aHiddenButtons -SelectedObjectsArray $SelectedObjectsArray -SelectedObjectsUniqueProperty $SelectedObjectsUniqueProperty
        } else {
            New-CLIDialog -Rows $aDialogLines -ValidateObject (New-CLIDialogButton -Text "Ok" -Validate) -HiddenButtons $aHiddenButtons
        }
        if ($Search -and $Results) {
            $oResult.FocusedRow = 1
        }
        return $oResult
    }

    function Get-Object {
        $aObjectResults = @()
        $iPage = 0
        $iPageCount = 0
        $oDialog = New-FindObjectDialog -SelectedColumns $SelectedColumns -StarForbidden:$StarForbidden -Checkbox:$MultiSelect
        $aSelectedObjects = @()
        $oResult = $null
        while ($null -eq $oResult) {
            $oDialogResult = Invoke-CLIDialog -InputObject $oDialog
            switch ($oDialogResult.PSTypeNames[0]) {
                "DialogResult.Action.Exit" {
                    $oResult = $oDialogResult
                }
                "DialogResult.Action.Back" {
                    if ($oDialogResult.Depth -eq 0) {
                        $oDialogResult.Depth += 1
                        $oResult = $oDialogResult
                    }
                }
                "DialogResult.Action.Validate" {
                    if ($oDialog.FocusedRow -eq 0) {
                        $oDialogForm = $oDialogResult.DialogResult.Form.GetValue()
                        $sSearchText = $oDialogForm.Search
                        if ($SearchFunctionParameters) {
                            $aObjectResults = . $SearchFunction -InputString $sSearchText @SearchFunctionParameters
                        } else {
                            $aObjectResults = . $SearchFunction -InputString $sSearchText
                        }
                        if ($aObjectResults) {
                            $aObjectResults = $aObjectResults | Where-Object { $null -ne $_.$Sort } | Sort-Object -Property { $_.$Sort }
                        }
                        $iPage = 0
                        $iPageCount = if ($aObjectResults) {
                            if ($aObjectResults -is [array]) {
                                [Math]::Ceiling($aObjectResults.Count / $ItemsPerPage)
                            } else {
                                1
                            }
                        } else {
                            0
                        }
                        if ($MultiSelect) {
                            $oDialog = New-FindObjectDialog -Search $sSearchText -Results $aObjectResults -SelectedColumns $SelectedColumns -Page $iPage -PageCount $iPageCount -ItemsPerPage $ItemsPerPage -StarForbidden:$StarForbidden -Checkbox:$MultiSelect -SelectedObjectsArray ([ref]$aSelectedObjects) -SelectedObjectsUniqueProperty $SelectedObjectsUniqueProperty
                        } else {
                            $oDialog = New-FindObjectDialog -Search $sSearchText -Results $aObjectResults -SelectedColumns $SelectedColumns -Page $iPage -PageCount $iPageCount -ItemsPerPage $ItemsPerPage -StarForbidden:$StarForbidden -Checkbox:$MultiSelect
                        }    
                    } else {
                        $oResult = New-DialogResultValue -Value $aSelectedObjects -DialogResult $oDialogResult
                    }
                }
                "DialogResult.Value" {
                    $oResult = $oDialogResult
                }
                "DialogResult.Action.Next" {
                    $iPage += 1
                    if ($MultiSelect) {
                        $oDialog = New-FindObjectDialog -Search $sSearchText -Results $aObjectResults -SelectedColumns $SelectedColumns -Page $iPage -PageCount $iPageCount -ItemsPerPage $ItemsPerPage -StarForbidden:$StarForbidden -Checkbox:$MultiSelect -SelectedObjectsArray ([ref]$aSelectedObjects) -SelectedObjectsUniqueProperty $SelectedObjectsUniqueProperty
                    } else {
                        $oDialog = New-FindObjectDialog -Search $sSearchText -Results $aObjectResults -SelectedColumns $SelectedColumns -Page $iPage -PageCount $iPageCount -ItemsPerPage $ItemsPerPage -StarForbidden:$StarForbidden -Checkbox:$MultiSelect
                    }
                }
                "DialogResult.Action.Previous" {
                    $iPage -= 1
                    if ($MultiSelect) {
                        $oDialog = New-FindObjectDialog -Search $sSearchText -Results $aObjectResults -SelectedColumns $SelectedColumns -Page $iPage -PageCount $iPageCount -ItemsPerPage $ItemsPerPage -StarForbidden:$StarForbidden -Checkbox:$MultiSelect -SelectedObjectsArray ([ref]$aSelectedObjects) -SelectedObjectsUniqueProperty $SelectedObjectsUniqueProperty
                    } else {
                        $oDialog = New-FindObjectDialog -Search $sSearchText -Results $aObjectResults -SelectedColumns $SelectedColumns -Page $iPage -PageCount $iPageCount -ItemsPerPage $ItemsPerPage -StarForbidden:$StarForbidden -Checkbox:$MultiSelect
                    }
                }
                default {
                    Write-Host $oDialogResult.PSTypeNames[0]
                }
            }
        }
        return $oResult
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
    
    if ($Confirm) {
        $oConfirmAnswer = "No"
        while ($oConfirmAnswer -eq "No") {
            $oResult = Get-Object
            if ($oResult.Type -eq "Action") {
                if ($oResult.Action -eq "Back") {
                    return $oResult
                } elseif ($oResult.Action -eq "Exit") {
                    return $oResult
                }
            }
            $sConfirmMessage = Replace-StringVar -InputString $ConfirmMessage -Result $oResult
            $sYesButtonText = Replace-StringVar -InputString $YesButtonText -Result $oResult
            $sNoButtonText = Replace-StringVar -InputString $NoButtonText -Result $oResult
            $sCancelButtonText = Replace-StringVar -InputString $CancelButtonText -Result $oResult
            if ($oResult.Value) {
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
        }
        if ($oConfirmAnswer -eq "Yes") {
            return $oResult
        } else {
            return New-DialogResultAction -Action "Cancel"
        }
    } else {
        return Get-Object
    }
}
