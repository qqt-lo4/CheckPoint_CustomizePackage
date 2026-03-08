function Get-QueryRegex {
    <#
    .SYNOPSIS
        Returns a regex pattern for matching URI query strings

    .DESCRIPTION
        Generates a regex pattern that matches the query component of a URI,
        starting with '?' followed by valid query characters (RFC 3986).

    .OUTPUTS
        System.String. The regex pattern with a named capture group 'Query'.

    .EXAMPLE
        $pattern = Get-QueryRegex
        "?key=value" -match $pattern

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    $queryChars = "(?:[a-zA-Z0-9._~!$&'()*+,;=:@/?-]|%[0-9a-fA-F]{2})"
    return "(?<Query>\?$queryChars*)?"
}
