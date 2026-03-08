function Copy-Hashtable {
    <#
    .SYNOPSIS
        Creates a shallow copy of a hashtable with optional property filtering

    .DESCRIPTION
        Copies a hashtable, optionally including only specified properties
        or excluding specified properties with the -Not switch.

    .PARAMETER InputObject
        The hashtable to copy

    .PARAMETER Properties
        Optional list of property names to include (or exclude with -Not)

    .PARAMETER Not
        If specified, excludes the listed Properties instead of including them

    .OUTPUTS
        Hashtable. A new hashtable with the selected properties.

    .EXAMPLE
        Copy-Hashtable -InputObject $hash -Properties "Name","Id"

    .EXAMPLE
        Copy-Hashtable -InputObject $hash -Properties "Password" -Not

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]    
        [hashtable]$InputObject,
        [Parameter(Position = 1)]
        [string[]]$Properties = @(),
        [switch]$Not
    )
    $result = @{}
    foreach ($item in $InputObject.Keys) {
        if ($Properties.Count -gt 0) {
            if ($Not) {
                if ($item -notin $Properties) {
                    $result.Add($item, $InputObject[$item])
                }    
            } else {
                if ($item -in $Properties) {
                    $result.Add($item, $InputObject[$item])
                }    
            }
        } else {
            $result.Add($item, $InputObject[$item])
        }
    }
    if ($Not -and ($result.Keys.Count -eq 0)) {
        return $null
    } else {
        return $result
    }
}
