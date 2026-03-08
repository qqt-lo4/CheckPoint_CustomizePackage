function Get-CurrentLocale {
    <#
    .SYNOPSIS
        Gets the current locale for the application

    .DESCRIPTION
        Determines the locale from configuration file, environment variable,
        or system culture (in that order)

    .EXAMPLE
        $locale = Get-CurrentLocale
        # Returns: "fr-FR" or "en-US"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdletBinding()]
    Param()

    # 1. Check global locale override (set during language change in UI)
    if ($global:OverrideLocale -and ($global:OverrideLocale -ne "")) {
        return $global:OverrideLocale
    }

    # 2. Check environment variable (for external override)
    if ($env:APP_LOCALE -and ($env:APP_LOCALE -ne "")) {
        return $env:APP_LOCALE
    }

    # 3. Use system culture
    try {
        $systemLocale = [System.Globalization.CultureInfo]::CurrentUICulture.Name

        # Map common locales
        switch -Wildcard ($systemLocale) {
            "fr*" {
                $result = "fr-FR"
                return $result
            }
            "en*" {
                $result = "en-US"
                return $result
            }
            "de*" {
                $result = "de-DE"
                return $result
            }
            "es*" {
                $result = "es-ES"
                return $result
            }
            "it*" {
                $result = "it-IT"
                return $result
            }
            "pt*" {
                $result = "pt-BR"
                return $result
            }
            "ja*" {
                $result = "ja-JP"
                return $result
            }
            "zh-CN*" {
                $result = "zh-CN"
                return $result
            }
            "zh-TW*" {
                $result = "zh-TW"
                return $result
            }
            default {
                $result = "en-US"
                return $result
            }
        }
    }
    catch {
        # If all else fails, return en-US
        return "en-US"
    }
}
