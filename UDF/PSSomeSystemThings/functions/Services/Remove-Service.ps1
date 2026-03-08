function Remove-Service {
    <#
    .SYNOPSIS
        Removes (deletes) a Windows service

    .DESCRIPTION
        Uses sc.exe to delete a Windows service. Requires administrator privileges.

    .PARAMETER name
        The service name to remove.

    .OUTPUTS
        [PSCustomObject]. Object with Output, ReturnCode, and Success properties.

    .EXAMPLE
        Remove-Service -name "MyService"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    Param(
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory, Position = 0)]
        [string]$name
    )
    if (Test-IsAdmin) {
        $commandOutput = & sc.exe delete $name
        return New-Object PSCustomObject -Property @{
            Output = $commandOutput
            ReturnCode = $LASTEXITCODE
            Success = $($LASTEXITCODE -eq 0)
        }
    } else {
        throw [System.AccessViolationException] "Please run this command with admin rights"
    }
}