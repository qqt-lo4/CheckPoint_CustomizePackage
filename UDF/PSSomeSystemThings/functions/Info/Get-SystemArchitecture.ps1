function Get-SystemArchitecture {
    <#
    .SYNOPSIS
        Retrieves the system architecture and its fallback architectures
    
    .DESCRIPTION
        Returns the primary system architecture and compatibility architectures
        Compatible with x86, x64, ARM, ARM64
        
        Microsoft documentation on ARM emulation:
        https://learn.microsoft.com/en-us/windows/arm/apps-on-arm-x86-emulation
        
        Emulation supported on ARM64:
        - Windows 10: ARM64, ARM, x86
        - Windows 11: ARM64, ARM, x86, x64 (x64 emulation added)
    
    .PARAMETER ExtendedInfo
        If specified, returns all detailed information.
        Otherwise, returns only Primary and Fallback.
    
    .EXAMPLE
        Get-SystemArchitecture
        Returns only Primary and Fallback
        On x64: Primary='x64', Fallback=@('x86')
    
    .EXAMPLE
        Get-SystemArchitecture -ExtendedInfo
        Returns all detailed information
    
    .EXAMPLE
        $arch = Get-SystemArchitecture
        $arch.Primary        # x64
        $arch.Fallback       # @('x86')
        $arch.Fallback[0]    # x86
    
    .EXAMPLE
        $arch = Get-SystemArchitecture -ExtendedInfo
        $arch.All            # @('ARM64', 'ARM', 'x64', 'x86') on Windows 11 ARM64
        $arch.SupportsX64Emulation  # True/False

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$ExtendedInfo
    )
    
    # Get processor architecture
    $processorArch = $env:PROCESSOR_ARCHITECTURE
    $processorArchW6432 = $env:PROCESSOR_ARCHITEW6432
    
    # Determine real system architecture
    # PROCESSOR_ARCHITEW6432 only exists in WOW64 mode (32-bit on 64-bit)
    if ($processorArchW6432) {
        $systemArch = $processorArchW6432
    } else {
        $systemArch = $processorArch
    }
    
    # Get Windows version for ARM64
    $osVersion = [System.Environment]::OSVersion.Version
    $isWindows11 = ($osVersion.Major -eq 10 -and $osVersion.Build -ge 22000) -or ($osVersion.Major -gt 10)
    
    # Initialize variables
    $primaryArch = $null
    $fallbackArchs = @()
    
    # Determine according to architecture
    switch ($systemArch) {
        'AMD64' {
            # x64 system (64-bit Intel/AMD)
            $primaryArch = 'x64'
            $fallbackArchs = @('x86')
        }
        'x86' {
            # x86 system (32-bit)
            $primaryArch = 'x86'
            $fallbackArchs = @()
        }
        'ARM64' {
            # ARM 64-bit system
            $primaryArch = 'ARM64'
            
            if ($isWindows11) {
                # Windows 11 ARM64: Supports ARM64, ARM, x64 (emulated), x86 (emulated)
                # Source: https://learn.microsoft.com/en-us/windows/arm/apps-on-arm-x86-emulation
                $fallbackArchs = @('ARM', 'x64', 'x86')
            } else {
                # Windows 10 ARM64: Supports ARM64, ARM, x86 (emulated only)
                $fallbackArchs = @('ARM', 'x86')
            }
        }
        'ARM' {
            # ARM 32-bit system
            $primaryArch = 'ARM'
            $fallbackArchs = @()
        }
        default {
            throw "Unrecognized architecture: $systemArch"
        }
    }
    
    # Build All architectures array (Primary + Fallback)
    $allArchs = @($primaryArch) + $fallbackArchs
    
    # If ExtendedInfo is not requested, return only Primary and Fallback
    if (-not $ExtendedInfo) {
        return [PSCustomObject]@{
            Primary  = $primaryArch
            Fallback = $fallbackArchs
        }
    }
    
    # Create full return object (ExtendedInfo)
    $archInfo = [PSCustomObject]@{
        # Primary architecture
        Primary = $primaryArch
        
        # Fallback/compatibility architectures (array, without Primary)
        Fallback = $fallbackArchs
        
        # All supported architectures (priority order: Primary + Fallback)
        All = $allArchs
        
        # Raw processor architecture
        RawArchitecture = $systemArch
        
        # Indicates if running in WOW64 mode (32-bit PowerShell on 64-bit system)
        IsWow64 = [bool]$processorArchW6432
        
        # System bits (32 or 64)
        SystemBits = if ($systemArch -match '64$') { 64 } else { 32 }
        
        # Microsoft Store format
        StoreFormat = $primaryArch
        
        # Windows version
        WindowsVersion = if ($isWindows11) { 'Windows 11+' } else { 'Windows 10 or earlier' }
        
        # Indicates if x64 emulation is available (ARM64 + Windows 11 only)
        SupportsX64Emulation = ($systemArch -eq 'ARM64' -and $isWindows11)
    }
    
    return $archInfo
}
