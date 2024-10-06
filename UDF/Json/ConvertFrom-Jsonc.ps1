function ConvertFrom-Jsonc {
    Param(
        [Parameter(Mandatory, ValueFromPipeline = $true, Position = 0)]
        [string]$inputText
    )
    $jsonResult = $inputText -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/'
    $jsonResult | ConvertFrom-Json
}