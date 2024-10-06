function Get-ItemSelectedByUser {
    Param(
        [array]$objects,
        [string]$selectedColumn,
        [switch]$doSort,
        [string]$sortColumn,
        [switch]$descending,
        [string]$selectHeaderMessage = "Please select an item:",
        [string]$footerMessage = "Please type item number",
        [string]$emptyArrayMessage = "No items in array",
        [AllowEmptyString()][string]$otherAcceptableAnswers = "^(e|E)$",
        [switch]$AutoSelectWhenOneItem
    )
    if (($null -eq $objects) -or ($objects.Count -eq 0)) {
        Write-Host $emptyArrayMessage
        return $null
    }
    if ($AutoSelectWhenOneItem.IsPresent -and ($objects.Count -eq 1)) {
        return [PSCustomObject]@{
            AnswerType = "Value"
            ItemSelected = 1
            Value = $objects[0]
        }
    }
    if ($doSort.IsPresent) {
        if ($sortColumn) {
            $arraySorted = $objects | Sort-Object -Property $sortColumn -Descending:$($descending.IsPresent)
        } else {
            $arraySorted = $objects | Sort-Object -Descending:$($descending.IsPresent)
        }
    } else {
        $arraySorted = $objects
    }
    $validAnswer = $false
    while (-not $validAnswer) {
        $iterator = 1
        Write-Host $selectHeaderMessage
        foreach ($item in $arraySorted) {
            if ($selectedColumn) {
                Write-Host $($iterator.ToString() + "`t" + $item.$selectedColumn)
            } else {
                Write-Host $($iterator.ToString() + "`t" + $item)
            }
            $iterator++
        }
        $selectedItem = Read-Host $footerMessage
        if ($selectedItem -match "^[0-9]+$") {
            $validAnswer, $selectedItem = Test-ValidNumberInput $selectedItem 1 $arraySorted.Count -allowEmptyValue
            if ($validAnswer) {
                return [PSCustomObject]@{
                    AnswerType = "Value"
                    ItemSelected = $selectedItem
                    Value = $arraySorted[$selectedItem - 1]
                }
            }
        } elseif ($otherAcceptableAnswers -and ($selectedItem -match $otherAcceptableAnswers)) {
            $validAnswer = $true
            return [PSCustomObject]@{
                AnswerType = "Other"
                Value = $selectedItem
            }
        }
        if (-not $validAnswer) {
            Write-Host "The value you typed is not valid. Please chose another value."
        }
    }
}