function Set-StringFormat {
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
        [int]$Position,
        [switch]$Underline,
        [switch]$Bold,
        [switch]$Italic,
        [switch]$Blink
    )
    $sStartChar, $sEndChar = "", ""
    if ($Underline) {
        $sStartChar += "$([char]27)[4m"
        $sEndChar += "$([char]27)[24m"
    }
    if ($Bold) {
        $sStartChar += "$([char]27)[1m"
        $sEndChar += "$([char]27)[22m"
    }
    if ($Italic) {
        $sStartChar += "$([char]27)[3m"
        $sEndChar += "$([char]27)[23m"
    }
    if ($Blink) {
        $sStartChar += "$([char]27)[5m"
        $sEndChar += "$([char]27)[25m"
    }
    $iEnd = switch ($PSCmdlet.ParameterSetName) {
        "All" { $InputObject.Length }
        "StartEnd" { if ($PSBoundParameters.ContainsKey("End")) { $End } else { $InputObject.Length } }
        "Position" { $Position + 1 }
    }
    $iStart = switch ($PSCmdlet.ParameterSetName) {
        "All" { 0 }
        "StartEnd" { $Start }
        "Position" { $Position }
    }
    return $InputObject.Insert($iEnd, $sEndChar).Insert($iStart, $sStartChar)
}
