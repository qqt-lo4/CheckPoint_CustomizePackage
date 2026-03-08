function Get-WingetSources {
    <#
    .SYNOPSIS
        Retrieves the list of Winget sources
    
    .DESCRIPTION
        This function uses 'winget source export' to retrieve
        sources and returns them as PowerShell objects
    
    .EXAMPLE
        Get-WingetSources
        
    .EXAMPLE
        $sources = Get-WingetSources
        $sources | Where-Object { $_.Name -eq 'winget' }
        
    .EXAMPLE
        Get-WingetSources | Format-Table Name, Type, Arg

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    
    [CmdletBinding()]
    param()
    
    try {
        # Execute winget source export and capture output
        $output = winget source export 2>&1
        
        # Check if the command succeeded
        if ($LASTEXITCODE -ne 0) {
            throw "Error executing 'winget source export': $output"
        }
        
        # Initialize results array
        $sources = @()
        
        # Parse each line as a separate JSON object
        foreach ($line in $output) {
            # Skip empty lines and non-JSON output
            if ([string]::IsNullOrWhiteSpace($line) -or $line -notmatch '^\{.*\}$') {
                continue
            }
            
            try {
                # Parse the JSON line
                $source = $line | ConvertFrom-Json
                $sources += $source
            }
            catch {
                Write-Warning "Failed to parse line: $line"
            }
        }
        
        return $sources
    }
    catch {
        Write-Error "Error retrieving Winget sources: $_"
        return $null
    }
}