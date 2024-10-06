function Get-CheckPointFile {
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