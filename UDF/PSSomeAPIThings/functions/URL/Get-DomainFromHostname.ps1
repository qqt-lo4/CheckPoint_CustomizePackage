function Get-DomainFromHostname {
    <#
    .SYNOPSIS
        Extracts the domain name from a hostname

    .DESCRIPTION
        Parses a hostname string to extract the domain portion (removing the
        first subdomain label if present). For a two-part hostname, returns
        it as-is.

    .PARAMETER Hostname
        The hostname to extract the domain from. Accepts pipeline input.

    .OUTPUTS
        [string]. The domain name.

    .EXAMPLE
        Get-DomainFromHostname -Hostname "mail.example.com"
        # Returns "example.com"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$Hostname
    )
    $domainregex = "^(?<domain>[^.]+\.[^.]+)$|(^[^.]+\.(?<domain>([^.]+\.)*.+)$)"
    $ss = Select-String -InputObject $Hostname -Pattern $domainregex
    return ($ss.Matches.Groups | Where-Object { $_.Name -eq "domain" }).Value
}