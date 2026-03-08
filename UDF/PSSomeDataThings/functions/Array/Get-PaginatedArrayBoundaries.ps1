function Get-PaginatedArrayBoundaries {
    <#
    .SYNOPSIS
        Gets index boundaries for a paginated array

    .DESCRIPTION
        Returns pagination metadata for an array: first/last page numbers,
        first/last item indexes for the requested page, item count, and total page count.
        If no page is specified (Page = -1), returns boundaries for the entire array.

    .PARAMETER Objects
        The array to paginate

    .PARAMETER Page
        Zero-based page number (-1 for entire array, default: -1)

    .PARAMETER ItemsPerPage
        Number of items per page (default: 10)

    .OUTPUTS
        PSCustomObject with FirstPage, LastPage, PageFirstItemIndex, PageLastItemIndex,
        PageItemCount, and PageCount properties.

    .EXAMPLE
        Get-PaginatedArrayBoundaries -Objects (1..100) -Page 3 -ItemsPerPage 10

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        All results and parameters are 0-based.
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [object[]]$Objects,
        [ValidateScript({$_ -ge -1})]
        [int]$Page = -1,
        [ValidateScript({$_ -ge 1})]
        [int]$ItemsPerPage = 10
    )
    if (($Page -gt 0) -and (($Page * $ItemsPerPage) -gt $Objects.Count)) {
        throw [System.IndexOutOfRangeException] "Page number too high"
    }
    $iFirstPage = 0
    $iLastPage = if ($Page -eq -1) { 
        0
    } else {
        [Math]::Floor(($Objects.Count -1) / $ItemsPerPage)
    }
    $iPageFirstItemIndex = if ($Page -eq -1) { 0 } else { $Page * $ItemsPerPage }
    $iPageLastItemIndex = if (($Page -eq -1) -or ($Page -eq $iLastPage)) { $Objects.Count - 1 } else { ($Page + 1) * $ItemsPerPage - 1 }
    return [PSCustomObject]@{
        FirstPage = $iFirstPage
        LastPage = $iLastPage
        PageFirstItemIndex = $iPageFirstItemIndex
        PageLastItemIndex = $iPageLastItemIndex
        PageItemCount = $iPageLastItemIndex - $iPageFirstItemIndex + 1
        PageCount = $iLastPage + 1
    }
}
