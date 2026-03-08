function Get-WingetPackageCatalog {
    <#
    .SYNOPSIS
        Downloads and extracts the Winget package catalog database
    
    .DESCRIPTION
        This function downloads the source2.msix file from Winget CDN,
        extracts the SQLite database containing all available packages,
        and optionally queries it
    
    .PARAMETER Url
        Custom URL to download the source. If not specified, uses the default winget source
    
    .PARAMETER OutputPath
        Path where to extract the database. If not specified, uses a temporary directory
    
    .PARAMETER KeepMsix
        If specified, keeps the downloaded .msix file after extraction
    
    .EXAMPLE
        Get-WingetPackageCatalog
        
    .EXAMPLE
        Get-WingetPackageCatalog -OutputPath "C:\temp\winget-catalog"
        
    .EXAMPLE
        $catalog = Get-WingetPackageCatalog
        $catalog.DatabasePath

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [string]$Url,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$KeepMsix
    )
    
    try {
        # Get the source URL
        $sourceUrl = if ($Url) { 
            $Url 
        } else { 
            $wingetSource = Get-WingetSources | Where-Object { $_.Name -eq "winget" }
            if (-not $wingetSource) {
                throw "Winget source not found. Please specify a URL manually."
            }
            $wingetSource.Arg
        }
        
        # Ensure the URL points to source2.msix
        if ($sourceUrl -notlike "*msix") {
            $sourceUrl = $sourceUrl.TrimEnd('/') + "/source2.msix"
        }
        
        Write-Verbose "Source URL: $sourceUrl"
        
        # Determine output path
        if (-not $OutputPath) {
            $OutputPath = Join-Path $env:TEMP "WingetCatalog-$(Get-Date -Format 'yyyyMMddHHmmss')"
        }
        
        # Create output directory if it doesn't exist
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        Write-Verbose "Output path: $OutputPath"
        
        # Download the .msix file
        $msixPath = Join-Path $OutputPath "source2.msix"
        Write-Host "Downloading Winget catalog from $sourceUrl..."
        
        try {
            Invoke-WebRequest -Uri $sourceUrl -OutFile $msixPath -UseBasicParsing
        }
        catch {
            throw "Failed to download catalog: $_"
        }
        
        if (-not (Test-Path $msixPath)) {
            throw "Downloaded file not found at $msixPath"
        }
        
        Write-Host "Download complete. File size: $([math]::Round((Get-Item $msixPath).Length / 1MB, 2)) MB"
        
        # Extract the .msix file (it's actually a ZIP archive)
        $extractPath = Join-Path $OutputPath "extracted"
        Write-Host "Extracting catalog..."

        try {
            # PowerShell 5's Expand-Archive only accepts .zip extension
            # Rename .msix to .zip temporarily for compatibility
            $zipPath = $msixPath -replace '\.msix$', '.zip'
            $needsRename = $msixPath -ne $zipPath

            if ($needsRename) {
                Rename-Item -Path $msixPath -NewName (Split-Path $zipPath -Leaf) -Force
            }

            try {
                # Use Expand-Archive or manual ZIP extraction
                if (Get-Command Expand-Archive -ErrorAction SilentlyContinue) {
                    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
                }
                else {
                    # Fallback using .NET
                    Add-Type -AssemblyName System.IO.Compression.FileSystem
                    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $extractPath)
                }
            }
            finally {
                # Rename back to .msix
                if ($needsRename -and (Test-Path $zipPath)) {
                    Rename-Item -Path $zipPath -NewName (Split-Path $msixPath -Leaf) -Force
                }
            }
        }
        catch {
            throw "Failed to extract catalog: $_"
        }
        
        # Find the SQLite database file (usually named index.db)
        $dbFile = Get-ChildItem -Path $extractPath -Filter "index.db" -Recurse | Select-Object -First 1
        
        if (-not $dbFile) {
            # Fallback: try any .db file
            $dbFile = Get-ChildItem -Path $extractPath -Filter "*.db" -Recurse | Select-Object -First 1
        }
        
        if (-not $dbFile) {
            throw "SQLite database not found in extracted files"
        }
        
        Write-Host "Database found: $($dbFile.Name)"
        
        # Clean up .msix file if requested
        if (-not $KeepMsix) {
            Remove-Item -Path $msixPath -Force -ErrorAction SilentlyContinue
        }
        
        # Return catalog information
        $result = [PSCustomObject]@{
            DatabasePath  = $dbFile.FullName
            ExtractPath   = $extractPath
            MsixPath      = if ($KeepMsix) { $msixPath } else { $null }
            DownloadDate  = Get-Date
            SourceUrl     = $sourceUrl
            DatabaseSize  = [math]::Round($dbFile.Length / 1MB, 2)
        }
        
        Write-Host "Catalog extracted successfully!" -ForegroundColor Green
        Write-Host "Database location: $($result.DatabasePath)"
        $Global:WingetCatalog = $result
        return $result
    }
    catch {
        Write-Error "Error retrieving Winget package catalog: $_"
        return $null
    }
}