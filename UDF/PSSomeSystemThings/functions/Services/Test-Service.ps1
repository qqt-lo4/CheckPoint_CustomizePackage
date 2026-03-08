function Test-Service {
    <#
    .SYNOPSIS
        Tests whether a Windows service exists

    .DESCRIPTION
        Checks if a service with the given name is installed on the local computer.

    .PARAMETER name
        The service name to check.

    .OUTPUTS
        [bool]. $true if the service exists, $false otherwise.

    .EXAMPLE
        Test-Service -name "Spooler"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    Param(
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory, Position = 0)]
        [string]$name
    )
    try {
        (Get-Service -Name $name -ErrorAction Stop).Count -eq 1 
    } catch {
        return $false
    }
}
