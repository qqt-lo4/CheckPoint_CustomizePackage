function Get-URLObject {
    <#
    .SYNOPSIS
        Parses a URL into its components including decoded query parameters

    .DESCRIPTION
        Decomposes a URL into protocol, hostname, command (path), and query arguments.
        Query parameter values are URL-decoded and HTML-decoded automatically.

    .PARAMETER urlcommand
        The URL string to parse.

    .OUTPUTS
        [hashtable]. Contains protocol, hostname, urlhost, command, url, urlhostcommand,
        argumentstostring, and arguments (decoded hashtable) properties.

    .EXAMPLE
        Get-URLObject -urlcommand "https://api.example.com/v1/search?q=hello%20world&page=1"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [string]$urlcommand
    )
    Process {
        if ($urlcommand -match "^((([a-z-A-Z]+):\/\/)?([^\/]+)\/)?([^?]*)(\?(.*))$") {
            $result = @{
                protocol = $Matches.3
                hostname = $Matches.4
                urlhost = $Matches.1
                command = $Matches.5
                url = $urlcommand
                urlhostcommand = $Matches.1 + $Matches.5
                argumentstostring = $Matches.7
            }
            [hashtable]$arguments = @{}
            $Matches.7 -split "&" | ForEach-Object {  
                if ($_ -match "^([^=]+)=(.+)$") {
                    $arguments.Add($Matches.1, [System.Web.HttpUtility]::HtmlDecode([System.Web.HttpUtility]::UrlDecode($Matches.2)))
                }
            }
            $result.Add("arguments", $arguments)
            return $result
        }    
    }
}