function Get-PathRegex {
    <#
    .SYNOPSIS
        Returns a regex pattern for matching URI paths

    .DESCRIPTION
        Generates a regex pattern for the path component of a URI
        with a named capture group "Path".

    .OUTPUTS
        System.String. The regex pattern.

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    $pathChars = "(?:[a-zA-Z0-9._~!$&'()*+,;=:@/-]|%[0-9a-fA-F]{2})"
    return "(?<Path>(?:/$pathChars*)*)"
}
