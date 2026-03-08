function Get-ArrayPage {
    <#
    .SYNOPSIS
        Returns a specific page of items from an array

    .DESCRIPTION
        Paginates an array and returns the items for the requested page number.
        Can also return the total number of pages with the -Count switch.

    .PARAMETER Objects
        The array of objects to paginate

    .PARAMETER Page
        Zero-based page number to retrieve (default: 0)

    .PARAMETER ItemsPerPage
        Number of items per page (default: 10)

    .PARAMETER Count
        If specified, returns the total number of pages instead of items

    .OUTPUTS
        Object[] or Int. The page items, or page count when -Count is used.

    .EXAMPLE
        1..100 | Get-ArrayPage -Page 2 -ItemsPerPage 10

    .EXAMPLE
        Get-ArrayPage -Objects $data -Count

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
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
