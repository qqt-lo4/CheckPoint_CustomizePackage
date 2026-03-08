function Get-CurrentMSAToken {
    <#
    .SYNOPSIS
    Returns the currently cached MSA Device Token
    
    .DESCRIPTION
    Returns the MSA Device Token currently being used by the module.
    Initializes it from registry if not already done.
    
    .EXAMPLE
    Get-CurrentMSAToken
    
    .OUTPUTS
    String containing the MSA Device Token

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding()]
    param()
    
    # Initialize MSAToken if not already done
    if (-not $script:MSAToken) {
        Write-Verbose "Initializing MSA Device Token from registry..."
        $script:MSAToken = Get-DeviceMSAToken
    }
    
    return $script:MSAToken
}
