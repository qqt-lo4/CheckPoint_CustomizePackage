function Invoke-PackageManifestQuery {
    <#
    .SYNOPSIS
        Queries the PackageManifests API for Win32 Store apps

    .DESCRIPTION
        Used for Win32 applications distributed via the Store that have BigIds (14+ characters).
        This API is different from DisplayCatalog which is used for standard MSIX/AppX apps.

    .PARAMETER BigId
        The application BigId (e.g., xpfm306ts4phh5)

    .PARAMETER Market
        Market code (e.g., US, FR)

    .PARAMETER Language
        Language code (e.g., en-US)

    .EXAMPLE
        Invoke-PackageManifestQuery -BigId "xpfm306ts4phh5" -Market "FR"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        Endpoint: storeedgefd.dsx.mp.microsoft.com/v9.0/packageManifests/
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BigId,
        
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]$Market, # = 'US',
        
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]$Language # = 'en-US'
    )
    
    try {
        # Endpoint pour packageManifests (apps Win32)
        $baseUrl = "https://storeedgefd.dsx.mp.microsoft.com/v9.0/packageManifests"
        
        # Normaliser le BigId (peut être en minuscules ou majuscules)
        $BigId = $BigId.ToUpper()
        
        # Construire l'URL avec les paramètres
        $fullUrl = if ($Market) {
            "$baseUrl/$BigId`?Market=$Market"
        } else {
            "$baseUrl/$BigId"
        }
        
        Write-Verbose "Querying PackageManifests API: $fullUrl"
        
        # Headers requis pour cette API
        $headers = @{
            'Accept' = 'application/json'
            'MS-CV' = (New-CorrelationVectorObject).GetValue()
        }
        
        # Faire la requête
        $response = Invoke-MSHttpRequest -Uri $fullUrl `
                                         -Method Get `
                                         -AdditionalHeaders $headers
        
        Write-Verbose "Response StatusCode: $($response.StatusCode)"
        Write-Verbose "Response Length: $($response.Content.Length)"
        
        $content = $response.Content | ConvertFrom-Json
        
        # Vérifier si on a reçu des données
        if ($content) {
            return @{
                PackageManifest = $content
                IsFound = $true
                BigId = $BigId
            }
        }
        else {
            return @{
                PackageManifest = $null
                IsFound = $false
                BigId = $BigId
            }
        }
    }
    catch {
        Write-Verbose "PackageManifests API error: $($_.Exception.Message)"
        
        # Si 404, l'app n'existe pas avec ce BigId
        if ($_.Exception.Message -match "404") {
            return @{
                PackageManifest = $null
                IsFound = $false
                BigId = $BigId
            }
        }
        
        throw "PackageManifests query error: $($_.Exception.Message)"
    }
}