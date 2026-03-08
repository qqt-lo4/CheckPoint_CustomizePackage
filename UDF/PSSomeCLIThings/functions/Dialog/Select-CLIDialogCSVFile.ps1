function Select-CLIDialogCSVFile {
    <#
    .SYNOPSIS
        Displays an interactive dialog to select a CSV file from a folder with validation and preview.

    .DESCRIPTION
        This function allows users to interactively select a CSV file from a specified folder.
        It validates that the selected CSV file has the expected headers/columns and provides
        a preview before final confirmation. The function leverages the CLI Dialog framework
        for a modern, user-friendly interface.

    .PARAMETER Folder
        The path to the folder containing CSV files. This parameter is mandatory.

    .PARAMETER Headers
        Array of expected header names for the CSV file. The function validates that the selected
        CSV file contains these exact columns. This parameter is mandatory.

    .PARAMETER ConfirmQuestion
        The confirmation question displayed after preview. Default: "Is the CSV OK for you?"

    .PARAMETER SelectHeaderMessage
        Header message for the file selection dialog.
        Default: "Please select a CSV file (must not contain headers and must be separated by commas):"

    .PARAMETER InvalidCSVMessage
        Error message displayed when CSV doesn't have the correct columns.
        Default: "Selected CSV file does not contain the correct number of columns."

    .PARAMETER PreviewMessage
        Message displayed before CSV preview. Use %1 as placeholder for line count.
        Default: "Preview of the CSV (%1 lines):"

    .PARAMETER PreviewLines
        Number of lines to show in the CSV preview. Default: 3

    .OUTPUTS
        Returns a DialogResult object with:
        - Type: "Value" if CSV selected, or action type if exited
        - CSV: The imported CSV data (if selected)
        - Headers: Array of CSV column headers (if selected)
        - File: Full path to the selected CSV file (if selected)

    .EXAMPLE
        $result = Select-CSVFile -Folder "C:\Data" -Headers @("Name", "Email", "Phone")
        if ($result.Type -eq "Value") {
            $csvData = $result.CSV
            Write-Host "Selected file: $($result.File)"
        }

    .NOTES
        Module: CLIDialog
        Author: Loïc Ade
        Created: 2021-12-13
        Modified: 2025-11-23
        Version: 2.0.0
        Dependencies: Select-CLIFileFromFolder, Invoke-YesNoCLIDialog, New-DialogResultAction

        This function provides an interactive way to select and validate CSV files from a folder.
        It ensures the selected CSV has the required column structure before returning the data.

        VALIDATION PROCESS:
        1. User selects a CSV file from the folder
        2. File is imported and headers are validated
        3. If headers match, a preview is shown
        4. User confirms or rejects the selection
        5. On rejection, user can select another file

        RESULT HANDLING:
        The function returns a DialogResult object that can be checked:
        ```powershell
        $result = Select-CSVFile -Folder $path -Headers @("Col1", "Col2")

        switch ($result.PSTypeNames[0]) {
            "DialogResult.Value" {
                # CSV was selected and validated
                $csvData = $result.CSV
                $filePath = $result.File
            }
            "DialogResult.Action.Exit" {
                # User cancelled the operation
                Write-Host "Selection cancelled"
            }
        }
        ```

        CSV VALIDATION:
        The function validates that all headers specified in the -Headers parameter exist in the CSV.
        The validation is case-sensitive and checks for exact matches.

        CHANGELOG:

        Version 2.0.0 - 2025-11-23 - Loïc Ade
            - Complete rewrite using CLI Dialog framework
            - Replaced Get-ItemSelectedByUser with Select-CLIFileFromFolder
            - Replaced Read-YesNoAnswer with Invoke-YesNoCLIDialog
            - Changed return type to DialogResult for consistency
            - Improved error messages and validation
            - Added comprehensive documentation
            - Enhanced user interface with modern dialog components
            - Added proper exit handling with DialogResult.Action.Exit
            - Renamed from Select-CSVFile to Select-CLIDialogCSVFile

        Version 1.0.0 - 2021-12-13 - Loïc Ade
            - Basic CSV file selection with validation
            - Used legacy Get-ItemSelectedByUser function
            - Custom result object format
    #>
    Param(
        [Parameter(Mandatory)]
        [string]$Folder,
        [Parameter(Mandatory)]
        [array]$Headers,
        [string]$ConfirmQuestion = "Is the CSV OK for you?",
        [string]$SelectHeaderMessage = "Please select a CSV file (must not contain headers and must be separated by commas):",
        [string]$InvalidCSVMessage = "Selected CSV file does not contain the correct number of columns.",
        [string]$PreviewMessage = "Preview of the CSV (%1 lines):",
        [int]$PreviewLines = 3
    )

    # Validate folder exists
    if (-not (Test-Path -Path $Folder -PathType Container)) {
        throw [System.IO.DirectoryNotFoundException] "Directory $Folder does not exist"
    }

    # Check if folder contains CSV files
    $csvFiles = Get-ChildItem -Path $Folder -Filter "*.csv"
    if ($null -eq $csvFiles -or $csvFiles.Count -eq 0) {
        throw [System.IO.FileNotFoundException] "Directory $Folder is empty or contains no CSV files"
    }

    # Main selection loop
    while ($true) {
        # Display file selection dialog
        $selectedFileResult = Select-CLIFileFromFolder -Path $Folder `
                                                        -Filter "*.csv" `
                                                        -SelectHeaderMessage $SelectHeaderMessage `
                                                        -AllowExit

        # Handle exit
        if ($selectedFileResult.PSTypeNames[0] -eq "DialogResult.Action.Exit") {
            return New-DialogResultAction -Action "Exit"
        }

        # Get selected file path
        $selectedCSVFile = $selectedFileResult.Value.FullName

        # Import and validate CSV
        $csv = Import-Csv -Path $selectedCSVFile -Delimiter ","
        $csvHeaders = $csv[0].PSObject.Properties.Name

        # Check if CSV has the correct headers
        $hasCorrectHeaders = $true
        foreach ($header in $Headers) {
            if ($header -notin $csvHeaders) {
                $hasCorrectHeaders = $false
                break
            }
        }

        if (-not $hasCorrectHeaders) {
            Write-Host $InvalidCSVMessage -ForegroundColor Red
            continue
        }

        # Display preview
        $previewLineCount = [Math]::Min($csv.Count, $PreviewLines)
        Write-Host ($PreviewMessage -replace "%1", $previewLineCount) -ForegroundColor Cyan
        Write-Host ($csv[0..($previewLineCount - 1)] | Format-Table | Out-String)

        # Confirmation dialog
        $confirmResult = Invoke-YesNoCLIDialog -Message $ConfirmQuestion `
                                                -YN `
                                                -Recommended "Yes"

        if ($confirmResult -eq "Yes") {
            # Return success result
            $result = @{
                Type = "Value"
                CSV = $csv
                Headers = $csvHeaders
                File = $selectedCSVFile
            }
            $result.PSTypeNames.Insert(0, "DialogResult.Value")
            return $result
        }
        # If "No", loop continues to select another file
    }
}