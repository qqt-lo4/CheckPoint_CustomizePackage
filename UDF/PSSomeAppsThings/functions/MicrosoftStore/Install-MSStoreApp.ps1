function Install-MSStoreApp {
    <#
    .SYNOPSIS
    Installs a Microsoft Store application

    .DESCRIPTION
    Installs a Microsoft Store application using native installation methods.
    - For MSIX/APPX apps: Uses Add-AppxPackage (user scope) or Add-AppxProvisionedPackage (machine scope)
    - For Win32 Store apps: Downloads and executes the installer

    Handles dependencies automatically by installing them in the correct order.

    .PARAMETER Package
    Package object from config.json with Source="msstore"
    Must contain: Id (ProductId), Scope (user/machine), Name

    .PARAMETER Architecture
    Target architecture. Default: Autodetect
    Valid values: x64, x86, arm64, arm, neutral, Autodetect

    .EXAMPLE
    $package = @{ Id = "9NKSQGP7F2NH"; Scope = "user"; Name = "WhatsApp" }
    Install-MSStoreApp -Package $package

    .EXAMPLE
    Install-MSStoreApp -Package $package -Architecture x64 -Verbose

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Package,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    Write-Host "Installing Microsoft Store app: $($Package.Name)" -ForegroundColor Cyan

    try {
        # Step 1: Get unified Store app information
        Write-Verbose "Retrieving Store app information for ProductId: $($Package.Id)"
        $storeInfo = Get-UnifiedStoreAppInfo -ProductId $Package.Id -Architecture Autodetect -ErrorAction Stop -LatestVersionsOnly

        if ($storeInfo.AppType -eq "MSIX/AppX") {
            Write-Host "  Type: MSIX/APPX (Modern Store App)" -ForegroundColor Gray
            Install-MSStoreAppx -StoreInfo $storeInfo -Scope $Package.Scope -Force:$Force
        }
        elseif ($storeInfo.AppType -eq "Win32") {
            Write-Host "  Type: Win32 Installer" -ForegroundColor Gray
            Install-MSStoreWin32 -StoreInfo $storeInfo -Scope $Package.Scope
        }
        else {
            throw "Unknown app type: $($storeInfo.AppType)"
        }

        Write-Host "  ✓ Installation completed successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "  ✗ Installation failed: $_" -ForegroundColor Red
        Write-Verbose "Error details: $($_.Exception.Message)"
        Write-Verbose "Stack trace: $($_.ScriptStackTrace)"
        return $false
    }
}

function Install-MSStoreAppx {
    <#
    .SYNOPSIS
    Installs MSIX/APPX Store packages

    .DESCRIPTION
    Downloads and installs MSIX/APPX packages with their dependencies.
    Uses Add-AppxPackage for user scope or Add-AppxProvisionedPackage for machine scope.
    Automatically handles already-provisioned packages by updating them.

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$StoreInfo,

        [Parameter(Mandatory = $true)]
        [ValidateSet('user', 'machine')]
        [string]$Scope,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $tempDir = Join-Path $env:TEMP "MSStoreDownload_$([guid]::NewGuid().ToString())"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    Write-Verbose "Created temporary directory: $tempDir"

    try {
        $packages = $StoreInfo.DownloadInfo.Packages

        # Step 1: Separate dependencies and main package
        $dependencies = @($packages | Where-Object { $_.IsMainPackage -eq $false })
        $mainPackage = $packages | Where-Object { $_.IsMainPackage -eq $true } | Select-Object -First 1

        if (-not $mainPackage) {
            throw "No main package found in Store app information"
        }

        Write-Host "  Main package: $($mainPackage.PackageName) ($($mainPackage.Architecture))" -ForegroundColor Gray
        Write-Host "  Dependencies: $($dependencies.Count)" -ForegroundColor Gray

        # Step 2: Install dependencies first (only if not already installed)
        $dependencyPaths = @()
        foreach ($dep in $dependencies) {
            if ($dep.Installed) {
                Write-Host "    - $($dep.PackageName): Already installed (skipped)" -ForegroundColor DarkGray
                continue
            }

            Write-Host "    - Downloading dependency: $($dep.PackageName)" -ForegroundColor Gray
            $depPath = Join-Path $tempDir $dep.FileName

            try {
                $webClient = New-Object System.Net.WebClient
                $webClient.Headers.Add("User-Agent", "Microsoft-Delivery-Optimization/10.0")
                $webClient.DownloadFile($dep.Url, $depPath)
                $webClient.Dispose()

                $dependencyPaths += $depPath
                Write-Verbose "Downloaded dependency: $depPath ($([math]::Round($dep.Size / 1MB, 2)) MB)"
            }
            catch {
                Write-Warning "Failed to download dependency $($dep.PackageName): $_"
                # Continue anyway - the main package installation will fail if dependency is truly required
            }
        }

        # Step 3: Download main package
        Write-Host "  Downloading main package: $($mainPackage.FileName)" -ForegroundColor Gray
        $mainPackagePath = Join-Path $tempDir $mainPackage.FileName

        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Microsoft-Delivery-Optimization/10.0")

        # Show progress for large downloads
        $startTime = Get-Date
        $webClient.DownloadFile($mainPackage.Url, $mainPackagePath)
        $webClient.Dispose()

        $duration = (Get-Date) - $startTime
        $sizeMB = [math]::Round($mainPackage.Size / 1MB, 2)
        Write-Verbose "Downloaded main package: $mainPackagePath ($sizeMB MB in $($duration.TotalSeconds)s)"

        # Step 4: Install dependencies
        if ($dependencyPaths.Count -gt 0) {
            Write-Host "  Installing $($dependencyPaths.Count) dependencies..." -ForegroundColor Gray
            foreach ($depPath in $dependencyPaths) {
                Write-Verbose "Installing dependency: $depPath"
                try {
                    if ($Scope -eq "machine") {
                        Add-AppxProvisionedPackage -Online -PackagePath $depPath -SkipLicense -ErrorAction Stop | Out-Null
                    }
                    else {
                        Add-AppxPackage -Path $depPath -ErrorAction Stop
                    }
                    Write-Host "    ✓ Installed: $(Split-Path $depPath -Leaf)" -ForegroundColor DarkGreen
                }
                catch {
                    Write-Warning "Failed to install dependency $(Split-Path $depPath -Leaf): $_"
                }
            }
        }

        # Step 5: Install main package
        Write-Host "  Installing main package..." -ForegroundColor Gray

        # Extract version from downloaded package name (format: Name_Version_Arch_...)
        $downloadedVersion = $null
        if ($mainPackage.PackageName -match '_(\d+\.\d+\.\d+\.\d+)_') {
            $downloadedVersion = [version]$matches[1]
        }
        Write-Verbose "Downloaded package version: $downloadedVersion"

        if ($Scope -eq "machine") {
            Write-Verbose "Installing for all users (machine scope)"

            # Extract package name from main package for provisioning check
            $packageBaseName = $mainPackage.PackageName -replace '_.*$', ''
            Write-Verbose "Checking if package '$packageBaseName' is already provisioned..."

            # Check if already provisioned
            $existingProvisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -eq $packageBaseName }

            if ($existingProvisioned) {
                Write-Host "  Package already provisioned: $($existingProvisioned.PackageName)" -ForegroundColor Yellow
                Write-Host "  Existing version: $($existingProvisioned.Version)" -ForegroundColor Gray
                Write-Host "  Downloaded version: $downloadedVersion" -ForegroundColor Gray

                # Compare versions
                $existingVersion = [version]$existingProvisioned.Version
                if ($downloadedVersion -and $existingVersion -ge $downloadedVersion) {
                    Write-Host "  ✓ Existing version ($existingVersion) is same or newer than downloaded ($downloadedVersion)" -ForegroundColor Green
                    Write-Host "  Skipping installation - package is already up to date" -ForegroundColor Yellow
                    return
                }

                # Downloaded version is newer, proceed with update
                Write-Host "  Upgrading from $existingVersion to $downloadedVersion..." -ForegroundColor Cyan

                # Try using DISM for provisioned package update (more reliable than Add-AppxPackage)
                try {
                    # Remove existing provisioned package first
                    Write-Verbose "Removing existing provisioned package..."
                    Remove-AppxProvisionedPackage -Online -PackageName $existingProvisioned.PackageName -ErrorAction Stop | Out-Null
                    Write-Verbose "Removed existing provisioned package"

                    # Re-provision with new version
                    Write-Verbose "Re-provisioning with new version..."
                    if ($dependencyPaths.Count -gt 0) {
                        Add-AppxProvisionedPackage -Online -PackagePath $mainPackagePath -DependencyPackagePath $dependencyPaths -SkipLicense -ErrorAction Stop | Out-Null
                    }
                    else {
                        Add-AppxProvisionedPackage -Online -PackagePath $mainPackagePath -SkipLicense -ErrorAction Stop | Out-Null
                    }
                    Write-Host "  ✓ Package upgraded successfully" -ForegroundColor Green
                }
                catch {
                    throw "Failed to upgrade provisioned package: $_"
                }
            }
            else {
                # Not provisioned yet, use Add-AppxProvisionedPackage
                Write-Verbose "Package not provisioned, using Add-AppxProvisionedPackage"
                if ($dependencyPaths.Count -gt 0) {
                    Add-AppxProvisionedPackage -Online -PackagePath $mainPackagePath -DependencyPackagePath $dependencyPaths -SkipLicense -ErrorAction Stop | Out-Null
                }
                else {
                    Add-AppxProvisionedPackage -Online -PackagePath $mainPackagePath -SkipLicense -ErrorAction Stop | Out-Null
                }
            }
        }
        else {
            Write-Verbose "Installing for current user (user scope) using Add-AppxPackage"
            Add-AppxPackage -Path $mainPackagePath -ErrorAction Stop
        }

        Write-Verbose "Main package installed successfully"
    }
    finally {
        # Cleanup temporary directory
        if (Test-Path $tempDir) {
            Write-Verbose "Cleaning up temporary directory: $tempDir"
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Install-MSStoreWin32 {
    <#
    .SYNOPSIS
    Installs Win32 Store applications

    .DESCRIPTION
    Downloads and installs Win32 installers from the Microsoft Store.

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$StoreInfo,

        [Parameter(Mandatory = $true)]
        [ValidateSet('user', 'machine')]
        [string]$Scope
    )

    $downloadInfo = $StoreInfo.DownloadInfo

    Write-Host "  Installer: $($downloadInfo.InstallerType) ($($downloadInfo.Architecture))" -ForegroundColor Gray
    Write-Verbose "Installer URL: $($downloadInfo.InstallerUrl)"

    # Create temporary directory
    $tempDir = Join-Path $env:TEMP "MSStoreWin32_$([guid]::NewGuid().ToString())"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    try {
        # Download installer
        $installerFileName = "installer_$([guid]::NewGuid().ToString().Substring(0,8)).$($downloadInfo.InstallerType)"
        $installerPath = Join-Path $tempDir $installerFileName

        Write-Host "  Downloading installer..." -ForegroundColor Gray
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Microsoft-Delivery-Optimization/10.0")
        $webClient.DownloadFile($downloadInfo.InstallerUrl, $installerPath)
        $webClient.Dispose()

        Write-Verbose "Downloaded installer to: $installerPath"

        # Verify SHA256 if available
        if ($downloadInfo.InstallerSha256) {
            Write-Verbose "Verifying installer SHA256..."
            $fileHash = (Get-FileHash -Path $installerPath -Algorithm SHA256).Hash
            if ($fileHash -ne $downloadInfo.InstallerSha256) {
                throw "SHA256 mismatch! Expected: $($downloadInfo.InstallerSha256), Got: $fileHash"
            }
            Write-Verbose "SHA256 verification passed"
        }

        # Build installer arguments
        $installerArgs = @()
        if ($downloadInfo.InstallerSwitches) {
            $installerArgs += $downloadInfo.InstallerSwitches
        }

        # Add scope-specific arguments if needed
        if ($Scope -eq "machine" -and $downloadInfo.InstallerType -in @("msi", "exe", "msix")) {
            # Most installers support these switches for all users installation
            if ($downloadInfo.InstallerSwitches -notmatch "/allusers|ALLUSERS") {
                $installerArgs += "/allusers"
            }
        }

        # Execute installer
        Write-Host "  Executing installer..." -ForegroundColor Gray
        Write-Verbose "Command: $installerPath $($installerArgs -join ' ')"

        $process = Start-Process -FilePath $installerPath -ArgumentList $installerArgs -Wait -PassThru -NoNewWindow

        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
            Write-Verbose "Installer completed with exit code $($process.ExitCode)"
            $script:LastInstallExitCode = $process.ExitCode
        }
        else {
            Write-Warning "Installer completed with exit code: $($process.ExitCode)"
        }
    }
    finally {
        # Cleanup
        if (Test-Path $tempDir) {
            Write-Verbose "Cleaning up temporary directory: $tempDir"
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
