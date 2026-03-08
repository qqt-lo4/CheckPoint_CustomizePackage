function New-EPSComputerFilter {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Column,
        [Parameter(Mandatory, Position = 1, ParameterSetName = "Contains")]
        [switch]$eq,
        [Parameter(Mandatory, Position = 1, ParameterSetName = "Grater")]
        [switch]$ge,
        [Parameter(Mandatory, Position = 1, ParameterSetName = "Smaller")]
        [switch]$le,
        [Parameter(Mandatory, Position = 2)]
        [object]$Value
    )
    return @{
        columnName = $Column
        filterType = $PSCmdlet.ParameterSetName
        filterValues = $Value
    }
}
