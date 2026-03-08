function Test-Type {
    <#
    .SYNOPSIS
        Tests if a .NET type exists

    .DESCRIPTION
        Verifies whether a specified .NET type is available in the current PowerShell session.
        Returns true if the type exists, false otherwise.

    .PARAMETER TypeName
        Name of the .NET type to test (e.g., "System.String", "System.IO.File").

    .OUTPUTS
        [Boolean]. True if type exists, false otherwise.

    .EXAMPLE
        Test-Type -TypeName "System.String"

    .EXAMPLE
        Test-Type -TypeName "MyCustom.Type"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [ValidatePattern("^[a-zA-Z_.0-9-]+$")]
        [string]$TypeName
    )
    try {
        Invoke-Expression -Command "[$TypeName] -as [type]" | Out-Null
        return $true
    } catch {
        return $false
    }
}
