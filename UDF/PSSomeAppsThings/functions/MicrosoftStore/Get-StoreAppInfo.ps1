function Get-StoreAppInfo {
    <#
    .SYNOPSIS
        Retrieves complete Microsoft Store app information including download URLs

    .DESCRIPTION
        Queries the DisplayCatalog API and FE3 delivery endpoint to retrieve comprehensive
        information about a Microsoft Store MSIX/AppX application, including package download
        URLs, version information, architecture details, and dependency status.

    .PARAMETER ProductId
        The Microsoft Store Product ID (12-14 characters, e.g., 9NKSQGP7F2NH)

    .PARAMETER Architecture
        Architecture filter: x64, x86, ARM64, ARM, neutral, All, or Autodetect (default)

    .PARAMETER Market
        Market code (default: US)

    .PARAMETER Language
        Language code (default: en-US)

    .PARAMETER LatestVersionsOnly
        When specified, returns only the latest version of each package

    .PARAMETER MSAToken
        Optional MSA Device Token. Uses module-cached token if not provided.

    .OUTPUTS
        PSCustomObject containing ProductId, ProductName, Publisher, Packages, and DisplayCatalog data

    .EXAMPLE
        Get-StoreAppInfo -ProductId "9NKSQGP7F2NH" -Architecture Autodetect

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidatePattern('^[A-Z0-9]{12,14}$')]
        [string]$ProductId,

        [Parameter(Mandatory=$false)]
        [ValidateSet('x64', 'x86', 'ARM64', 'ARM', 'neutral', 'All', 'Autodetect')]
        [string]$Architecture = 'Autodetect',

        [Parameter(Mandatory=$false)]
        [string]$Market = 'US',

        [Parameter(Mandatory=$false)]
        [string]$Language = 'en-US',

        [Parameter(Mandatory=$false)]
        [switch]$LatestVersionsOnly,

        [Parameter(Mandatory=$false)]
        [string]$MSAToken
    )

    Begin {
        # Architecture will be handled by Filter-PackagesByArchitecture
        Write-Verbose "Architecture filter: $Architecture"

        # Initialize MSAToken if not already done and not provided
        if (-not $MSAToken) {
            if (-not $script:MSAToken) {
                Write-Verbose "Initializing MSA Device Token..."
                $script:MSAToken = Get-DeviceMSAToken
            }
            $tokenToUse = $script:MSAToken
        }
        else {
            $tokenToUse = $MSAToken
        }
        
        # Initialize CorrelationVector if not already done
        if (-not $script:GlobalCV) {
            $script:GlobalCV = New-CorrelationVectorObject
        }
        
        Write-Progress -Activity "Retrieving Microsoft Store information" `
                       -Status "Initializing (ProductId: $ProductId)" `
                       -PercentComplete 0

        # Ensure installed programs are loaded (used to check if package dependencies are installed)
        if (-not $Global:InstalledPrograms) {
            Write-Progress -Activity "Retrieving Microsoft Store information" `
                           -Status "Loading installed programs..." `
                           -PercentComplete 5
            $Global:InstalledPrograms = Get-InstalledPrograms -ProgramAndFeatures -AsHashtable -IncludeAppx
        }
    }
    
    Process {
        try {
            # Step 1: DisplayCatalog (0-30%)
            Write-Progress -Activity "Retrieving Microsoft Store information" `
                           -Status "Querying product catalog..." `
                           -PercentComplete 10
            
            # Query DisplayCatalog
            $dcatResult = Invoke-DisplayCatalogQuery -ProductId $ProductId -Market $Market -Language $Language
            
            if (-not $dcatResult.IsFound) {
                Write-Progress -Activity "Retrieving Microsoft Store information" -Completed
                throw "Product not found with ID: $ProductId"
            }
            
            $product = $dcatResult.ProductListing.Products[0]
            
            Write-Progress -Activity "Retrieving Microsoft Store information" `
                           -Status "Product found: $($product.LocalizedProperties[0].ProductTitle)" `
                           -PercentComplete 30
            
            # Step 2: FE3Handler (30-70%)
            Write-Progress -Activity "Retrieving Microsoft Store information" `
                           -Status "Retrieving packages via FE3..." `
                           -PercentComplete 40
            
            # Get WuCategoryId
            $wuCategoryId = $product.DisplaySkuAvailabilities[0].Sku.Properties.FulfillmentData.WuCategoryId
            Write-Verbose "WuCategoryId: $wuCategoryId"
            
            # Get packages from FE3
            $xml = Invoke-FE3SyncUpdates -WuCategoryId $wuCategoryId -MSAToken $tokenToUse
            $idsResult = Get-FE3UpdateIDs -Xml $xml
            $updateIDs = $idsResult.UpdateIDs
            $revisionIDs = $idsResult.RevisionIDs
            
            if ($updateIDs.Count -eq 0) {
                Write-Progress -Activity "Retrieving Microsoft Store information" -Completed
                throw "No packages found for this product"
            }
            
            $fileUrls = Get-FE3FileUrls -UpdateIDs $updateIDs -RevisionIDs $revisionIDs -MSAToken $tokenToUse
            
            # Build package instances
            $packageInstances = @()
            for ($i = 0; $i -lt $fileUrls.Count; $i++) {
                $package = @{
                    PackageUri = $fileUrls[$i]
                    UpdateId = if ($i -lt $updateIDs.Count) { $updateIDs[$i] } else { $null }
                }
                $packageInstances += $package
            }
            
            Write-Progress -Activity "Retrieving Microsoft Store information" `
                           -Status "Found $($packageInstances.Count) package(s)" `
                           -PercentComplete 70
            
            # Step 3: Build URL list with GUID → RealName mapping (70-85%)
            Write-Progress -Activity "Retrieving Microsoft Store information" `
                           -Status "Resolving file names..." `
                           -PercentComplete 75
            
            $downloadUrls = @()
            foreach ($pkg in $packageInstances) {
                if ($pkg.PackageUri) {
                    # Extract GUID from URL (without extension)
                    $urlPath = ([uri]$pkg.PackageUri).LocalPath
                    $guid = [System.IO.Path]::GetFileNameWithoutExtension($urlPath)
                    
                    # Look for real name in mapping
                    # The mapping now stores entries as "GUID.extension" → "RealName"
                    $realName = $null
                    $extension = $null
                    
                    # Try to find mapping with different possible extensions
                    foreach ($ext in @('.msixbundle', '.appxbundle', '.msix', '.appx', '.emsix', '.eappx')) {
                        $key = "$guid$ext"
                        if ($script:GuidToPackageNameMap -and $script:GuidToPackageNameMap.ContainsKey($key)) {
                            $realName = $script:GuidToPackageNameMap[$key]
                            $extension = $ext
                            Write-Verbose "Resolved $key to $realName"
                            break
                        }
                    }
                    
                    if (-not $realName) {
                        $realName = $guid
                        $extension = '.appx'  # Default extension
                        Write-Verbose "No mapping found for $guid, using GUID as filename with .appx"
                    }
                    
                    # Build final filename
                    if ($realName -match '\.(appx|msix|msixbundle|appxbundle|eappx|emsix)$') {
                        # RealName already has extension
                        $fileName = $realName
                    }
                    else {
                        # Add extension from mapping
                        $fileName = "$realName$extension"
                    }
                    
                    Write-Verbose "Package URL: $($pkg.PackageUri)"
                    Write-Verbose "  FileName: $fileName"
                    
                    # Determine if this is the main package (non-framework with high PackageRank)
                    $isMainPackage = $false
                    $packageRank = 100  # Default for frameworks
                    $packageMoniker = $null
                    $packageName = $null
                    $packageVersion = $null
                    $packageArchitecture = $null
                    $publisherId = $null
                    $fileSize = $null
                    
                    # Look up package properties in XML to determine if it's main package
                    if ($pkg.UpdateId -and $script:SyncUpdatesXml) {
                        try {
                            [xml]$syncDoc = $script:SyncUpdatesXml
                            $updateNodes = $syncDoc.GetElementsByTagName("UpdateInfo")
                            foreach ($node in $updateNodes) {
                                $identityNodes = $node.GetElementsByTagName("UpdateIdentity")
                                if ($identityNodes.Count -gt 0) {
                                    $nodeUpdateId = $identityNodes[0].GetAttribute("UpdateID")
                                    if ($nodeUpdateId -eq $pkg.UpdateId) {
                                        # Check Properties for IsAppxFramework and PackageRank
                                        $propNodes = $node.GetElementsByTagName("Properties")
                                        if ($propNodes.Count -gt 0) {
                                            $isFramework = $propNodes[0].GetAttribute("IsAppxFramework")
                                            $rankAttr = $propNodes[0].GetAttribute("PackageRank")
                                            
                                            if ($rankAttr) {
                                                $packageRank = [int]$rankAttr
                                            }
                                            
                                            # Main package: not a framework AND has high PackageRank (> 100)
                                            if ($isFramework -ne "true" -and $packageRank -gt 100) {
                                                $isMainPackage = $true
                                                Write-Verbose "  Detected as MAIN PACKAGE (PackageRank=$packageRank, IsAppxFramework=$isFramework)"
                                            }
                                        }
                                        
                                        # Extract file size from ExtendedUpdateInfo section
                                        # Size is in <ExtendedUpdateInfo><Updates><Update><Xml><Files><File Size="...">
                                        # We need to search in the ExtendedUpdateInfo part of the XML
                                        try {
                                            $extendedUpdateInfoNodes = $syncDoc.GetElementsByTagName("ExtendedUpdateInfo")
                                            if ($extendedUpdateInfoNodes.Count -gt 0) {
                                                $extendedUpdatesNodes = $extendedUpdateInfoNodes[0].GetElementsByTagName("Update")
                                                foreach ($extUpdate in $extendedUpdatesNodes) {
                                                    # Check if this Update node matches our UpdateId
                                                    $idNodes = $extUpdate.GetElementsByTagName("ID")
                                                    if ($idNodes.Count -gt 0) {
                                                        # Find the UpdateInfo node with this ID to get its UpdateID
                                                        $updateInfoId = $idNodes[0].InnerText
                                                        
                                                        # Find corresponding UpdateInfo to get UpdateID
                                                        $allUpdateInfos = $syncDoc.GetElementsByTagName("UpdateInfo")
                                                        foreach ($ui in $allUpdateInfos) {
                                                            $uiIdNode = $ui.GetElementsByTagName("ID")
                                                            if ($uiIdNode.Count -gt 0 -and $uiIdNode[0].InnerText -eq $updateInfoId) {
                                                                # Get UpdateID from UpdateIdentity
                                                                $uiIdentityNodes = $ui.GetElementsByTagName("UpdateIdentity")
                                                                if ($uiIdentityNodes.Count -gt 0) {
                                                                    $uiUpdateId = $uiIdentityNodes[0].GetAttribute("UpdateID")
                                                                    if ($uiUpdateId -eq $pkg.UpdateId) {
                                                                        # Found matching update, now get Size from File node
                                                                        $extFileNodes = $extUpdate.GetElementsByTagName("File")
                                                                        if ($extFileNodes.Count -gt 0) {
                                                                            $sizeAttr = $extFileNodes[0].GetAttribute("Size")
                                                                            if ($sizeAttr) {
                                                                                $fileSize = [long]$sizeAttr
                                                                                Write-Verbose "  Found file size: $fileSize bytes"
                                                                            }
                                                                        }
                                                                        break
                                                                    }
                                                                }
                                                                break
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        catch {
                                            Write-Verbose "  Could not extract file size: $_"
                                        }
                                        
                                        # Extract PackageMoniker from AppxMetadata
                                        $appxMetadataNodes = $node.GetElementsByTagName("AppxMetadata")
                                        if ($appxMetadataNodes.Count -gt 0) {
                                            $packageMoniker = $appxMetadataNodes[0].GetAttribute("PackageMoniker")
                                            
                                            # Parse PackageName, Version, Architecture, and PublisherId from PackageMoniker
                                            # Format: PackageName_Version_Architecture__PublisherId
                                            # Example: Microsoft.VCLibs.140.00.UWPDesktop_14.0.33728.0_x64__8wekyb3d8bbwe
                                            if ($packageMoniker -match '^(.+?)_(\d+\.\d+\.\d+\.\d+)_([^_]+)__(.+)$') {
                                                $packageName = $matches[1]
                                                $packageVersion = $matches[2]
                                                $packageArchitecture = $matches[3]
                                                $publisherId = $matches[4]
                                                Write-Verbose "  PackageName: $packageName, Version: $packageVersion, Arch: $packageArchitecture, Publisher: $publisherId"
                                            }
                                            elseif ($packageMoniker -match '^(.+?)_(\d+\.\d+\.\d+)_([^_]+)__(.+)$') {
                                                # Some packages have 3-part versions
                                                $packageName = $matches[1]
                                                $packageVersion = $matches[2]
                                                $packageArchitecture = $matches[3]
                                                $publisherId = $matches[4]
                                                Write-Verbose "  PackageName: $packageName, Version: $packageVersion, Arch: $packageArchitecture, Publisher: $publisherId"
                                            }
                                            elseif ($packageMoniker -match '^(.+?)_(\d+\.\d+\.\d+\.\d+)_([^_]+)_~_(.+)$') {
                                                # Bundle format with ~
                                                $packageName = $matches[1]
                                                $packageVersion = $matches[2]
                                                $packageArchitecture = $matches[3]
                                                $publisherId = $matches[4]
                                                Write-Verbose "  PackageName: $packageName, Version: $packageVersion, Arch: $packageArchitecture, Publisher: $publisherId"
                                            }
                                        }
                                        
                                        # If no AppxMetadata, try to extract from File node InstallerSpecificIdentifier
                                        if (-not $packageMoniker) {
                                            $fileNodes = $node.GetElementsByTagName("File")
                                            if ($fileNodes.Count -gt 0) {
                                                $installerSpecificId = $fileNodes[0].GetAttribute("InstallerSpecificIdentifier")
                                                if ($installerSpecificId) {
                                                    $packageMoniker = $installerSpecificId
                                                    
                                                    # Parse PackageName, Version, Architecture, and PublisherId
                                                    if ($packageMoniker -match '^(.+?)_(\d+\.\d+\.\d+\.\d+)_([^_]+)__(.+)$') {
                                                        $packageName = $matches[1]
                                                        $packageVersion = $matches[2]
                                                        $packageArchitecture = $matches[3]
                                                        $publisherId = $matches[4]
                                                        Write-Verbose "  PackageName: $packageName, Version: $packageVersion, Arch: $packageArchitecture, Publisher: $publisherId (from File node)"
                                                    }
                                                    elseif ($packageMoniker -match '^(.+?)_(\d+\.\d+\.\d+)_([^_]+)__(.+)$') {
                                                        $packageName = $matches[1]
                                                        $packageVersion = $matches[2]
                                                        $packageArchitecture = $matches[3]
                                                        $publisherId = $matches[4]
                                                        Write-Verbose "  PackageName: $packageName, Version: $packageVersion, Arch: $packageArchitecture, Publisher: $publisherId (from File node)"
                                                    }
                                                }
                                            }
                                        }
                                        
                                        break
                                    }
                                }
                            }
                        }
                        catch {
                            Write-Verbose "  Could not determine package properties: $_"
                        }
                    }
                    
                    $downloadUrls += [PSCustomObject]@{
                        UpdateId = $pkg.UpdateId
                        PackageMoniker = $packageMoniker
                        PackageName = $packageName
                        Version = $packageVersion
                        Architecture = $packageArchitecture
                        PublisherId = $publisherId
                        FileName = $fileName
                        Size = $fileSize
                        Url = $pkg.PackageUri
                        IsMainPackage = $isMainPackage
                        PackageRank = $packageRank
                    }
                }
            }
            
            Write-Verbose "Total download URLs collected: $($downloadUrls.Count)"
            
            # Deduplication (80-85%)
            Write-Progress -Activity "Retrieving Microsoft Store information" `
                           -Status "Deduplicating packages..." `
                           -PercentComplete 82
            
            $seenFiles = @{}
            $uniqueUrls = @()
            foreach ($url in $downloadUrls) {
                if (-not $seenFiles.ContainsKey($url.FileName)) {
                    $seenFiles[$url.FileName] = $true
                    $uniqueUrls += $url
                }
                else {
                    Write-Verbose "Duplicate removed: $($url.FileName)"
                }
            }
            
            Write-Verbose "After deduplication: $($uniqueUrls.Count) unique packages"
            $downloadUrls = $uniqueUrls
            
            # Filter by architecture per PackageName (90-100%)
            Write-Progress -Activity "Retrieving Microsoft Store information" `
                           -Status "Filtering by architecture: $Architecture" `
                           -PercentComplete 95

            # Group by PackageName to filter architecture separately for each package
            $groupedByName = $downloadUrls | Group-Object PackageName
            $filteredUrls = @()

            foreach ($group in $groupedByName) {
                # Filter architecture for this specific package
                $filtered = Filter-PackagesByArchitecture -Packages $group.Group -Architecture $Architecture
                if ($filtered) {
                    $filteredUrls += $filtered
                }
            }
            
            # Filter to keep only latest versions if requested
            if ($LatestVersionsOnly) {
                Write-Progress -Activity "Retrieving Microsoft Store information" `
                               -Status "Filtering latest versions..." `
                               -PercentComplete 97
                
                $latestPackages = @()
                $groupedByName = $filteredUrls | Group-Object PackageName
                
                foreach ($group in $groupedByName) {
                    if ($group.Group.Count -eq 1) {
                        # Only one version, keep it
                        $latestPackages += $group.Group[0]
                    }
                    else {
                        # Multiple versions, sort by version and keep the latest
                        $sorted = $group.Group | Where-Object { $_.Version } | Sort-Object {
                            # Convert version string to comparable format
                            try {
                                [version]$_.Version
                            }
                            catch {
                                # If version parsing fails, use string comparison
                                $_.Version
                            }
                        } -Descending
                        
                        if ($sorted.Count -gt 0) {
                            $latestPackages += $sorted[0]
                            Write-Verbose "Kept latest version $($sorted[0].Version) of $($group.Name), removed $($sorted.Count - 1) older version(s)"
                        }
                        else {
                            # No version info, keep the first one
                            $latestPackages += $group.Group[0]
                        }
                    }
                }
                
                $filteredUrls = $latestPackages
                Write-Verbose "After latest version filter: $($filteredUrls.Count) packages"
            }
            
            foreach ($oPackage in $filteredUrls) {
                $oInstalledPackage = $Global:InstalledPrograms | Where-Object { ($_.type -eq "appx") -and ($_.PackageName -eq $oPackage.PackageName) -and ($_.Architecture -eq $oPackage.Architecture) }
                if ($null -eq $oInstalledPackage) {
                    $oPackage | Add-Member -NotePropertyName "Installed" -NotePropertyValue $false
                } else {
                    if ([version]$oInstalledPackage.Version -lt [version]$oPackage.Version) {
                        $oPackage | Add-Member -NotePropertyName "Installed" -NotePropertyValue $false
                    } else {
                        $oPackage | Add-Member -NotePropertyName "Installed" -NotePropertyValue $true
                    }
                }
            }

            # Calculate total size
            $totalSize = ($filteredUrls | Where-Object { $_.Size } | Measure-Object -Property Size -Sum).Sum
            if (-not $totalSize) {
                $totalSize = 0
            }

            Write-Progress -Activity "Retrieving Microsoft Store information" `
                           -Status "Complete - $($filteredUrls.Count) file(s) selected" `
                           -PercentComplete 100

            # Build result object
            $result = [PSCustomObject]@{
                ProductId = $ProductId
                ProductName = $product.LocalizedProperties[0].ProductTitle
                Publisher = $product.LocalizedProperties[0].PublisherName
                Architecture = $Architecture
                PackageCount = $filteredUrls.Count
                TotalSize = $totalSize
                Packages = $filteredUrls
                DisplayCatalog = $dcatResult
            }
            
            # Complete the progress bar
            Write-Progress -Activity "Retrieving Microsoft Store information" -Completed
            
            return $result
        }
        catch {
            Write-Progress -Activity "Retrieving Microsoft Store information" -Completed
            throw
        }
    }
}

