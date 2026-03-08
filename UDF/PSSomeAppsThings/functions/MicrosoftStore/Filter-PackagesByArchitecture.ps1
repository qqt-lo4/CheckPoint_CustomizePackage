function Filter-PackagesByArchitecture {
    <#
    .SYNOPSIS
    Filter packages by target architecture

    .DESCRIPTION
    Filters packages based on architecture property of package objects.
    Supports Autodetect mode which uses Get-SystemArchitecture to detect system architecture.
    Priority order for Autodetect: Primary architecture → neutral packages → fallback architectures

    .PARAMETER Packages
    Array of package objects to filter

    .PARAMETER Architecture
    Architecture to filter by: x64, x86, arm64, arm, neutral, all, or Autodetect (default)
    - Autodetect: Returns packages in priority order (primary → neutral → fallbacks)
    - Specific architecture: Returns only packages matching that architecture + neutral packages
    - all: Returns all packages without filtering

    .PARAMETER Property
    Property name to use for architecture detection (default: Architecture)
    Falls back to filename parsing if property doesn't exist

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Packages,

        [Parameter(Mandatory=$false)]
        [ValidateSet('x64', 'x86', 'arm64', 'arm', 'neutral', 'all', 'Autodetect')]
        [string]$Architecture = 'Autodetect',

        [Parameter(Mandatory=$false)]
        [string]$Property = 'Architecture'
    )

    # Handle "all" mode - return everything
    if ($Architecture -eq "all") {
        Write-Verbose "Returning all $($Packages.Count) packages (no architecture filter)"
        return $Packages
    }

    # Build priority list of architectures to try
    if ($Architecture -eq 'Autodetect') {
        $sysArch = Get-SystemArchitecture
        # Priority: Primary → neutral → Fallbacks
        $architecturePriority = @($sysArch.Primary) + @('neutral') + $sysArch.Fallback
        Write-Verbose "Auto-detect priority order: $($architecturePriority -join ' → ')"
    }
    else {
        # For specific architecture
        $architecturePriority = @($Architecture)
        Write-Verbose "Filtering for architecture: $Architecture"
    }

    # Return first matching packages by architecture priority
    foreach ($arch in $architecturePriority) {
        $matchingPackages = $Packages | Where-Object { $_.$Property -eq $arch }
        if ($matchingPackages) {
            Write-Verbose "Found $($matchingPackages.Count) package(s) for architecture: $arch"
            return $matchingPackages
        }
    }

    Write-Verbose "No matching packages found"
    return @()
}
