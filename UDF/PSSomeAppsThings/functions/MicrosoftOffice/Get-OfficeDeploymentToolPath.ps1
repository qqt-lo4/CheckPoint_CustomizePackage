function Get-OfficeDeploymentToolPath {
    <#
    .SYNOPSIS
        Gets the path to Office Deployment Tool setup.exe

    .DESCRIPTION
        Searches for Office Deployment Tool (setup.exe) in common installation locations.
        Checks both Program Files and Program Files (x86) directories.

    .OUTPUTS
        Returns the full path to setup.exe if found, otherwise returns $null

    .EXAMPLE
        $odtPath = Get-OfficeDeploymentToolPath
        if ($odtPath) {
            Write-Host "Office Deployment Tool found at: $odtPath"
            & $odtPath /configure config.xml
        }

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdletBinding()]
    Param()

    # Common installation paths to check
    $searchPaths = @(
        "${env:ProgramFiles(x86)}\OfficeDeploymentTool\setup.exe",
        "$env:ProgramFiles\OfficeDeploymentTool\setup.exe",
        "${env:ProgramFiles(x86)}\Office Deployment Tool\setup.exe",
        "$env:ProgramFiles\Office Deployment Tool\setup.exe"
    )

    # Check each path
    foreach ($path in $searchPaths) {
        if (Test-Path $path) {
            Write-Verbose "Office Deployment Tool found at: $path"
            return $path
        }
    }

    # If not found in common paths, search in Program Files directories
    Write-Verbose "Searching for Office Deployment Tool in Program Files directories..."

    $programFilesDirs = @(
        ${env:ProgramFiles(x86)},
        $env:ProgramFiles
    )

    foreach ($programFilesDir in $programFilesDirs) {
        if (Test-Path $programFilesDir) {
            # Search for directories containing "Office" and "Deployment"
            $odtDirs = Get-ChildItem -Path $programFilesDir -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match 'Office.*Deploy|Deploy.*Office' }

            foreach ($dir in $odtDirs) {
                $setupPath = Join-Path $dir.FullName "setup.exe"
                if (Test-Path $setupPath) {
                    # Verify it's actually ODT by checking file description or version
                    try {
                        $fileInfo = Get-Item $setupPath
                        $versionInfo = $fileInfo.VersionInfo

                        # Office Deployment Tool setup.exe usually has "Office" in its description
                        if ($versionInfo.FileDescription -match 'Office|Microsoft') {
                            Write-Verbose "Office Deployment Tool found at: $setupPath"
                            return $setupPath
                        }
                    }
                    catch {
                        Write-Verbose "Could not verify file at: $setupPath"
                    }
                }
            }
        }
    }

    Write-Verbose "Office Deployment Tool not found"
    return $null
}
