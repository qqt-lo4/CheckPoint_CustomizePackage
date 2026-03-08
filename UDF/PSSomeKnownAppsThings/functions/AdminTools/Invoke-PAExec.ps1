function Invoke-PAExec {
    <#
    .SYNOPSIS
        Runs a command on a remote computer using PAExec

    .DESCRIPTION
        Executes a remote command via PAExec (PsExec alternative). Supports
        authentication via username/password or PSCredential, and can run
        as SYSTEM with the -System switch.

    .PARAMETER Computer
        The remote computer name or IP address.

    .PARAMETER paexecpath
        Path to the PAExec executable. Defaults to Search-PAExecPath result.

    .PARAMETER Application
        The application to run on the remote computer.

    .PARAMETER Arguments
        Arguments to pass to the remote application.

    .PARAMETER System
        Run the remote command as SYSTEM.

    .PARAMETER Username
        Username for authentication.

    .PARAMETER Password
        SecureString password for authentication.

    .PARAMETER Credential
        PSCredential for authentication (alternative to Username/Password).

    .EXAMPLE
        Invoke-PAExec -Computer "SERVER01" -Application "cmd.exe" -Arguments "/c ipconfig" -Credential $cred

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdletBinding(DefaultParameterSetName = "cmd")]
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Computer,
        [string]$paexecpath = (Search-PAExecPath),
        [string]$Application,
        [string[]]$Arguments,
        [switch]$System,
        [string]$Username,
        [securestring]$Password,
        [pscredential]$Credential
    )
    $sUser, $sPasswd = if ($Credential) {
        $Credential.UserName
        [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password))
    } else {
        $Username
        [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
    }
    $aArgs = @()
    $aArgs += "\\$Computer"
    if ($Username -or $Credential) {
        $aArgs += "-u"
        $aArgs += if ($Username) { $Username } else { $Credential.UserName }
    }
    if ($Password -or $Credential) {
        $aArgs += "-p"
        $aArgs += if ($Password) {
            [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)) 
        } else {
            [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password))
        }
    }
    if ($System) {
        $aArgs += "-s"
    }
    #$aArgs += "-accepteula"
    $aArgs += $Application
    if ($Arguments) {
        $aArgs += $Arguments
    }
    Start-Process -Wait -FilePath $paexecpath -ArgumentList $aArgs -NoNewWindow | Out-Null
}