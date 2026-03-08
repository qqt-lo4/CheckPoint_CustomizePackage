function Get-FragmentRegex {
    <#
    .SYNOPSIS
        Returns a regex pattern for matching URI fragments

    .DESCRIPTION
        Generates a regex pattern for the fragment component (#...) of a URI
        with a named capture group "Fragment".

    .OUTPUTS
        System.String. The regex pattern.

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    $fragmentChars = "(?:[a-zA-Z0-9._~!$&'()*+,;=:@/?-]|%[0-9a-fA-F]{2})"
    return "(?<Fragment>#$fragmentChars*)?"
}
