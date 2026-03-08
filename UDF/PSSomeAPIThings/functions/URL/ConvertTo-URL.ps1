function ConvertTo-URL {
    <#
    .SYNOPSIS
        Builds a complete URL from a base URL and query parameters

    .DESCRIPTION
        Combines a base URL with a hashtable of arguments to produce a full URL
        with query string. Uses ConvertTo-URLArguments for serialization.

    .PARAMETER URL
        The base URL without query string.

    .PARAMETER Arguments
        A hashtable of query parameters to append.

    .PARAMETER Recurse
        If specified, recursively serializes nested hashtables in the arguments.

    .PARAMETER BoolToString
        If specified, converts boolean values to lowercase strings ("true"/"false").

    .OUTPUTS
        [string]. The complete URL with query string.

    .EXAMPLE
        ConvertTo-URL -URL "https://api.example.com/search" -Arguments @{ q = "test"; page = 1 }

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 1)]
        [string]$URL,
        [Parameter(Position = 1)]
        [hashtable]$Arguments,
        [switch]$Recurse,
        [switch]$BoolToString
    )

    $sArguments = ConvertTo-URLArguments -Arguments $Arguments -Recurse:$Recurse -BoolToString:$BoolToString

    if ($sArguments -ne "") {
        return $URL + "?" + $sArguments
    } else {
        return $URL
    }
}
