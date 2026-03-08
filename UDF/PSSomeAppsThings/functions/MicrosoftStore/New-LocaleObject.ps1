function New-LocaleObject {
    <#
    .SYNOPSIS
    Creates a new Locale object
    
    .DESCRIPTION
        Creates a hashtable-based Locale with market, language, and DCat trail properties.
        The DCatTrail property is formatted for use with the DisplayCatalog API query string.

    .PARAMETER Market
        Market code (e.g., US, FR, DE)

    .PARAMETER Language
        Language code (e.g., en-US, fr-FR)

    .PARAMETER IncludeNeutral
        Whether to include 'neutral' in the language trail for broader compatibility

    .OUTPUTS
        Hashtable with Market, Language, UseWWW, and DCatTrail properties

    .EXAMPLE
        $locale = New-LocaleObject -Market "US" -Language "en-US" -IncludeNeutral $true
        # $locale.DCatTrail = "market=US&languages=en-US-US,en-US,neutral"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    param(
        [string]$Market,
        [string]$Language,
        [bool]$IncludeNeutral
    )
    
    $locale = @{
        Market = $Market
        Language = $Language
        UseWWW = $IncludeNeutral
    }
    
    # Exact StoreLib format: languages={lang}-{market},{lang},neutral
    if ($IncludeNeutral) {
        $locale.DCatTrail = "market=$Market&languages=$Language-$Market,$Language,neutral"
    }
    else {
        $locale.DCatTrail = "market=$Market&languages=$Language-$Market,$Language"
    }
    
    return $locale
}
