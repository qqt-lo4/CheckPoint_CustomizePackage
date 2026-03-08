function Get-MaketoolPath {
    <#
    .SYNOPSIS
        Retrieves the path(s) to maketool.bat on the local administrator workstation.

    .DESCRIPTION
        Searches for maketool.bat in standard SmartConsole installation directories.
        Supports both R80.x and R81.10+ installation paths.
        Returns a hashtable with major versions as keys for easy selection.

    .OUTPUTS
        Hashtable. Keys are SmartConsole major versions (e.g., "R81.20", "R80.40"), values are full paths.

    .EXAMPLE
        $maketoolVersions = Get-MaketoolPath
        $maketoolVersions["R81.20"]

    .EXAMPLE
        $maketoolVersions = Get-MaketoolPath
        $maketoolVersions.Keys | ForEach-Object { Write-Host "$_ : $($maketoolVersions[$_])" }

    .NOTES
        Author  : Assistant
        Version : 1.1.0
    #>
    [CmdletBinding()]
    Param()

    Process {
        $hResult = @{}

        # SmartConsole base paths
        $aBasePaths = @(
            "${env:ProgramFiles(x86)}\CheckPoint\SmartConsole",
            "$env:ProgramFiles\CheckPoint\SmartConsole"
        )

        foreach ($sBasePath in $aBasePaths) {
            if (-not (Test-Path $sBasePath)) {
                continue
            }

            # Get all version folders
            $aVersionFolders = Get-ChildItem -Path $sBasePath -Directory -ErrorAction SilentlyContinue

            foreach ($oVersionFolder in $aVersionFolders) {
                $sVersion = $oVersionFolder.Name

                # R81.10+: Program\util\RepWorkFolder\INVOKE\maketool.bat
                $sPathR81 = Join-Path $oVersionFolder.FullName "Program\util\RepWorkFolder\INVOKE\maketool.bat"
                
                # R80.x and lower: PROGRAM\data\RepWorkFolder\INVOKE\maketool.bat
                $sPathR80 = Join-Path $oVersionFolder.FullName "PROGRAM\data\RepWorkFolder\INVOKE\maketool.bat"

                $sMaketoolPath = if (Test-Path $sPathR81) {
                    $sPathR81
                } elseif (Test-Path $sPathR80) {
                    $sPathR80
                } else {
                    $null
                }

                if ($sMaketoolPath) {
                    $hResult[$sVersion] = $sMaketoolPath
                }
            }
        }

        if ($hResult.Count -eq 0) {
            throw "maketool.bat not found. Please ensure SmartConsole is installed."
        }

        return $hResult
    }
}
