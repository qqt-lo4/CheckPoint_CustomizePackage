function Set-CurrentLocale {
    <#
    .SYNOPSIS
        Sets the locale for the application

    .DESCRIPTION
        Saves the locale preference to the configuration file

    .PARAMETER Locale
        Locale code (e.g., "fr-FR", "en-US")

    .EXAMPLE
        Set-CurrentLocale -Locale "en-US"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("fr-FR", "en-US", "de-DE", "es-ES", "it-IT", "pt-BR", "ja-JP", "zh-CN", "zh-TW")]
        [string]$Locale
    )

    try {
        # Get config file path
        $configFile = Get-RootScriptConfigFile

        # Load or create config
        if (Test-Path $configFile) {
            $config = Get-Content -Path $configFile -Raw | ConvertFrom-Json -AsHashtable
        }
        else {
            $config = @{}
        }

        # Update locale
        $config.Locale = $Locale

        # Save config
        $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configFile -Encoding UTF8

        # Clear translation cache to force reload
        $script:TranslationCache = @{}

        Write-Verbose "Locale set to: $Locale"
    }
    catch {
        throw "Failed to save locale preference: $_"
    }
}
