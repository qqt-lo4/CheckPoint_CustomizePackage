function Test-StringIsDateTime {
    <#
    .SYNOPSIS
        Tests if a value can be parsed as a DateTime

    .DESCRIPTION
        Attempts to parse the input value as a DateTime. Returns the parsed DateTime
        object on success, or $false if the value cannot be parsed.

    .PARAMETER DateTime
        The value to test. Can be a string or any object with a ToString() method.
        Aliases: Date, Time.

    .OUTPUTS
        System.DateTime or System.Boolean. The parsed DateTime, or $false on failure.

    .EXAMPLE
        Test-StringIsDateTime "2024-01-15"
        # Returns a DateTime object

    .EXAMPLE
        Test-StringIsDateTime "not a date"
        # Returns $false

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [Alias("Date", "Time")]
        [object]$DateTime
    )
    try {
        return [datetime]::Parse($DateTime.ToString())
    } catch {
        return $false
    }
}