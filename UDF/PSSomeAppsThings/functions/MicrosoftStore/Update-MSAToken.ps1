function Update-MSAToken {
    <#
    .SYNOPSIS
    Refreshes the MSA Device Token from the registry
    
    .DESCRIPTION
    Re-reads the MSA Device Token from Windows registry and updates the module's cached token.
    Useful if the token has been refreshed by Windows Store or Windows Update.
    
    .EXAMPLE
    Update-MSAToken -Verbose
    
    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        The token is automatically loaded when the module is imported, but you can call this
        function to refresh it if needed.
    #>
    [CmdletBinding()]
    param()
    
    Write-Verbose "Refreshing MSA Device Token from registry..."
    $script:MSAToken = Get-DeviceMSAToken
    Write-Verbose "MSA Token refreshed"
}
