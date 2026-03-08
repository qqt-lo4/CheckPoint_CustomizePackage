function Get-URLDomain {
    <#
    .SYNOPSIS
        Extracts the top-level domain from a URL or hostname

    .DESCRIPTION
        Parses a URL or hostname string to extract the last two dot-separated
        segments (e.g., "example.com" from "www.sub.example.com").

    .PARAMETER url
        The URL or hostname string to extract the domain from.

    .OUTPUTS
        [string]. The domain (last two segments).

    .EXAMPLE
        Get-URLDomain -url "www.sub.example.com"
        # Returns "example.com"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [ValidateScript({($_ -ne $null) -and ($_ -ne "") -and ($_.Contains("."))})]
        [Parameter(Position=0)]
        [string]$url
    )
    $last_dot_index = $url.LastIndexOf(".")
    $before_last_dot_index = $url.LastIndexOf(".", $last_dot_index - 1)
    if ($before_last_dot_index -eq -1) {
        return $url
    } else {
        return $url.Substring($before_last_dot_index + 1)
    }
}