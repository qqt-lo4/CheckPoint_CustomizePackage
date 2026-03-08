function Download-StoreApp {
    <#
    .SYNOPSIS
        Downloads Microsoft Store app packages to a local directory

    .DESCRIPTION
        Downloads all package files (main app and dependencies) for a Microsoft Store
        application identified by its Product ID. Creates the output directory if needed.

    .PARAMETER ProductId
        The 12-character Microsoft Store Product ID (e.g., 9NKSQGP7F2NH)

    .PARAMETER OutputPath
        Directory path where downloaded files will be saved

    .PARAMETER Architecture
        Target architecture filter: x64, x86, ARM64, ARM, neutral, or All (default: All)

    .PARAMETER Market
        Market code (default: US)

    .PARAMETER Language
        Language code (default: en-US)

    .OUTPUTS
        Array of downloaded file paths

    .EXAMPLE
        Download-StoreApp -ProductId "9NKSQGP7F2NH" -OutputPath "C:\Temp\StoreApps"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidatePattern('^[A-Z0-9]{12}$')]
        [string]$ProductId,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('x64', 'x86', 'ARM64', 'ARM', 'neutral', 'All')]
        [string]$Architecture = 'All',
        
        [Parameter(Mandatory=$false)]
        [string]$Market = 'US',
        
        [Parameter(Mandatory=$false)]
        [string]$Language = 'en-US'
    )
    
    Begin {
        if (-not (Test-Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }
    }
    
    Process {
        try {
            # Get app information including URLs and dependencies
            $appInfo = Get-StoreAppInfo -ProductId $ProductId -Architecture $Architecture -Market $Market -Language $Language -Verbose:$VerbosePreference
            
            if (-not $appInfo -or -not $appInfo.Packages -or $appInfo.Packages.Count -eq 0) {
                Write-Warning "No files to download"
                return @()
            }
            
            # Download
            Write-Host "Downloading $($appInfo.PackageCount) file(s)..." -ForegroundColor Yellow
            Write-Host ""
            
            $downloaded = @()
            
            foreach ($item in $appInfo.Packages) {
                $fileName = $item.FileName
                $url = $item.Url
                $outputFile = Join-Path $OutputPath $fileName
                
                Write-Host "Downloading: $fileName" -ForegroundColor Cyan
                
                try {
                    $webClient = New-Object System.Net.WebClient
                    $webClient.Headers.Add("User-Agent", "StoreLib")
                    
                    $webClient.DownloadFile($url, $outputFile)
                    
                    $fileInfo = Get-Item $outputFile
                    $sizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
                    
                    Write-Host "✓ $fileName ($sizeMB MB)" -ForegroundColor Green
                    Write-Host ""
                    
                    $downloaded += $outputFile
                }
                catch {
                    Write-Warning "Error downloading $fileName : $($_.Exception.Message)"
                }
                finally {
                    if ($webClient) {
                        $webClient.Dispose()
                    }
                }
            }
            
            if ($downloaded.Count -gt 0) {
                Write-Host ""
                Write-Host "========================================" -ForegroundColor Green
                Write-Host "✓ Download complete!" -ForegroundColor Green
                Write-Host "Files: $($downloaded.Count)" -ForegroundColor Yellow
                Write-Host "Location: $OutputPath" -ForegroundColor Yellow
                Write-Host "========================================" -ForegroundColor Green
                
                $bundleFile = $downloaded | Where-Object { $_ -match '\.msixbundle$|\.appxbundle$' } | Select-Object -First 1
                if ($bundleFile) {
                    Write-Host ""
                    Write-Host "To install:" -ForegroundColor Cyan
                    Write-Host "Add-AppxPackage -Path '$bundleFile'" -ForegroundColor White
                    Write-Host ""
                }
            }
            
            return $downloaded
        }
        catch {
            throw
        }
    }
}
