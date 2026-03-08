function Get-DCatEndpointUrl {
    <#
    .SYNOPSIS
    Gets the DisplayCatalog endpoint URL
    
    .DESCRIPTION
    Returns the appropriate endpoint URL based on environment (Production or Int)

    .PARAMETER Endpoint
    The environment to target. Valid values: Production, Int. Default: Production.

    .OUTPUTS
    String containing the DisplayCatalog API endpoint URL

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    param(
        [ValidateSet('Production', 'Int')]
        [string]$Endpoint = 'Production'
    )
    
    switch ($Endpoint) {
        'Production' { return 'https://displaycatalog.mp.microsoft.com/v7.0/products' }
        'Int' { return 'https://displaycatalog-int.mp.microsoft.com/v7.0/products' }
    }
}
