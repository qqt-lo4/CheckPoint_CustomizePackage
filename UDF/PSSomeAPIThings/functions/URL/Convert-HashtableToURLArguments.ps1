function Convert-HashtableToURLArguments {
    <#
    .SYNOPSIS
        Converts a hashtable to a URL query string

    .DESCRIPTION
        Serializes a hashtable into a URL-encoded query string (key=value pairs
        separated by ampersands). Values are URL-encoded using HttpUtility.UrlEncode.

    .PARAMETER Arguments
        The hashtable of key-value pairs to convert.

    .OUTPUTS
        [string]. The URL query string (without leading "?").

    .EXAMPLE
        Convert-HashtableToURLArguments -Arguments @{ name = "John Doe"; page = 1 }
        # Returns "name=John+Doe&page=1"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [hashtable]$Arguments
    )
    $sResult = ""

    foreach ($key in $Arguments.Keys) {
        $sValue = [System.Web.HttpUtility]::UrlEncode($Arguments[$key]) 
        if ($sResult -ne "") {
            $sResult += "&"
        }
        $sResult += "$key=$sValue"
    }

    return $sResult
}
