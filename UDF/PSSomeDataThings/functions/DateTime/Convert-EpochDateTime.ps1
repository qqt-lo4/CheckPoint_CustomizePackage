function Convert-EpochDateTime {
    <#
    .SYNOPSIS
        Converts Unix epoch milliseconds to a DateTime object

    .DESCRIPTION
        Converts a Unix epoch timestamp in milliseconds to a .NET DateTime object
        (UTC, starting from January 1, 1970).

    .PARAMETER Milliseconds
        The Unix epoch timestamp in milliseconds

    .OUTPUTS
        System.DateTime. The corresponding DateTime value.

    .EXAMPLE
        Convert-EpochDateTime -Milliseconds 1609459200000
        # Returns: Friday, January 1, 2021 12:00:00 AM

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [int64]$Milliseconds
    )
    $oEpochDate = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
    $oResult = $oEpochDate.AddMilliseconds([int64]$Milliseconds)
    return $oResult
}
