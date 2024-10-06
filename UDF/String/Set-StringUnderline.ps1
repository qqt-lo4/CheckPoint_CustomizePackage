function Set-StringUnderline {
    [CmdletBinding(DefaultParameterSetName = "All")]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ParameterSetName = "StartEnd")]
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ParameterSetName = "Position")]
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ParameterSetName = "All")]
        [string]$InputObject,
        [Parameter(Mandatory, Position = 1, ParameterSetName = "StartEnd")]
        [int]$Start,
        [Parameter(Position = 2, ParameterSetName = "StartEnd")]
        [int]$End,
        [Parameter(Mandatory, Position = 2, ParameterSetName = "Position")]
        [int]$Position
    )
    return Set-StringFormat -Underline @PSBoundParameters
}
