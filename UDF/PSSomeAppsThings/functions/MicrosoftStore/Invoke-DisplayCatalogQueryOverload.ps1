function Invoke-DisplayCatalogQueryOverload {
    <#
    .SYNOPSIS
    Queries DisplayCatalog with just ProductId (uses defaults)

    .DESCRIPTION
    Simplified wrapper for Invoke-DisplayCatalogQuery that only requires a ProductId.

    .PARAMETER ProductId
    The Microsoft Store Product ID

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProductId
    )
    
    return Invoke-DisplayCatalogQuery -ProductId $ProductId
}
