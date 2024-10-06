function Get-ArrayPage {
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [object[]]$Objects,
        [Parameter(ParameterSetName = "Page")]
        [ValidateScript({$_ -ge 0})]
        [int]$Page = 0,
        [Parameter(ParameterSetName = "Page")]
        [ValidateScript({$_ -ge 1})]
        [int]$ItemsPerPage = 10,
        [Parameter(ParameterSetName = "Count")]
        [switch]$Count
    )
    Begin {
        $aObjects = @()
    }
    Process {
        $aObjects += $Objects
    }
    End {
        $iLastPage = [Math]::Floor(($aObjects.Count -1) / $ItemsPerPage)
        if ($Count) {
            return $iLastPage + 1
        } else {
            if (($Page -gt 0) -and (($Page * $ItemsPerPage) -gt $aObjects.Count)) {
                throw [System.IndexOutOfRangeException] "Page number too high"
            }
            $iPageFirstItemIndex = $Page * $ItemsPerPage
            $iPageLastItemIndex = if ($Page -eq $iLastPage) { $aObjects.Count - 1 } else { ($Page + 1) * $ItemsPerPage - 1 }
            $aResult = if ($iPageFirstItemIndex -eq $iPageLastItemIndex) {
                $aObjects[$iPageFirstItemIndex]
            } else {
                $aObjects[$iPageFirstItemIndex..$iPageLastItemIndex]
            }
            return $aResult    
        }
    }
}
