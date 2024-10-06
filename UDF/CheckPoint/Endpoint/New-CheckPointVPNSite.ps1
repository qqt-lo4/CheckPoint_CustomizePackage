function New-CheckPointVPNSite {
    Param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = "authMethod")]
        [Parameter(Mandatory, Position = 0, ParameterSetName = "LoginOption")]
        [string]$site,
        [Parameter(ParameterSetName = "authMethod")]
        [Parameter(ParameterSetName = "LoginOption")]
        [string]$displayName,
        [ValidateSet("username-password", "certificate", "p12-certificate", `
                     "challenge-response", "securIDKeyFob", "securIDPinPad", "SoftID")]
        [Parameter(Mandatory, ParameterSetName = "authMethod")]
        [string]$authenticationMethod,
        [Parameter(Mandatory, ParameterSetName = "LoginOption")]
        [string]$loginOption,
        [string]$tracexe = $(Get-CheckPointTracExe)
    )
    if (Test-Path -Path $tracexe -PathType Leaf) {
        $arguments = @("create", "-s", $site)
        if ($displayName) {
            $arguments += "-di"
            $arguments += $displayName
        }
        if ($loginOption) {
            $arguments += "-lo"
            $arguments += $loginOption
        }
        if ($authenticationMethod) {
            $arguments += "-a"
            $arguments += $authenticationMethod
        }
        $textOutput = $(& $tracexe @arguments)
        $outputLastLine = $textOutput[$textOutput.Count - 1].Trim().ToLower()
        $success = $($outputLastLine -eq "connection was successfully created")
        return New-Object psobject -Property @{
            Success = $success
            Output = $textOutput
            Site = $site
        }
    } else {
        throw [System.IO.FileNotFoundException] "trac.exe file does not exists"
    }
}
