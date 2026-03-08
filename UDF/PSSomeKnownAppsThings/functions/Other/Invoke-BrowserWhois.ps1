function Invoke-BrowserWhois {
    <#
    .SYNOPSIS
        Opens a WHOIS lookup in the browser

    .DESCRIPTION
        Opens whois.com in the default browser for the specified domain or IP.

    .PARAMETER Target
        The domain name or IP address to look up.

    .EXAMPLE
        Invoke-BrowserWhois "example.com"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Target
    )
    Invoke-Browser "https://www.whois.com/whois/$Target" | Out-Null
}
