function Get-StoreAppManifest {
    <#
    .SYNOPSIS
        Retrieves the complete manifest of a Microsoft Store application

    .DESCRIPTION
        Queries the PackageManifests API (unified modern Store API) to retrieve all
        available information about an application: metadata, description, screenshots,
        ratings, supported platforms, languages, and installer details.
        Works for ALL app types (MSIX, AppX, Win32).

    .PARAMETER ProductId
        The Store identifier (12 characters like 9NKSQGP7F2NH or 14+ characters like xpfm306ts4phh5)

    .PARAMETER Market
        Market code (e.g., US, FR)

    .PARAMETER Language
        Language code (e.g., en-US)

    .PARAMETER FilterInstallers
        When specified, filters installers by preferred architecture and locale

    .EXAMPLE
        Get-StoreAppManifest -ProductId "9NKSQGP7F2NH"

    .EXAMPLE
        Get-StoreAppManifest -ProductId "xpfm306ts4phh5" -Market "FR"

    .OUTPUTS
        PSCustomObject containing all manifest information

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        Uses the modern API: storeedgefd.dsx.mp.microsoft.com/v9.0/packageManifests
        This function is independent of Get-StoreAppInfo (which uses DisplayCatalog for downloads).
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidatePattern('^[A-Za-z0-9]{12,}$')]
        [string]$ProductId,
        
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]$Market, # = 'US',
        
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]$Language, # = 'en-US',
        
        [Parameter(Mandatory = $false)]
        [switch]$FilterInstallers
    )
    
    Begin {
        Write-Verbose "Querying Microsoft Store PackageManifests API"
        Write-Verbose "ProductId: $ProductId, Market: $Market, Language: $Language"
        
        # Normaliser l'ID
        $ProductId = $ProductId.ToUpper()
        
        # Initialize progress
        Write-Progress -Activity "Retrieving Store Manifest" -Status "Querying PackageManifests API..." -PercentComplete 0
    }
    
    Process {
        try {
            # ================================================================
            # Query PackageManifests API (API moderne unifiée)
            # ================================================================
            
            Write-Progress -Activity "Retrieving Store Manifest" -Status "Fetching data from Store..." -PercentComplete 20
            
            $pmResult = Invoke-PackageManifestQuery -BigId $ProductId -Market $Market -Language $Language
            
            if (-not $pmResult.IsFound) {
                Write-Progress -Activity "Retrieving Store Manifest" -Completed
                throw "Application not found with ID: $ProductId"
            }
            
            $data = $pmResult.PackageManifest
            
            Write-Progress -Activity "Retrieving Store Manifest" -Status "Parsing manifest data..." -PercentComplete 50
            
            # ================================================================
            # Construire le manifeste unifié
            # ================================================================

            # Détecter le type d'app (MSIX vs Win32) selon l'InstallerType
            $appType = if ("msstore" -in $data.Data.Versions.Installers.InstallerType) {
                "MSIX/AppX"
            } else {
                "Win32"
            }
            
            $manifest = [PSCustomObject]@{
                ProductId = $ProductId
                Market = $Market
                Language = $Language
                QueryDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                AppType = $appType
                
                # Display Properties
                DisplayProperties = [PSCustomObject]@{
                    Title = $data.PackageMoniker
                    Publisher = $data.PublisherName
                    Description = $data.Description
                    ShortDescription = $data.ShortDescription
                    PublisherWebsiteUri = $data.PublisherWebsite
                    SupportUri = $data.SupportUri
                    PrivacyUri = $data.PrivacyUri
                    Copyright = $data.Copyright
                }
                
                # Product Information
                ProductInfo = [PSCustomObject]@{
                    PackageMoniker = $data.PackageMoniker
                    PackageIdentityName = $data.PackageIdentityName
                    Category = $data.Category
                    ReleaseDate = $data.PublishedDate
                    LastModifiedDate = $data.LastModifiedDate
                    Version = $data.Version
                }
                
                # Pricing
                Pricing = [PSCustomObject]@{
                    IsFree = $data.IsFree
                    Price = $data.Price
                    CurrencyCode = $data.CurrencyCode
                }
                
                # Rating
                Rating = if ($data.AverageRating) {
                    [PSCustomObject]@{
                        AverageRating = $data.AverageRating
                        RatingCount = $data.RatingCount
                    }
                } else { $null }
                
                # Screenshots
                Screenshots = @()
                
                # Videos
                Videos = @()
                
                # Supported Platforms
                Platforms = @()
                
                # Supported Languages
                SupportedLanguages = if ($data.SupportedLanguages) { $data.SupportedLanguages } else { @() }
                
                # Capabilities
                Capabilities = if ($data.Capabilities) { $data.Capabilities } else { @() }
                
                # System Requirements
                SystemRequirements = [PSCustomObject]@{
                    MinimumOS = $data.MinimumOSVersion
                    Architecture = $data.Architecture
                    Memory = $data.MinimumMemory
                    Storage = $data.MinimumStorage
                    Processor = $data.MinimumProcessor
                    Graphics = $data.MinimumGraphics
                    DirectX = $data.MinimumDirectX
                    AdditionalRequirements = $data.AdditionalRequirements
                }
                
                # Package Information
                PackageInfo = [PSCustomObject]@{
                    PackageMoniker = $data.PackageMoniker
                    PackageIdentityName = $data.PackageIdentityName
                    PackageFamilyName = $data.PackageFamilyName
                    Version = $data.Version
                    PublisherId = $data.PublisherId
                    Architecture = $data.Architecture
                }

                Installers = $data.Data.Versions.Installers
                InstallerType = if ("msstore" -in $data.Data.Versions.Installers.InstallerType) {
                    "msstore"
                } else {
                    "win32"
                }
                
                # Raw JSON (pour usage avancé)
                RawManifest = $data
            }

            if ($FilterInstallers) {
                $aInstallers = $manifest.Installers | Select-PreferredArchitecture
                if ($aInstallers.InstallerLocale) {
                    $aInstallers = $aInstallers | Select-PreferredLocale
                }
                $manifest.Installers = $aInstallers
            }
            
            # Extract Screenshots
            if ($data.Screenshots) {
                $manifest.Screenshots = $data.Screenshots | ForEach-Object {
                    [PSCustomObject]@{
                        Uri = if ($_.Url) { $_.Url } else { $_.Uri }
                        Height = $_.Height
                        Width = $_.Width
                        Caption = $_.Caption
                        ImageType = $_.ImageType
                    }
                }
            }
            
            # Extract Videos/Trailers
            if ($data.Trailers -or $data.Videos) {
                $videoSource = if ($data.Trailers) { $data.Trailers } else { $data.Videos }
                $manifest.Videos = $videoSource | ForEach-Object {
                    [PSCustomObject]@{
                        Uri = if ($_.Url) { $_.Url } else { $_.Uri }
                        Title = $_.Title
                        PreviewImage = $_.PreviewImageUrl
                    }
                }
            }
            
            # Extract Platforms
            if ($data.SupportedPlatforms) {
                $manifest.Platforms = $data.SupportedPlatforms | ForEach-Object {
                    if ($_ -is [string]) {
                        [PSCustomObject]@{ PlatformName = $_ }
                    }
                    else {
                        [PSCustomObject]@{
                            PlatformName = $_.PlatformName
                            MinVersion = $_.MinVersion
                            MaxTested = $_.MaxTested
                        }
                    }
                }
            }
         
            Write-Progress -Activity "Retrieving Store Manifest" -Completed
            
            return $manifest
        }
        catch {
            Write-Progress -Activity "Retrieving Store Manifest" -Completed
            throw
        }
    }
}