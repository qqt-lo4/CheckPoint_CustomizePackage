function Test-IsGuid {
    <#
    .SYNOPSIS
        Tests if a string is a valid GUID

    .DESCRIPTION
        Attempts to parse the input string as a System.Guid and returns
        true if successful, false otherwise.

    .PARAMETER InputString
        The string to test

    .OUTPUTS
        System.Boolean. True if the string is a valid GUID.

    .EXAMPLE
        Test-IsGuid -InputString "{12345678-1234-1234-1234-123456789012}"
        # Returns: True

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    param (
        [Parameter(Mandatory=$true)]
        [string]$InputString
    )
    
    try {
        [System.Guid]::Parse($InputString) | Out-Null
        return $true
    }
    catch {
        return $false
    }
}