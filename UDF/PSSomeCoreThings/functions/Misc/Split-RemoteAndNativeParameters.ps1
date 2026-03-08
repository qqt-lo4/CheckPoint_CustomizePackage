function Split-RemoteAndNativeParameters {
    [CmdletBinding()]
    Param()
    $hParameters = (Get-PSCallStack)[1].InvocationInfo.BoundParameters
    $hRemoteParams = @{}
    if ($hParameters.ComputerName -or $hParameters.Session) {
        $hRemoteParams = if ($hParameters.Session) {
            @{Session = $hParameters.Session}
        } else {
            if ($hParameters.Credential) {
                @{
                    ComputerName = $hParameters.ComputerName
                    Credential = $hParameters.Credential
                }
            } else {
                @{
                    ComputerName = $hParameters.ComputerName
                }
            }                
        }
        $hParameters.Remove("Session")      | Out-Null
        $hParameters.Remove("ComputerName") | Out-Null
        $hParameters.Remove("Credential")   | Out-Null
    }
    return @{
        Remote = $hRemoteParams
        Native = $hParameters
    }
}