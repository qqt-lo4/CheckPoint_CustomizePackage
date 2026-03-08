function Get-URLtld {
    <#
    .SYNOPSIS
        Extracts the top-level domain (TLD) from a URL or hostname

    .DESCRIPTION
        Returns the substring after the last dot in a URL or hostname string
        (e.g., "com", "org", "net").

    .PARAMETER url
        The URL or hostname string to extract the TLD from.

    .OUTPUTS
        [string]. The top-level domain.

    .EXAMPLE
        Get-URLtld -url "www.example.com"
        # Returns "com"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Position=0)]
        [ValidateScript({($_ -ne $null) -and ($_ -ne "") -and ($_.Contains("."))})]
        [string]$url
    )
    return $url.Substring($url.LastIndexOf(".") + 1)
}
