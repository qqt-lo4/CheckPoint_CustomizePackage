function Test-ContainsArray {
    <#
    .SYNOPSIS
        Tests if an array contains all elements of another array

    .DESCRIPTION
        Checks whether every element in ArrayContained exists in ReferenceArray
        using Compare-Object for set comparison.

    .PARAMETER ReferenceArray
        The array to search in

    .PARAMETER ArrayContained
        The array of elements that must all be present

    .OUTPUTS
        System.Boolean. True if all elements of ArrayContained are in ReferenceArray.

    .EXAMPLE
        Test-ContainsArray -ReferenceArray @(1,2,3,4,5) -ArrayContained @(2,4)
        # Returns: True

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [object[]]$ReferenceArray,
        [Parameter(Mandatory, Position = 1)]
        [object[]]$ArrayContained
    )
    $oCompareResults = @() + (Compare-Object -ReferenceObject $ReferenceArray -DifferenceObject $ArrayContained -IncludeEqual -ExcludeDifferent)
    return ($oCompareResults.Count -eq $ArrayContained.Count)
}
