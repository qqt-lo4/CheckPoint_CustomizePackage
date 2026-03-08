function New-ArrayPageExtractor {
    <#
    .SYNOPSIS
        Creates a stateful paginator object for an array

    .DESCRIPTION
        Returns a PSCustomObject that wraps an array with navigation methods for pagination:
        GetPage(), GetCurrentPage(), GoToNextPage(), GoToPreviousPage(), etc.
        Optionally sorts the array before pagination.

    .PARAMETER Objects
        The array of objects to paginate

    .PARAMETER ItemsPerPage
        Number of items per page (default: 10)

    .PARAMETER Sort
        Optional property name to sort the array by before paginating

    .OUTPUTS
        PSCustomObject. A paginator with navigation methods and page state.

    .EXAMPLE
        $pager = New-ArrayPageExtractor -Objects (1..100) -ItemsPerPage 20
        $pager.GetPage(2)
        $pager.GoToNextPage()
        $pager.GetCurrentPage()

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [object[]]$Objects,
        [ValidateScript({$_ -ge 1})]
        [int]$ItemsPerPage = 10,
        [object]$Sort
    )
    $iFirstPage = 0
    $iLastPage = [Math]::Floor(($Objects.Count -1) / $ItemsPerPage)
    $oResult = [PSCustomObject]@{
        FirstPage = $iFirstPage
        LastPage = $iLastPage
        ItemsPerPage = $ItemsPerPage
        Page = 0
        PageCount = $iLastPage + 1
        Objects = if ($Sort) { $Objects | Sort-Object $Sort } else { $Objects }
    }

    $oResult | Add-Member -MemberType ScriptMethod -Name "PageFirstItemIndex" -Value {
        return $this.Page * $this.ItemsPerPage 
    }

    $oResult | Add-Member -MemberType ScriptMethod -Name "PageLastItemIndex" -Value {
        if ($this.Page -eq $this.LastPage) { 
            return $this.Objects.Count - 1 
        } else { 
            ($this.Page + 1) * $this.ItemsPerPage - 1 
        }
    }

    $oResult | Add-Member -MemberType ScriptMethod -Name "PageItemCount" -Value {
        return $this.PageLastItemIndex() - $this.PageFirstItemIndex() + 1
    }

    $oResult | Add-Member -MemberType ScriptMethod -Name "GoToPreviousPage" -Value {
        if ($this.Page -gt 0) {
            $this.Page = $this.Page - 1
        }
    }

    $oResult | Add-Member -MemberType ScriptMethod -Name "GoToNextPage" -Value {
        if ($this.Page -lt $this.LastPage) {
            $this.Page = $this.Page + 1
        }
    }

    $oResult | Add-Member -MemberType ScriptMethod -Name "GoToGetFirstPage" -Value {
        $this.Page = 0
    }

    $oResult | Add-Member -MemberType ScriptMethod -Name "GoToGetLastPage" -Value {
        $this.Page = $this.LastPage
    }

    $oResult | Add-Member -MemberType ScriptMethod -Name "GetCurrentPage" -Value {
        return $this.Objects[$this.PageFirstItemIndex()..$this.PageLastItemIndex()]
    }

    $oResult | Add-Member -MemberType ScriptMethod -Name "GetPage" -Value {
        Param(
            [Parameter(Mandatory)]
            [int]$Page
        )
        if (($Page -ge 0) -and ($Page -le $this.LastPage)) {
            $this.Page = $Page
        } else {
            if ($Page -lt 0) {
                $this.Page = 0
            } else {
                # Page -gt $this.LastPage
                $this.Page = $this.LastPage
            }
        }
        return $this.GetCurrentPage()
    }

    return $oResult
}
