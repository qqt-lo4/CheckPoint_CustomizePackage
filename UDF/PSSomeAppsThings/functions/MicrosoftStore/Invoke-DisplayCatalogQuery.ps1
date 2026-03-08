function Invoke-DisplayCatalogQuery {
    <#
    .SYNOPSIS
    Queries the DisplayCatalog for a product
    
    .DESCRIPTION
    Queries the Microsoft Store DisplayCatalog API to retrieve product information

    .PARAMETER ProductId
    The Microsoft Store Product ID

    .PARAMETER Market
    Market code (default: US)

    .PARAMETER Language
    Language code (default: en-US)

    .PARAMETER Endpoint
    API environment: Production or Int (default: Production)

    .PARAMETER AuthToken
    Optional authentication token

    .OUTPUTS
    Hashtable with ProductListing, IsFound, and ID properties

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProductId,
        
        [Parameter(Mandatory=$false)]
        [string]$Market = 'US',
        
        [Parameter(Mandatory=$false)]
        [string]$Language = 'en-US',
        
        [Parameter(Mandatory=$false)]
        [string]$Endpoint = 'Production',
        
        [Parameter(Mandatory=$false)]
        [string]$AuthToken
    )
    
    try {
        # Create locale object
        $locale = New-LocaleObject -Market $Market -Language $Language -IncludeNeutral $true
        
        # Get endpoint URL
        $baseUrl = Get-DCatEndpointUrl -Endpoint $Endpoint
        
        # Build URL: {endpoint}/v7.0/products/{ID}?{locale.DCatTrail}
        $fullUrl = "$baseUrl/$ProductId`?$($locale.DCatTrail)"

        $headers = @{
            'Accept' = 'application/json'
        }
        
        if ($AuthToken) {
            $headers['Authentication'] = $AuthToken
        }
        
        Write-Verbose "QueryDCAT: $fullUrl"
        
        # Use Invoke-MSHttpRequest to get MS-CV and User-Agent
        $response = Invoke-MSHttpRequest -Uri $fullUrl `
                                         -Method Get `
                                         -AdditionalHeaders $headers
        
        Write-Verbose "Response StatusCode: $($response.StatusCode)"
        Write-Verbose "Response Length: $($response.Content.Length)"
        
        $content = $response.Content | ConvertFrom-Json
        
        # API can return either "Product" (singular) or "Products" (plural)
        if ($content.Product) {
            Write-Verbose "Found 'Product' (singular) in response"
            # If it's Product (singular), put it in a Products array
            if (-not $content.Products) {
                $content | Add-Member -NotePropertyName 'Products' -NotePropertyValue @($content.Product) -Force
            }
        }
        
        Write-Verbose "Products count: $(if ($content.Products) { $content.Products.Count } else { 'null' })"
        
        if ($content.Products -and $content.Products.Count -gt 0) {
            return @{
                ProductListing = $content
                IsFound = $true
                ID = $ProductId
            }
        }
        else {
            return @{
                ProductListing = $null
                IsFound = $false
                ID = $ProductId
            }
        }
    }
    catch {
        Write-Verbose "QueryDCAT error: $($_.Exception.Message)"
        throw "QueryDCAT error: $($_.Exception.Message)"
    }
}
