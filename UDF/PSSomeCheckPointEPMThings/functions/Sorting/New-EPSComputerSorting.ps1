function New-EPSComputerSorting {
    [Cmdletbinding(DefaultParameterSetName = "Ascending")]
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Column,
        [Parameter(ParameterSetName = "Ascending")]
        [switch]$Ascending,
        [Parameter(ParameterSetName = "Descending")]
        [switch]$Descending
    )
    return @{
        columnDescriptionEnum = $Column
        ascending = ($PSCmdlet.ParameterSetName -eq "Ascending")
    }
}
