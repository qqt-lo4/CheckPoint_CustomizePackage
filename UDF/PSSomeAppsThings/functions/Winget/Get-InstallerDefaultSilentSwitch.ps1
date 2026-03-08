function Get-InstallerDefaultSilentSwitch {
    <#
    .SYNOPSIS
        Gets the default silent install switch for an installer type

    .DESCRIPTION
        Returns the standard silent/quiet command-line switches for common
        Windows installer types (MSI, WiX, Inno Setup, NSIS).

    .PARAMETER InstallerType
        The installer type: portable, exe, msi, wix, inno, nullsoft

    .OUTPUTS
        System.String. The silent install command-line switches.

    .EXAMPLE
        Get-InstallerDefaultSilentSwitch -InstallerType "inno"
        # Returns "/SP- /VERYSILENT /NORESTART"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$InstallerType
    )
    switch ($InstallerType) {
        "portable" {
            ""
        }
        "exe" {
            ""
        }
        "msi" {
            "/quiet /norestart"
        }
        "wix" {
            "/quiet /norestart"
        }
        "inno" {
            "/SP- /VERYSILENT /NORESTART"
        }
        "nullsoft" {
            "/S"
        }
    }
}