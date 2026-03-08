function Wait-ProgressBar {
    <#
    .SYNOPSIS
        Displays a countdown progress bar for a specified duration.

    .DESCRIPTION
        Shows a progress bar that counts down for a specified number of seconds
        using Write-Progress. Updates every second with the remaining time and
        a percentage-complete bar.

    .PARAMETER Duration
        Duration of the countdown in seconds.

    .PARAMETER Message
        Activity text displayed on the progress bar.

    .OUTPUTS
        None. Displays a progress bar in the console.

    .EXAMPLE
        Wait-ProgressBar -Duration 30 -Message "Waiting for service restart..."

        Displays a 30-second countdown progress bar.

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory)][int]$Duration, 
        [Parameter(Mandatory)][string]$Message
    )
    $TimeToWait = 1
    while($TimeToWait -lt $Duration) 
    {
        $Remaining = $Duration - $TimeToWait
        Write-Progress $Message -Status "$Remaining seconds remaining" -PercentComplete (($TimeToWait*100)/$Duration)
        Start-Sleep -Seconds 1
        $TimeToWait++
    }
}
