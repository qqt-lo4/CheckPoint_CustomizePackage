function ConvertTo-URLArguments {
    <#
    .SYNOPSIS
        Converts a hashtable to a URL-encoded query string

    .DESCRIPTION
        Serializes a hashtable into URL query string format. Handles nested hashtables
        by JSON-encoding them, booleans by converting to "1"/"0" or "true"/"false",
        and other values by URL-encoding them.

    .PARAMETER Arguments
        The hashtable of key-value pairs to convert. Accepts pipeline input.

    .PARAMETER Recurse
        If specified, recursively processes nested hashtables.

    .PARAMETER BoolToString
        If specified, converts boolean values to "true"/"false" instead of "1"/"0".

    .OUTPUTS
        [string]. The URL-encoded query string (without leading "?").

    .EXAMPLE
        ConvertTo-URLArguments -Arguments @{ search = "hello world"; active = $true }

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Position = 0, ValueFromPipeline)]
        [hashtable]$Arguments,
        [switch]$Recurse,
        [switch]$BoolToString
    )

    $sArguments = ""

    foreach ($key in $Arguments.Keys) {
        $sValue = if ($Arguments[$key] -is [hashtable]) {
            [System.Web.HttpUtility]::UrlEncode((ConvertTo-JsonRecursive -InputObject $Arguments[$key] -Compress))
        } else {
            if ($Arguments[$key] -is [bool]) {
                if ($BoolToString) {
                    $Arguments[$key].ToString().ToLower()
                } else {
                    if ($Arguments[$key]) { "1" } else { "0" }
                }
            } else {
                [System.Web.HttpUtility]::UrlEncode($Arguments[$key]) 
            }
        }
        if ($sArguments -ne "") {
            $sArguments += "&"
        }
        $sArguments += "$key=$sValue"
    }

    return $sArguments
}
