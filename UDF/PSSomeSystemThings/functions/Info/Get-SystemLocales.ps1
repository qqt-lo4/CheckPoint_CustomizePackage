function Get-SystemLocales {
    <#
    .SYNOPSIS
        Retrieves system locales in various formats

    .DESCRIPTION
        Returns the current system locale information in multiple formats
        (full culture, short language code, etc.)

    .OUTPUTS
        [PSCustomObject]. Object containing locale details (CurrentCulture, TwoLetterISOLanguageName, LCID, etc.)

    .EXAMPLE
        Get-SystemLocales
        Returns an object with all system locales.

    .EXAMPLE
        (Get-SystemLocales).CurrentCulture
        Returns the current culture (e.g., fr-FR).

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    
    [CmdletBinding()]
    param()
    
    # Retrieve cultures
    $currentCulture = [System.Globalization.CultureInfo]::CurrentCulture
    $currentUICulture = [System.Globalization.CultureInfo]::CurrentUICulture
    $installedUICulture = [System.Globalization.CultureInfo]::InstalledUICulture
    
    # Build return object
    $localeInfo = [PSCustomObject]@{
        # Current culture (e.g., fr-FR)
        CurrentCulture = $currentCulture.Name
        
        # User interface culture (e.g., fr-FR)
        CurrentUICulture = $currentUICulture.Name
        
        # Installed UI culture (e.g., fr-FR)
        InstalledUICulture = $installedUICulture.Name
        
        # Short language code - 2 letters (e.g., fr)
        TwoLetterISOLanguageName = $currentCulture.TwoLetterISOLanguageName
        
        # ISO 639-2 language code - 3 letters (e.g., fra)
        ThreeLetterISOLanguageName = $currentCulture.ThreeLetterISOLanguageName
        
        # Windows language code (e.g., FRA)
        ThreeLetterWindowsLanguageName = $currentCulture.ThreeLetterWindowsLanguageName
        
        # English name (e.g., French (France))
        EnglishName = $currentCulture.EnglishName
        
        # Native name (e.g., français (France))
        NativeName = $currentCulture.NativeName
        
        # Display name (e.g., French (France))
        DisplayName = $currentCulture.DisplayName
        
        # LCID (Locale ID) (e.g., 1036 for fr-FR)
        LCID = $currentCulture.LCID
        
        # Region information
        RegionName = $currentCulture.Name.Split('-')[-1]  # e.g., FR
        
        # Parent culture (e.g., fr)
        ParentCulture = if ($currentCulture.Parent.Name) { 
            $currentCulture.Parent.Name 
        } else { 
            $null 
        }
        
        # Full culture info
        FullCultureInfo = $currentCulture
    }
    
    return $localeInfo
}
