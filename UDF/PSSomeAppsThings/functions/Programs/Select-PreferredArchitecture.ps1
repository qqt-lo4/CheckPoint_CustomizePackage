function Select-PreferredArchitecture {
    <#
    .SYNOPSIS
        Filters objects to select all packages with the preferred architecture based on system compatibility
    
    .DESCRIPTION
        Takes a collection of objects with an Architecture property and returns ALL objects
        matching the most preferred compatible architecture for the current system.
        Uses Get-SystemArchitecture to determine priority order.
        
        Architecture priority order:
        1. Native architecture (e.g., x64 on x64 system) - Best performance, platform-specific optimizations
        2. Neutral architecture - Universal packages that may contain multiple architectures or managed code
        3. Compatible fallback architectures (e.g., x86 on x64 system) - Works but with limitations
        
        Neutral is prioritized over fallback architectures because neutral packages often contain
        optimized code for multiple architectures or are universal packages that adapt at runtime.
        
        Unlike selecting a single object, this returns all packages with the first compatible
        architecture found, allowing further filtering by locale or other criteria.
    
    .PARAMETER InputObject
        Array of objects containing an Architecture property
    
    .PARAMETER ArchitectureProperty
        Name of the property containing the architecture value.
        Default: 'Architecture'
    
    .EXAMPLE
        $installers | Select-PreferredArchitecture
        Returns ALL installers with the most preferred architecture
    
    .EXAMPLE
        $archFiltered = $installers | Select-PreferredArchitecture
        $preferred = $archFiltered | Select-PreferredLocale
        Filter by architecture first, then by locale
    
    .EXAMPLE
        Select-PreferredArchitecture -InputObject $packages -ArchitectureProperty 'Arch'
        Uses custom property name 'Arch' instead of 'Architecture'

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyCollection()]
        [object[]]$InputObject,
        
        [Parameter(Mandatory = $false)]
        [string]$ArchitectureProperty = 'Architecture'
    )
    
    begin {
        $allObjects = @()
    }
    
    process {
        $allObjects += $InputObject
    }
    
    end {
        # Check if we have objects
        if ($allObjects.Count -eq 0) {
            Write-Warning "No objects provided to filter"
            return @()
        }
        
        # Get system architecture preferences
        $systemArch = Get-SystemArchitecture -ExtendedInfo
        
        # Build preference order:
        # 1. Primary architecture (native, best performance)
        # 2. Neutral (may contain multiple architectures or universal code)
        # 3. Fallback architectures (compatible but with limitations)
        $preferredOrder = @($systemArch.Primary) + @('neutral') + $systemArch.Fallback
        
        Write-Verbose "Architecture preference order: $($preferredOrder -join ' > ')"
        
        # Normalize architecture names for comparison (case-insensitive)
        $normalizedPreferences = $preferredOrder | ForEach-Object { $_.ToLower() }
        
        # Try each preferred architecture in order
        foreach ($preferredArch in $normalizedPreferences) {
            Write-Verbose "Looking for architecture: $preferredArch"
            
            # Find ALL objects matching this architecture
            $matches = $allObjects | Where-Object {
                $archValue = $_.$ArchitectureProperty
                if ($null -eq $archValue) {
                    return $false
                }
                $archValue.ToLower() -eq $preferredArch
            }
            
            if ($matches) {
                $matchCount = ($matches | Measure-Object).Count
                Write-Verbose "Found $matchCount package(s) with architecture: $preferredArch"
                return $matches
            }
        }
        
        # No compatible architecture found
        Write-Warning "No compatible architecture found in provided objects"
        $availableArchs = $allObjects.$ArchitectureProperty | Where-Object { $_ } | Sort-Object -Unique
        Write-Warning "Available architectures: $($availableArchs -join ', ')"
        Write-Warning "System supports: $($preferredOrder -join ', ')"
        
        return @()
    }
}
