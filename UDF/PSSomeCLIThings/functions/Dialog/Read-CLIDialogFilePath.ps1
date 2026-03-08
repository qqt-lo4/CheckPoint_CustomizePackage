function Read-CLIDialogFilePath {
    <#
    .SYNOPSIS
        Displays an interactive dialog to collect and validate a file path from the user.

    .DESCRIPTION
        This function creates a dialog that collects a file path with existence validation.
        Supports paths with surrounding double quotes (as copied from Windows Explorer).
        Supports file type filtering with Windows file dialog style patterns (e.g., "*.msi|*.exe").
        Built on top of Read-CLIDialogValidatedValue for consistent dialog experience.

    .PARAMETER Header
        Header text displayed above the input field.
        Default: "Please enter a file path"

    .PARAMETER PropertyName
        Name of the property displayed in the dialog input field.
        Default: "Path"

    .PARAMETER Filter
        File type filter pattern using pipe-separated wildcards, similar to Windows file dialogs.
        When specified, the selected file must match at least one of the patterns.
        Example: "*.msi|*.exe" allows only .msi and .exe files.

    .PARAMETER ErrorMessage
        Custom error message displayed when validation fails.
        Default: "File path is not valid or file does not exist"

    .PARAMETER AllowCancel
        When specified, adds a Cancel button. Returns null if user cancels.

    .OUTPUTS
        [System.IO.FileInfo] - FileInfo object for the validated file path
        $null - If user cancels (when AllowCancel is set)

    .EXAMPLE
        $file = Read-CLIDialogFilePath
        Write-Host "Selected file: $($file.FullName)"

    .EXAMPLE
        $file = Read-CLIDialogFilePath -Header "Enter MSI package path" -AllowCancel
        if ($null -eq $file) {
            Write-Host "User cancelled"
        }

    .EXAMPLE
        $file = Read-CLIDialogFilePath -Header "Enter package path" -Filter "*.msi|*.exe"
        Write-Host "Selected package: $($file.FullName)"

    .NOTES
        Author: Loïc Ade
        Created: 2026-03-08
        Version: 1.0.0
        Module: CLIDialog
        Dependencies: Read-CLIDialogValidatedValue

        CHANGELOG:

        Version 1.0.0 - 2026-03-08 - Loïc Ade
            - Initial release
            - File path validation with existence check
            - Automatic removal of surrounding double quotes
            - Cancel button support
            - PropertyName parameter for custom input field label
            - Filter parameter for file type filtering (pipe-separated wildcards)
    #>
    Param(
        [string]$Header = "Please enter a file path",
        [string]$PropertyName = "Path",
        [string]$Filter,
        [string]$ErrorMessage = "File path is not valid or file does not exist",
        [switch]$AllowCancel
    )

    # Build filter patterns from "*.msi|*.exe" style string
    $aFilterPatterns = if ($Filter) {
        $Filter.Split('|') | ForEach-Object { $_.Trim() }
    } else {
        @()
    }

    $validationScript = {
        param($value)
        if ($value -eq "") {
            return $false
        }
        $sPath = $value
        if ($sPath -match '^\s*"(.+)"\s*$') {
            $sPath = $Matches[1]
        }
        if (-not (Test-Path -Path $sPath -PathType Leaf)) {
            return $false
        }
        if ($aFilterPatterns.Count -gt 0) {
            $sFileName = Split-Path -Path $sPath -Leaf
            foreach ($sPattern in $aFilterPatterns) {
                if ($sFileName -like $sPattern) {
                    return $true
                }
            }
            return $false
        }
        return $true
    }.GetNewClosure()

    $params = @{
        Header           = $Header
        PropertyName     = $PropertyName
        ValidationMethod = $validationScript
        ErrorMessage     = $ErrorMessage
    }

    if ($AllowCancel) {
        $params.AllowCancel = $true
    }

    $result = Read-CLIDialogValidatedValue @params

    if ($result.Type -eq "Action" -and $result.Action -eq "Cancel") {
        return $null
    } elseif ($result.Type -eq "Value") {
        $sPath = $result.Value
        if ($sPath -match '^\s*"(.+)"\s*$') {
            $sPath = $Matches[1]
        }
        return Get-Item -Path $sPath
    }
}
