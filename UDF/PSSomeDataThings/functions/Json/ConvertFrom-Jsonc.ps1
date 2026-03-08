function ConvertFrom-Jsonc {
    <#
    .SYNOPSIS
        Converts JSONC (JSON with Comments) to a PowerShell object

    .DESCRIPTION
        Strips single-line (//) and multi-line (/* */) comments from JSONC text
        before passing it to ConvertFrom-Json.

    .PARAMETER inputText
        The JSONC string to parse

    .OUTPUTS
        PSCustomObject. The parsed JSON object.

    .EXAMPLE
        Get-Content "config.jsonc" -Raw | ConvertFrom-Jsonc

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, ValueFromPipeline = $true, Position = 0)]
        [string]$inputText
    )
    $jsonResult = $inputText -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/'
    $jsonResult | ConvertFrom-Json
}