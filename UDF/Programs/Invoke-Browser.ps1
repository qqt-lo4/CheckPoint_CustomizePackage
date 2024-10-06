function Invoke-Browser {
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