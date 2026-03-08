function Get-InternalDrivesPartitions {
    <#
    .SYNOPSIS
        Retrieves partitions from internal (fixed) disk drives

    .DESCRIPTION
        Lists non-hidden partitions on internal fixed disks. Optionally filters to only
        partitions with assigned drive letters. Includes free space information.

    .PARAMETER ComputerName
        Remote computer name to query.

    .PARAMETER Credential
        Credentials for remote execution.

    .PARAMETER Session
        Existing PSSession for remote execution.

    .PARAMETER PartitionsWithLetters
        If specified, returns only partitions that have an assigned drive letter.

    .OUTPUTS
        [Microsoft.Management.Infrastructure.CimInstance[]]. Partition objects with added Free property.

    .EXAMPLE
        Get-InternalDrivesPartitions

    .EXAMPLE
        Get-InternalDrivesPartitions -PartitionsWithLetters

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    Param(
        [string]$ComputerName,
        [pscredential]$Credential,
        [System.Management.Automation.Runspaces.PSSession]$Session,
        [switch]$PartitionsWithLetters
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
            $internalDrives = Get-CimInstance -Query "SELECT * FROM Win32_DiskDrive WHERE MediaType = `"Fixed hard disk media`""
            $result = Get-Partition | Where-Object { $_.IsHidden -eq $false } | Where-Object { $_.DiskNumber -in ($internalDrives.Index) }
            if ($Params.PartitionsWithLetters) {
                $result = $result | Where-Object { $_.DriveLetter.ToString() -ne "" }
            }
            foreach ($partition in $result) {
                $freespace = (Get-PSDrive -Name $partition.DriveLetter).Free
                $partition | Add-Member -NotePropertyName "Free" -NotePropertyValue $freespace
            }
            return $result
        }
    }
    Process {
        $hParams = Split-RemoteAndNativeParameters
        $hRemoteParams = $hParams.Remote
        Invoke-Command @hRemoteParams -ScriptBlock $oScriptBlock -ArgumentList $hParams.Native
    }
}