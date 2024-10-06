function Test-ProcessElevated
{
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [System.Diagnostics.Process]$Process = (Get-Process -ID $PID)
    )

    begin {}

    process {
        [Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544'
    }

    end {}
}