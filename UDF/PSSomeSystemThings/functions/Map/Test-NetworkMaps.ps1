function Test-NetworkMaps {
    <#
    .SYNOPSIS
        Tests the availability of network drive mappings

    .DESCRIPTION
        Checks an array of drive definitions and returns the ratio of accessible drives.
        Supports %username% placeholder in the Root property.

    .PARAMETER Drives
        Array of hashtables with Name and Root keys defining expected drive mappings.

    .OUTPUTS
        [double]. Ratio of found drives (0.0 to 1.0).

    .EXAMPLE
        Test-NetworkMaps -Drives @(@{Name="Z"; Root="\\server\share"})

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    Param(
        [hashtable[]]$Drives
    )
    $iFound = 0
    foreach ($item in $Drives) {
        $item.Root = $item.Root -replace "%username%",$env:USERNAME
        if (Test-PSDrive @item) {
            $iFound += 1
        }
    }
    return ($iFound / $Drives.Count)
}