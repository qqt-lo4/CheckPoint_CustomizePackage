function Test-StringEnd {
    <#
    .SYNOPSIS
        Tests if a string ends with any of the specified suffixes

    .DESCRIPTION
        Checks whether the input string ends with any of the provided suffix strings.
        Returns the matching suffix if found, or $false if none match.

    .PARAMETER InputString
        The string to test. Accepts pipeline input.

    .PARAMETER StringEnd
        An array of suffixes to check against.

    .OUTPUTS
        System.String or System.Boolean. The matching suffix, or $false if no match.

    .EXAMPLE
        "document.pdf" | Test-StringEnd -StringEnd ".pdf", ".docx"
        # Returns ".pdf"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$InputString,
        [Parameter(Mandatory, Position = 1)]
        [string[]]$StringEnd
    )
    for ($i = 0; $i -lt $StringEnd.Count; $i++) {
        if ($InputString -like "*$($StringEnd[$i])") {
            return $StringEnd[$i]
        }
    }
    return $false
}