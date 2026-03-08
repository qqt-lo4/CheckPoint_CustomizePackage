function Invoke-Browser {
    <#
    .SYNOPSIS
        Opens a URL in a web browser

    .DESCRIPTION
        Opens a URL in the default browser or a specific browser (Edge,
        Firefox, Internet Explorer, or Chrome).

    .PARAMETER Url
        The URL to open.

    .PARAMETER Edge
        Open in Microsoft Edge.

    .PARAMETER Firefox
        Open in Mozilla Firefox.

    .PARAMETER InternetExplorer
        Open in Internet Explorer.

    .PARAMETER Chrome
        Open in Google Chrome.

    .EXAMPLE
        Invoke-Browser "https://example.com"

    .EXAMPLE
        Invoke-Browser "https://example.com" -Edge

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdletBinding(DefaultParameterSetName = "All")]
    Param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = "All")]
        [Parameter(Mandatory, Position = 0, ParameterSetName = "msedge")]
        [Parameter(Mandatory, Position = 0, ParameterSetName = "firefox")]
        [Parameter(Mandatory, Position = 0, ParameterSetName = "iexplore")]
        [Parameter(Mandatory, Position = 0, ParameterSetName = "chrome")]
        [String]$Url,
        [Parameter(ParameterSetName = "msedge")]
        [switch]$Edge,
        [Parameter(ParameterSetName = "firefox")]
        [switch]$Firefox,
        [Parameter(ParameterSetName = "iexplore")]
        [Alias("IE")]
        [switch]$InternetExplorer,
        [Parameter(ParameterSetName = "chrome")]
        [switch]$Chrome
    )
    switch ($PSCmdlet.ParameterSetName) {
        "All" {
            [system.Diagnostics.Process]::Start($Url)
        }
        Default {
            [system.Diagnostics.Process]::Start($PSCmdlet.ParameterSetName, $Url)
        }
    }
}