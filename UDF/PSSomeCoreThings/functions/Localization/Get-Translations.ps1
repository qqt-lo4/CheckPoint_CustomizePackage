function Get-Translations {
    <#
    .SYNOPSIS
        Loads translation data from JSON files

    .DESCRIPTION
        Reads and caches translation files for the specified locale.
        Falls back to en-US if locale file is not found.

    .PARAMETER Locale
        Locale code (e.g., "fr-FR", "en-US")

    .PARAMETER Force
        Force reload from disk (bypass cache)

    .EXAMPLE
        Get-Translations -Locale "fr-FR"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Locale,

        [Parameter(Mandatory=$false)]
        [switch]$Force
    )

    # Cache translations in script scope
    if (-not $script:TranslationCache) {
        $script:TranslationCache = @{}
    }

    # Return from cache if available
    if (-not $Force -and $script:TranslationCache.ContainsKey($Locale)) {
        return $script:TranslationCache[$Locale]
    }

    # Determine locales directory using Get-ScriptDir -InputDir
    $inputDir = Get-ScriptDir -InputDir
    $localesDir = Join-Path $inputDir "lang"

    # Build file path
    $localeFile = Join-Path $localesDir "$Locale.json"

    # Fallback to en-US if file doesn't exist
    if (-not (Test-Path $localeFile)) {
        Write-Verbose "Locale file not found: $localeFile. Falling back to en-US."
        $Locale = "en-US"
        $localeFile = Join-Path $localesDir "$Locale.json"

        if (-not (Test-Path $localeFile)) {
            throw "Default locale file (en-US.json) not found in: $localesDir"
        }
    }

    # Load JSON
    try {
        $jsonContent = Get-Content -Path $localeFile -Raw -Encoding UTF8
        $translations = $jsonContent | ConvertFrom-Json | ConvertTo-Hashtable #-AsHashtable

        # Cache translations
        $script:TranslationCache[$Locale] = $translations

        Write-Verbose "Loaded translations for locale: $Locale"
        return $translations
    }
    catch {
        throw "Failed to load translations from ${localeFile}: $_"
    }
}
