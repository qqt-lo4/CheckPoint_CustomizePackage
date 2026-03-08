function Get-WingetPackageManifest {
    <#
    .SYNOPSIS
        Downloads the YAML manifest for a Winget package from CDN
    
    .DESCRIPTION
        Retrieves package manifests from the official Winget CDN and parses them as PowerShell objects
    
    .PARAMETER PackageId
        Package identifier (e.g., "Mozilla.Firefox.fr")
    
    .PARAMETER Version
        Specific version. If not specified, uses latest_version from database
    
    .PARAMETER OutputPath
        Save location for the manifest file (YAML format)
    
    .PARAMETER AsYaml
        If specified, returns the raw YAML string instead of parsed object
    
    .EXAMPLE
        $manifest = Get-WingetPackageManifest "Mozilla.Firefox.fr"
        $manifest.PackageVersion
    
    .EXAMPLE
        Get-WingetPackageManifest "Microsoft.PowerShell" -Version "7.4.0" -OutputPath "C:\temp\ps.yaml"
        
    .EXAMPLE
        $yaml = Get-WingetPackageManifest "Mozilla.Firefox.fr" -AsYaml

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$PackageId,
        
        [Parameter(Mandatory=$false)]
        [string]$Version,
        
        [Parameter(Mandatory=$false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$false)]
        [switch]$AsYaml
    )
    
    try {
        # Ensure powershell-yaml is installed and imported
        Import-PSModule -Name "powershell-yaml"
        
        # Get winget source URL
        $wingetSource = Get-WingetSources | Where-Object { $_.Name -eq "winget" }
        if (-not $wingetSource) {
            throw "Winget source not found. Please ensure winget is properly configured."
        }
        
        $baseUrl = $wingetSource.Arg
        Write-Verbose "Using Winget source: $baseUrl"
        
        # Get package from database
        $package = Get-WingetPackages -PackageId $PackageId
        if (-not $package) {
            throw "Package '$PackageId' not found in database"
        }
        
        # Use specified version or latest
        if (-not $Version) {
            $Version = $package.latest_version
            Write-Verbose "Using latest version: $Version"
        }
        
        # Get hash from database
        $dbHash = $package.hash
        if (-not ($dbHash -is [byte[]])) {
            throw "Invalid hash format in database"
        }
        
        $dbHashHex = ($dbHash | ForEach-Object { $_.ToString("x2") }) -join ''
        $hash8 = $dbHashHex.Substring(0, 8)
        
        # Download and decompress versionData.mszyml
        $versionDataUrl = "$baseUrl/packages/$PackageId/$hash8/versionData.mszyml"
        
        Write-Verbose "Downloading version data from: $versionDataUrl"
        
        $buffer = (Invoke-WebRequest -Uri $versionDataUrl -UseBasicParsing).Content
        $decompressedYaml = ConvertFrom-MSZIPYaml -Buffer $buffer
        
        # Parse YAML to get version info
        $versionData = ConvertFrom-Yaml $decompressedYaml
        
        # Find the version entry
        $versionEntry = $versionData.vD | Where-Object { $_.v -eq $Version } | Select-Object -First 1
        
        if (-not $versionEntry) {
            throw "Version '$Version' not found in versionData"
        }
        
        $relativePath = $versionEntry.rP
        Write-Verbose "Relative path: $relativePath"
        
        # Download the manifest from CDN (NOT compressed)
        $manifestUrl = "$baseUrl/$relativePath"
        Write-Verbose "Downloading manifest from: $manifestUrl"
        
        $response = Invoke-WebRequest -Uri $manifestUrl -UseBasicParsing
        
        # Ensure we get a string
        if ($response.Content -is [byte[]]) {
            $manifestYaml = [System.Text.Encoding]::UTF8.GetString($response.Content)
        } else {
            $manifestYaml = $response.Content
        }
        
        # Save to file if requested
        if ($OutputPath) {
            $manifestYaml | Set-Content -Path $OutputPath -Encoding UTF8
            Write-Host "Manifest saved to: $OutputPath" -ForegroundColor Green
        }
        
        # Return as YAML string or parsed object
        if ($AsYaml) {
            return [string]$manifestYaml
        } else {
            $manifestObject = ConvertFrom-Yaml $manifestYaml
            if ($manifestObject -is [hashtable]) {
                $manifestObject.VersionData = $versionData
            }
            return $manifestObject
        }
        
    } catch {
        Write-Error "Failed to retrieve manifest for $PackageId v$Version : $_"
        return $null
    }
}