function Get-DeviceMSAToken {
    <#
    .SYNOPSIS
    Retrieves the MSA Device Token from Windows registry or uses fallback
    
    .DESCRIPTION
    Attempts to retrieve the Microsoft Store Authentication (MSA) Device Token by:
    1. Reading from cache in ProgramData (if available)
    2. Extracting from SYSTEM registry via Invoke-AsSystem (if admin)
    3. Requesting UAC elevation if ElevateIfNeeded is specified
    4. Checking standard registry locations
    5. Using a valid fallback token
    
    Successfully retrieved tokens are cached to ProgramData to avoid re-extraction.
    
    .PARAMETER ElevateIfNeeded
    If specified and the current process is not elevated, will prompt for UAC elevation
    to extract the real device token from SYSTEM registry.
    
    .PARAMETER SkipCache
    If specified, bypasses reading from cache and forces fresh token extraction.
    The newly extracted token will still be cached for future use.
    
    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        The MSA Device Token enables authentication with Microsoft Store services.
        Cached tokens are stored in: $env:ProgramData\StoreLib\MSAToken.dat
    
    .EXAMPLE
    Get-DeviceMSAToken
    
    .EXAMPLE
    Get-DeviceMSAToken -ElevateIfNeeded
    
    .EXAMPLE
    Get-DeviceMSAToken -SkipCache -ElevateIfNeeded
    #>
    
    [CmdletBinding()]
    param(
        [switch]$ElevateIfNeeded,
        [switch]$SkipCache
    )
    
    # Define cache location
    $cacheDir = Join-Path $env:ProgramData "StoreLib"
    $cacheFile = Join-Path $cacheDir "MSAToken.dat"
    
    # Helper function to save token to cache
    function Save-TokenToCache {
        param([string]$Token)
        
        try {
            if (-not (Test-Path $cacheDir)) {
                New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
                Write-Verbose "Created cache directory: $cacheDir"
            }
            
            $Token | Out-File -FilePath $cacheFile -Encoding UTF8 -NoNewline -Force
            Write-Verbose "Token cached to: $cacheFile"
            
            # Set permissions for all users to read
            $acl = Get-Acl $cacheFile
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "Read", "Allow")
            $acl.SetAccessRule($rule)
            Set-Acl -Path $cacheFile -AclObject $acl
            
            return $true
        }
        catch {
            Write-Verbose "Failed to cache token: $_"
            return $false
        }
    }
    
    try {
        # Try to read from cache first
        if (-not $SkipCache -and (Test-Path $cacheFile)) {
            try {
                $cachedToken = Get-Content -Path $cacheFile -Raw -Encoding UTF8 -ErrorAction Stop
                
                if ($cachedToken -and $cachedToken.Trim().Length -gt 0 -and $cachedToken -match '^<Device>.+</Device>$') {
                    Write-Verbose "MSA Device Token loaded from cache: $cacheFile"
                    return $cachedToken
                }
                else {
                    Write-Verbose "Cached token is invalid, will extract fresh token"
                }
            }
            catch {
                Write-Verbose "Failed to read cache: $_"
            }
        }
        elseif ($SkipCache) {
            Write-Verbose "Cache bypassed (SkipCache specified)"
        }
        
        # Check if running as admin
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        # Handle UAC elevation if requested and not admin
        if (-not $isAdmin -and $ElevateIfNeeded) {
            Write-Verbose "Not running as administrator, requesting UAC elevation..."
            
            $outputFile = [System.IO.Path]::GetTempFileName()
            
            # Script that runs as admin and calls Invoke-AsSystem
            $elevatedScript = @"
# Import the module functions we need
$(Get-FunctionCode -FunctionName "Get-FunctionCode")

$(Get-FunctionCode -FunctionName "Invoke-AsSystem")

$(Get-FunctionCode -FunctionName "Invoke-SystemTokenExtraction")

# Extract token using Invoke-AsSystem
try {
    Invoke-AsSystem -ScriptBlock {
        Invoke-SystemTokenExtraction -OutputFile `$OutputFile
    } -RequiredFunctions @("Invoke-SystemTokenExtraction") -OutputFile '$outputFile' -Timeout 15
    
    'done' | Out-File -FilePath '$outputFile.done' -Encoding UTF8
} catch {
    # Error occurred
}
"@
            
            $scriptFile = "$env:TEMP\ElevateTokenExtraction.ps1"
            $elevatedScript | Out-File -FilePath $scriptFile -Encoding UTF8
            
            try {
                # Launch elevated PowerShell
                $psi = New-Object System.Diagnostics.ProcessStartInfo
                $psi.FileName = "powershell.exe"
                $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptFile`""
                $psi.Verb = "runas"
                $psi.UseShellExecute = $true
                $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
                $psi.CreateNoWindow = $true
                
                $process = [System.Diagnostics.Process]::Start($psi)
                
                if ($process) {
                    Write-Verbose "Elevated process started, waiting for token extraction..."
                    
                    # Wait with progress
                    $timeout = 20
                    $elapsed = 0
                    
                    while ($elapsed -lt $timeout) {
                        if (Test-Path "$outputFile.done") {
                            Write-Progress -Activity "Retrieving MSA Device Token" -Status "Token retrieved successfully" -PercentComplete 100 -Completed
                            break
                        }
                        
                        $percentComplete = [Math]::Min(99, ($elapsed / $timeout) * 100)
                        $secondsRemaining = [Math]::Max(0, $timeout - $elapsed)
                        
                        Write-Progress -Activity "Retrieving MSA Device Token" `
                                       -Status "Extracting token from SYSTEM registry... ($([Math]::Round($elapsed, 1))s / ${timeout}s)" `
                                       -PercentComplete $percentComplete `
                                       -SecondsRemaining $secondsRemaining
                        
                        Start-Sleep -Milliseconds 500
                        $elapsed += 0.5
                    }
                    
                    if ($elapsed -ge $timeout) {
                        Write-Progress -Activity "Retrieving MSA Device Token" -Status "Timeout - using fallback token" -PercentComplete 100 -Completed
                    }
                    
                    # Read token
                    if (Test-Path $outputFile) {
                        $elevatedToken = Get-Content -Path $outputFile -Raw -Encoding UTF8
                        
                        Remove-Item -Path $outputFile, "$outputFile.done", $scriptFile -Force -ErrorAction SilentlyContinue
                        
                        if ($elevatedToken -and $elevatedToken.Trim().Length -gt 0) {
                            Write-Verbose "MSA Device Token retrieved via UAC elevation"
                            Save-TokenToCache -Token $elevatedToken | Out-Null
                            return $elevatedToken
                        }
                    }
                    
                    Remove-Item -Path $outputFile, "$outputFile.done", $scriptFile -Force -ErrorAction SilentlyContinue
                    Write-Verbose "Elevation completed but token extraction failed"
                }
            }
            catch {
                Write-Progress -Activity "Retrieving MSA Device Token" -Status "Elevation cancelled" -PercentComplete 100 -Completed
                Write-Verbose "UAC elevation was declined or failed: $_"
                Remove-Item -Path $outputFile, "$outputFile.done", $scriptFile -Force -ErrorAction SilentlyContinue
            }
        }
        
        # If already admin, extract using Invoke-AsSystem
        if ($isAdmin) {
            try {
                $tokenFile = [System.IO.Path]::GetTempFileName()
                
                $extractedToken = Invoke-AsSystem -ScriptBlock {
                    Invoke-SystemTokenExtraction -OutputFile $OutputFile
                } -RequiredFunctions @("Invoke-SystemTokenExtraction") -OutputFile $tokenFile -Timeout 10
                
                if ($extractedToken -and $extractedToken.Trim().Length -gt 0) {
                    Write-Verbose "MSA Device Token retrieved from SYSTEM registry via Invoke-AsSystem"
                    Save-TokenToCache -Token $extractedToken | Out-Null
                    return $extractedToken
                }
            }
            catch {
                Write-Verbose "Could not extract token via Invoke-AsSystem: $_"
            }
        }
        
        # Try standard HKLM locations
        $tokenPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Store\StoreClient'
        if (Test-Path $tokenPath) {
            $token = Get-ItemProperty -Path $tokenPath -Name 'ServiceToken' -ErrorAction SilentlyContinue
            if ($token -and $token.ServiceToken) {
                $deviceToken = "<Device>$($token.ServiceToken)</Device>"
                Write-Verbose "MSA Device Token retrieved from HKLM StoreClient"
                Save-TokenToCache -Token $deviceToken | Out-Null
                return $deviceToken
            }
        }
        
        $tokenPath2 = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator'
        if (Test-Path $tokenPath2) {
            $tokenData = Get-ItemProperty -Path $tokenPath2 -Name 'TokenData' -ErrorAction SilentlyContinue
            if ($tokenData -and $tokenData.TokenData) {
                $deviceToken = "<Device>$($tokenData.TokenData)</Device>"
                Write-Verbose "MSA Device Token retrieved from WindowsUpdate Orchestrator"
                Save-TokenToCache -Token $deviceToken | Out-Null
                return $deviceToken
            }
        }
        
        # No accessible token found
        if ($ElevateIfNeeded -and -not $isAdmin) {
            Write-Verbose "MSA Device Token extraction failed or was declined, using generic fallback token"
        } else {
            Write-Verbose "MSA Device Token not found, using generic fallback token"
        }
    }
    catch {
        Write-Verbose "Error accessing registry: $($_.Exception.Message)"
    }
    
    # Fallback token
    return '<Device>dAA9AEUAdwBBAHcAQQBzAE4AMwBCAEEAQQBVADEAYgB5AHMAZQBtAGIAZQBEAFYAQwArADMAZgBtADcAbwBXAHkASAA3AGIAbgBnAEcAWQBtAEEAQQBMAGoAbQBqAFYAVQB2AFEAYwA0AEsAVwBFAC8AYwBDAEwANQBYAGUANABnAHYAWABkAGkAegBHAGwAZABjADEAZAAvAFcAeQAvAHgASgBQAG4AVwBRAGUAYwBtAHYAbwBjAGkAZwA5AGoAZABwAE4AawBIAG0AYQBzAHAAVABKAEwARAArAFAAYwBBAFgAbQAvAFQAcAA3AEgAagBzAEYANAA0AEgAdABsAC8AMQBtAHUAcgAwAFMAdQBtAG8AMABZAGEAdgBqAFIANwArADQAcABoAC8AcwA4ADEANgBFAFkANQBNAFIAbQBnAFIAQwA2ADMAQwBSAEoAQQBVAHYAZgBzADQAaQB2AHgAYwB5AEwAbAA2AHoAOABlAHgAMABrAFgAOQBPAHcAYQB0ADEAdQBwAFMAOAAxAEgANgA4AEEASABzAEoAegBnAFQAQQBMAG8AbgBBADIAWQBBAEEAQQBpAGcANQBJADMAUQAvAFYASABLAHcANABBAEIAcQA5AFMAcQBhADEAQgA4AGsAVQAxAGEAbwBLAEEAdQA0AHYAbABWAG4AdwBWADMAUQB6AHMATgBtAEQAaQBqAGgANQBkAEcAcgBpADgAQQBlAEUARQBWAEcAbQBXAGgASQBCAE0AUAAyAEQAVwA0ADMAZABWAGkARABUAHoAVQB0AHQARQBMAEgAaABSAGYAcgBhAGIAWgBsAHQAQQBUAEUATABmAHMARQBGAFUAYQBRAFMASgB4ADUAeQBRADgAagBaAEUAZQAyAHgANABCADMAMQB2AEIAMgBqAC8AUgBLAGEAWQAvAHEAeQB0AHoANwBUAHYAdAB3AHQAagBzADYAUQBYAEIAZQA4AHMAZwBJAG8AOQBiADUAQQBCADcAOAAxAHMANgAvAGQAUwBFAHgATgBEAEQAYQBRAHoAQQBYAFAAWABCAFkAdQBYAFEARQBzAE8AegA4AHQAcgBpAGUATQBiAEIAZQBUAFkAOQBiAG8AQgBOAE8AaQBVADcATgBSAEYAOQAzAG8AVgArAFYAQQBiAGgAcAAwAHAAUgBQAFMAZQBmAEcARwBPAHEAdwBTAGcANwA3AHMAaAA5AEoASABNAHAARABNAFMAbgBrAHEAcgAyAGYARgBpAEMAUABrAHcAVgBvAHgANgBuAG4AeABGAEQAbwBXAC8AYQAxAHQAYQBaAHcAegB5AGwATABMADEAMgB3AHUAYgBtADUAdQBtAHAAcQB5AFcAYwBLAFIAagB5AGgAMgBKAFQARgBKAFcANQBnAFgARQBJADUAcAA4ADAARwB1ADIAbgB4AEwAUgBOAHcAaQB3AHIANwBXAE0AUgBBAFYASwBGAFcATQBlAFIAegBsADkAVQBxAGcALwBwAFgALwB2AGUATAB3AFMAawAyAFMAUwBIAGYAYQBLADYAagBhAG8AWQB1AG4AUgBHAHIAOABtAGIARQBvAEgAbABGADYASgBDAGEAYQBUAEIAWABCAGMAdgB1AGUAQwBKAG8AOQA4AGgAUgBBAHIARwB3ADQAKwBQAEgAZQBUAGIATgBTAEUAWABYAHoAdgBaADYAdQBXADUARQBBAGYAZABaAG0AUwA4ADgAVgBKAGMAWgBhAEYASwA3AHgAeABnADAAdwBvAG4ANwBoADAAeABDADYAWgBCADAAYwBZAGoATAByAC8ARwBlAE8AegA5AEcANABRAFUASAA5AEUAawB5ADAAZAB5AEYALwByAGUAVQAxAEkAeQBpAGEAcABwAGgATwBQADgAUwAyAHQANABCAHIAUABaAFgAVAB2AEMAMABQADcAegBPACsAZgBHAGsAeABWAG0AKwBVAGYAWgBiAFEANQA1AHMAdwBFAD0AJgBwAD0A</Device>'
}
