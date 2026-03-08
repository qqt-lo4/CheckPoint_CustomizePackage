function Get-SchemeRegex {
    <#
    .SYNOPSIS
        Returns a regex pattern for matching URI schemes (http, https, ftp, etc.)

    .DESCRIPTION
        Generates a regex pattern that matches the scheme component of a URI
        as defined in RFC 3986 (starts with a letter, followed by letters, digits, +, -, or .).

    .OUTPUTS
        System.String. The regex pattern with a named capture group 'Scheme'.

    .EXAMPLE
        $pattern = Get-SchemeRegex
        "https" -match $pattern

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    return "(?<Scheme>[a-zA-Z][a-zA-Z0-9+.-]*)"
}
