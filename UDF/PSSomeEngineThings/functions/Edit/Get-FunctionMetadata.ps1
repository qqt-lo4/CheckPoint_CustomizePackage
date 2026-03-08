function Get-FunctionMetadata {
    <#
    .SYNOPSIS
        Extracts module and dependency metadata from a PowerShell script file.

    .DESCRIPTION
        Parses a PowerShell script file to extract the Module and Dependencies properties
        from the comment-based help block within the function definition.

    .PARAMETER FilePath
        The full path to the PowerShell script file to parse.

    .OUTPUTS
        Returns a custom object with the following properties:
        - FilePath: Full path to the file
        - FileName: Name of the file
        - FunctionName: Name of the function (extracted from function declaration)
        - Module: Array of module names from the Module property
        - Dependencies: Array of dependency function names from the Dependencies property
        - HasMetadata: Boolean indicating if Module metadata was found

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop

        # Initialize result object
        $result = [PSCustomObject]@{
            FilePath      = $FilePath
            FileName      = Split-Path -Path $FilePath -Leaf
            FunctionName  = $null
            Module        = @()
            Dependencies  = @()
            HasMetadata   = $false
        }

        # Extract function name
        if ($content -match 'function\s+([\w-]+)\s*\{') {
            $result.FunctionName = $Matches[1]
        }

        # Extract Module property from .NOTES section
        # Pattern: "Module:" followed by one or more module names (space-separated)
        if ($content -match '(?ms)\.NOTES.*?Module:\s*([^\r\n]+)') {
            $moduleString = $Matches[1].Trim()
            # Split by spaces to support multiple modules
            $result.Module = $moduleString -split '\s+' | Where-Object { $_ -ne '' }
            $result.HasMetadata = $true
        }

        # Extract Dependencies property from .NOTES section
        # Pattern: "Dependencies:" followed by function names (comma or space-separated) or "None"
        if ($content -match '(?ms)\.NOTES.*?Dependencies:\s*([^\r\n]+)') {
            $dependencyString = $Matches[1].Trim()

            # Check if dependencies are "None"
            if ($dependencyString -ne 'None') {
                # Split by comma or space, clean up whitespace
                $result.Dependencies = $dependencyString -split '[,\s]+' |
                    Where-Object { $_ -ne '' -and $_ -ne 'None' }
            }
        }

        return $result
    }
    catch {
        Write-Warning "Failed to parse file '$FilePath': $_"
        return $null
    }
}
