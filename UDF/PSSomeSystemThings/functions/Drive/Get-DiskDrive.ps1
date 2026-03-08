function Get-DiskDrive {
    <#
    .SYNOPSIS
        Retrieves disk drive information via WMI

    .DESCRIPTION
        Queries Win32_DiskDrive to get disk drive details. Supports local and remote
        execution via ComputerName, Credential, or an existing PSSession.

    .PARAMETER ComputerName
        Remote computer name to query.

    .PARAMETER Credential
        Credentials for remote execution.

    .PARAMETER Session
        Existing PSSession for remote execution.

    .PARAMETER MediaType
        Filter by media type: "Fixed hard disk media" or "External hard disk media".

    .OUTPUTS
        [CimInstance[]]. Win32_DiskDrive objects.

    .EXAMPLE
        Get-DiskDrive
        Returns all local disk drives.

    .EXAMPLE
        Get-DiskDrive -MediaType "Fixed hard disk media"
        Returns only fixed (internal) disk drives.

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    Param(
        [string]$ComputerName,
        [pscredential]$Credential,
        [System.Management.Automation.Runspaces.PSSession]$Session,
        [AllowEmptyString()]
        [ValidateSet("Fixed hard disk media", "External hard disk media", "")]
        [string]$MediaType = ""
    )
    Begin {
        if ($Session -and $ComputerName) {
            throw "Incompatible arguments : you can't use Session and ComputerName at the same time"
        }
        $oScriptBlock = {
            Param(
                [Parameter(Mandatory)]
                [object]$Params
            )
            $query = "SELECT * FROM Win32_DiskDrive"
            if ($Params.MediaType) {
                $query = $query + " WHERE MediaType = `"$($Params.MediaType)`""
            }
            return Get-CimInstance -Query $query    
        }
    }
    Process {
        $hParams = Split-RemoteAndNativeParameters
        $hRemoteParams = $hParams.Remote
        Invoke-Command @hRemoteParams -ScriptBlock $oScriptBlock -ArgumentList $hParams.Native
    }
}