function Copy-Hashtable {
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
