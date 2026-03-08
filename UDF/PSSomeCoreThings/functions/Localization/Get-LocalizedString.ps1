function Get-LocalizedString {
    <#
    .SYNOPSIS
        Retrieves a localized string from the translation resources

    .DESCRIPTION
        Loads translation from JSON files based on current locale and returns
        the translated string with optional parameter substitution

    .PARAMETER Key
        The translation key in dot notation (e.g., "UI.WindowTitle")

    .PARAMETER Parameters
        Optional array of parameters to substitute in the translated string

    .PARAMETER Locale
        Locale code (default: auto-detect from system or config)

    .EXAMPLE
        Get-LocalizedString "UI.WindowTitle"
        Returns: "Software Installation Manager" (if locale is en-US)

    .EXAMPLE
        Get-LocalizedString "Console.Success" -Parameters @("Chrome")
        Returns: "✓ Chrome installed successfully"

    .EXAMPLE
        Get-LocalizedString "UI.InstallButton" -Parameters @(3)
        Returns: "Install 3 software" (handles pluralization)

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Key,

        [Parameter(Mandatory=$false)]
        [array]$Parameters,

        [Parameter(Mandatory=$false)]
        [string]$Locale
    )

    # Get locale if not specified
    if (-not $Locale) {
        $Locale = Get-CurrentLocale
    }

    # Load translations (cached)
    $translations = Get-Translations -Locale $Locale

    # Navigate through key path
    $keyParts = $Key -split '\.'
    $value = $translations

    foreach ($part in $keyParts) {
        if ((($value -is [hashtable]) -or ($value -is [System.Collections.Specialized.OrderedDictionary])) -and ($part -in $value.Keys)) {
            $value = $value[$part]
        }
        else {
            Write-Warning "Translation key not found: $Key (Locale: $Locale)"
            return $Key
        }
    }

    # Handle pluralization (if value contains |)
    if ($value -match '\|' -and $Parameters -and $Parameters.Count -gt 0) {
        $forms = $value -split '\|'
        $count = $Parameters[0]

        # Select form based on count (simple rule: 0-1 = singular, 2+ = plural)
        if ($count -eq 0 -or $count -eq 1) {
            $value = $forms[0]
        }
        else {
            $value = if ($forms.Count -gt 1) { $forms[1] } else { $forms[0] }
        }
    }

    # Substitute parameters
    if ($Parameters -and $Parameters.Count -gt 0) {
        for ($i = 0; $i -lt $Parameters.Count; $i++) {
            $value = $value -replace "\{$i\}", $Parameters[$i]
        }
    }

    return $value
}

# Shorthand alias
Set-Alias -Name 'tr' -Value 'Get-LocalizedString' -Scope Global -Force
