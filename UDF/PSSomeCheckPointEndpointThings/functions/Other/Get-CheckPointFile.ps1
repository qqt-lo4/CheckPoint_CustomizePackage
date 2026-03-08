function Get-CheckPointFile {
    <#
    .SYNOPSIS
        Retrieves the full path to a Check Point file

    .DESCRIPTION
        Gets the full path to a specified file in the Check Point installation directory.
        Automatically detects the correct path based on the Check Point product (VPN or Endpoint Security)
        and operating system architecture (x86 or x64).

    .PARAMETER filename
        Name of the file to locate (e.g., "trac.exe", "trac.defaults").

    .PARAMETER regkey
        Registry key object for Check Point installation.

    .PARAMETER applicationname
        Check Point application name ("Check Point VPN" or "Check Point Endpoint Security").

    .OUTPUTS
        [String]. Full path to the file, or empty string if not found.

    .EXAMPLE
        Get-CheckPointFile -filename "trac.exe"

    .EXAMPLE
        Get-CheckPointFile -filename "trac.defaults" -applicationname "Check Point Endpoint Security"

    .EXAMPLE
        $regkey = Get-CheckPointRegKey
        Get-CheckPointFile -filename "trac.exe" -regkey $regkey

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = "regkey")]
        [Parameter(Mandatory, Position = 0, ParameterSetName = "applicationname")]
        [Parameter(Mandatory, Position = 0, ParameterSetName = "noinfo")]
        [ValidateNotNullOrEmpty()]
        [string]$filename,
        [Parameter(Mandatory, Position = 1, ParameterSetName = "regkey")]
        [Microsoft.Win32.RegistryKey]$regkey,
        [Parameter(Mandatory, Position = 1, ParameterSetName = "applicationname")]
        [string]$applicationname
    )
    switch ($PSCmdlet.ParameterSetName) {
        "regkey" {
            $application = Get-CheckPointProduct -regkey $regkey
        }
        "applicationname" {
            $application = $applicationname
        }
        "noinfo" {
            $regkey = $(Get-CheckPointRegKey)
            $application = Get-CheckPointProduct -regkey $regkey
        }
    }
    $path = switch($application) {
        "Check Point VPN"   { 
                                if ([System.Environment]::Is64BitOperatingSystem) {
                                    "C:\Program Files (x86)\CheckPoint\Endpoint Connect\$filename"
                                } else {
                                    "C:\Program Files\CheckPoint\Endpoint Connect\$filename"
                                }
                            }
        "Check Point Endpoint Security"
                            { 
                                if ([System.Environment]::Is64BitOperatingSystem) {
                                    "C:\Program Files (x86)\CheckPoint\Endpoint Security\Endpoint Connect\$filename"
                                } else {
                                    "C:\Program Files\CheckPoint\Endpoint Security\Endpoint Connect\$filename"
                                }
                            }
        default { "" }
    }
    if (($path -ne "") -and (Test-Path -Path $path)) {
        return $path
    } else {
        return ""
    }
}