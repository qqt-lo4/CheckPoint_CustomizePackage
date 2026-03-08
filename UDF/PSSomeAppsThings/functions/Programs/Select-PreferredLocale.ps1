function Select-PreferredLocale {
    <#
    .SYNOPSIS
        Filters objects to select the preferred locale based on system language
    
    .DESCRIPTION
        Takes a collection of objects with an InstallerLocale property and returns the object
        matching the most preferred compatible locale for the current system.
        Uses Get-LocaleFormats to determine priority order.
        
        Priority order:
        1. Exact match (e.g., fr-FR)
        2. Language match (e.g., fr)
        3. English US (en-US) as fallback
        4. English (en) as fallback
    
    .PARAMETER InputObject
        Array of objects containing a locale property
    
    .PARAMETER LocaleProperty
        Name of the property containing the locale value.
        Default: 'InstallerLocale'
    
    .PARAMETER UseEnglishFallback
        If specified, uses English (en-US, en) as fallback when system locale is not found.
        Default: $true
    
    .EXAMPLE
        $installers | Select-PreferredLocale
        Returns the installer with the most preferred locale
    
    .EXAMPLE
        Select-PreferredLocale -InputObject $packages -LocaleProperty 'Language'
        Uses custom property name 'Language' instead of 'InstallerLocale'
    
    .EXAMPLE
        $preferred = $installers | Select-PreferredLocale -UseEnglishFallback:$false
        Disables English fallback
    
    .EXAMPLE
        $preferred = $installers | Select-PreferredLocale
        if ($preferred) {
            Write-Host "Selected locale: $($preferred.InstallerLocale)"
        }

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
        [string]$LocaleProperty = 'InstallerLocale',
        
        [Parameter(Mandatory = $false)]
        [bool]$UseEnglishFallback = $true
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
            return $null
        }
        
        # Get system locale preferences
        $systemLocale = Get-LocaleFormats
        
        # Build preference order: Full (e.g., fr-FR), Short (e.g., fr), then English fallback
        $preferredOrder = @()
        
        # Add system locale (full and short)
        if ($systemLocale.Full) {
            $preferredOrder += $systemLocale.Full
        }
        if ($systemLocale.Short -and $systemLocale.Short -ne $systemLocale.Full) {
            $preferredOrder += $systemLocale.Short
        }
        
        # Add English fallback if enabled
        if ($UseEnglishFallback) {
            $preferredOrder += 'en-US'
            $preferredOrder += 'en'
        }
        
        Write-Verbose "Locale preference order: $($preferredOrder -join ' > ')"
        
        # Normalize locale names for comparison (case-insensitive)
        $normalizedPreferences = $preferredOrder | ForEach-Object { $_.ToLower() }
        
        # Try each preferred locale in order
        foreach ($preferredLocale in $normalizedPreferences) {
            Write-Verbose "Looking for locale: $preferredLocale"
            
            # Find first object matching this locale
            $match = $allObjects | Where-Object {
                $localeValue = $_.$LocaleProperty
                if ($null -eq $localeValue) {
                    return $false
                }
                $localeValue.ToLower() -eq $preferredLocale
            } | Select-Object -First 1
            
            if ($match) {
                Write-Verbose "Found match with locale: $($match.$LocaleProperty)"
                return $match
            }
        }
        
        # No compatible locale found
        Write-Warning "No compatible locale found in provided objects"
        $availableLocales = $allObjects.$LocaleProperty | Where-Object { $_ } | Sort-Object -Unique
        Write-Warning "Available locales: $($availableLocales -join ', ')"
        Write-Warning "System locale: $($systemLocale.Full) ($($systemLocale.Short))"
        
        return $null
    }
}
