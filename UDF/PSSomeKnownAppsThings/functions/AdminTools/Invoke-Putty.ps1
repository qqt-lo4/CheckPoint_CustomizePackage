function Invoke-Putty {
    <#
    .SYNOPSIS
        Launches a PuTTY session to a remote host

    .DESCRIPTION
        Opens a PuTTY connection to a remote computer using SSH (v1 or v2) or
        Telnet. Supports authentication via username/password or PSCredential.

    .PARAMETER Computer
        The remote host to connect to.

    .PARAMETER PuttyPath
        Path to the PuTTY executable. Defaults to Search-PuttyPath result.

    .PARAMETER SSHv1
        Use SSH version 1.

    .PARAMETER SSHv2
        Use SSH version 2 (default).

    .PARAMETER Telnet
        Use Telnet protocol.

    .PARAMETER Username
        Username for authentication.

    .PARAMETER Password
        SecureString password for authentication.

    .PARAMETER Credential
        PSCredential for authentication (alternative to Username/Password).

    .EXAMPLE
        Invoke-Putty -Computer "192.168.1.1" -Credential $cred

    .EXAMPLE
        Invoke-Putty -Computer "switch01" -Telnet

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdletBinding(DefaultParameterSetName = "SSHv2")]
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Computer,
        [string]$PuttyPath = (Search-PuttyPath),
        [Parameter(ParameterSetName = "SSHv1")]
        [switch]$SSHv1,
        [Parameter(ParameterSetName = "SSHv2")]
        [switch]$SSHv2,
        [Parameter(ParameterSetName = "Telnet")]
        [switch]$Telnet,
        [string]$Username,
        [securestring]$Password,
        [pscredential]$Credential
    )
    if (-not $PuttyPath) {
        throw "Putty not found"
    }
    if ($Credential -and $Username) {
        throw "Can't have Username and Credential at the same time"
    }
    if ($Password -and (-not $Username))  {
        throw "Can't have a password without a username"
    }
    $aPuttyArgs = @()
    if ($SSHv1) {
        $aPuttyArgs += "-ssh"
        $aPuttyArgs += "-1"
    }
    if ($SSHv2) {
        $aPuttyArgs += "-ssh"
        $aPuttyArgs += "-2"
    }
    if ($Telnet) {
        $aPuttyArgs += "-telnet"
    }
    if ($Username -or $Credential) {
        $sUsername = if ($Username) { $Username } else { $Credential.UserName }
        $aPuttyArgs += "-l"
        $aPuttyArgs += $sUsername
    }
    if ($Password -or $Credential) {
        $ssPass = if ($Password) { $Password } else { $Credential.Password }
        $sPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ssPass))
        $aPuttyArgs += "-pw"
        $aPuttyArgs += $sPassword
    }
    $aPuttyArgs += $Computer
    &$PuttyPath $aPuttyArgs
}
