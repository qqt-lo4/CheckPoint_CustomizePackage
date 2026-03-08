function Get-LocaleFormats {
    <#
    .SYNOPSIS
        Retrieves locale formats (fr-FR, fr, etc.)

    .DESCRIPTION
        Returns the current system locale in various format representations
        including full culture name, short language code, ISO3, region, and LCID.

    .OUTPUTS
        [PSCustomObject]. Object with Full, Short, ISO3, Region, and LCID properties.

    .EXAMPLE
        Get-LocaleFormats
        Returns: @{Full='fr-FR'; Short='fr'; ISO3='fra'; Region='FR'; LCID=1036}

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    
    [CmdletBinding()]
    param()
    
    $culture = [System.Globalization.CultureInfo]::CurrentCulture
    
    return [PSCustomObject]@{
        Full   = $culture.Name                              # fr-FR
        Short  = $culture.TwoLetterISOLanguageName         # fr
        ISO3   = $culture.ThreeLetterISOLanguageName       # fra
        Region = $culture.Name.Split('-')[-1]              # FR
        LCID   = $culture.LCID                             # 1036
    }
}
