function Get-Volume {
    <#
    .SYNOPSIS
        Retrieves volume information with remote execution support

    .DESCRIPTION
        Wraps Storage\Get-Volume and adds support for remote execution via
        ComputerName, Credential, or PSSession parameters. Supports filtering
        by drive letter, label, path, unique ID, partition, disk image, and
        various storage objects.

    .PARAMETER DriveLetter
        Filter by drive letter(s).

    .PARAMETER ThrottleLimit
        Maximum number of concurrent operations.

    .PARAMETER AsJob
        Run as a background job.

    .PARAMETER ObjectId
        Filter by object ID(s).

    .PARAMETER UniqueId
        Filter by unique ID(s).

    .PARAMETER Path
        Filter by volume path(s).

    .PARAMETER FileSystemLabel
        Filter by file system label(s).

    .PARAMETER Partition
        Filter by partition object (from pipeline).

    .PARAMETER DiskImage
        Filter by disk image object (from pipeline).

    .PARAMETER StorageSubSystem
        Filter by storage subsystem object (from pipeline).

    .PARAMETER StoragePool
        Filter by storage pool object (from pipeline).

    .PARAMETER StorageNode
        Filter by storage node object (from pipeline).

    .PARAMETER StorageFileServer
        Filter by storage file server object (from pipeline).

    .PARAMETER FileShare
        Filter by file share object (from pipeline).

    .PARAMETER StorageJob
        Filter by storage job object (from pipeline).

    .PARAMETER FilePath
        Filter by file path.

    .PARAMETER ComputerName
        Remote computer name to query.

    .PARAMETER Credential
        Credentials for remote execution.

    .PARAMETER Session
        Existing PSSession for remote execution.

    .OUTPUTS
        [Microsoft.Management.Infrastructure.CimInstance[]]. Volume objects.

    .EXAMPLE
        Get-Volume

    .EXAMPLE
        Get-Volume -DriveLetter C

    .EXAMPLE
        Get-Volume -FileSystemLabel "Data" -ComputerName "SERVER01"

    .NOTES
        Author  : Loïc Ade
        Version : 2.0.0

        Version History:
        1.0.0 - Initial version (Get-LocalVolume, simple wrapper around Get-Volume)
        2.0.0 - Renamed to Get-Volume, added full parameter set support,
                 replaced Invoke-ThisFunctionRemotely with Invoke-Command,
                 added Session/ComputerName conflict check
    #>

    [CmdletBinding(DefaultParameterSetName="ByDriveLetter")]
    Param(
        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = "ByDriveLetter")]
        [ValidateNotNull()]
        [Char[]]$DriveLetter,

        [Parameter(ParameterSetName = "ByFilePath")]
        [Parameter(ParameterSetName = "ByStorageJob")]
        [Parameter(ParameterSetName = "ByFileShare")]
        [Parameter(ParameterSetName = "ByStorageFileServer")]
        [Parameter(ParameterSetName = "ByStorageNode")]
        [Parameter(ParameterSetName = "ByStoragePool")]
        [Parameter(ParameterSetName = "ByStorageSubSystem")]
        [Parameter(ParameterSetName = "ByDiskImage")]
        [Parameter(ParameterSetName = "ByPartition")]
        [Parameter(ParameterSetName = "ByDriveLetter")]
        [Parameter(ParameterSetName = "ByLabel")]
        [Parameter(ParameterSetName = "ByPaths")]
        [Parameter(ParameterSetName = "ByUniqueId")]
        [Parameter(ParameterSetName = "ById")]
        [Int32]$ThrottleLimit,

        [Parameter(ParameterSetName = "ByFilePath")]
        [Parameter(ParameterSetName = "ByStorageJob")]
        [Parameter(ParameterSetName = "ByFileShare")]
        [Parameter(ParameterSetName = "ByStorageFileServer")]
        [Parameter(ParameterSetName = "ByStorageNode")]
        [Parameter(ParameterSetName = "ByStoragePool")]
        [Parameter(ParameterSetName = "ByStorageSubSystem")]
        [Parameter(ParameterSetName = "ByDiskImage")]
        [Parameter(ParameterSetName = "ByPartition")]
        [Parameter(ParameterSetName = "ByDriveLetter")]
        [Parameter(ParameterSetName = "ByLabel")]
        [Parameter(ParameterSetName = "ByPaths")]
        [Parameter(ParameterSetName = "ByUniqueId")]
        [Parameter(ParameterSetName = "ById")]
        [switch]$AsJob,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = "ById")]
        [ValidateNotNull()]
        [Alias("Id")]
        [string[]]$ObjectId,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = "ByUniqueId")]
        [ValidateNotNull()]
        [string[]]$UniqueId,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = "ByPaths")]
        [ValidateNotNull()]
        [string[]]$Path,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = "ByLabel")]
        [ValidateNotNull()]
        [Alias("FriendlyName")]
        [string[]]$FileSystemLabel,

        [Parameter(ValueFromPipeline, ParameterSetName = "ByPartition")]
        [ValidateNotNull()]
        [Microsoft.Management.Infrastructure.CimInstance]$Partition,

        [Parameter(ValueFromPipeline, ParameterSetName = "ByDiskImage")]
        [ValidateNotNull()]
        [Microsoft.Management.Infrastructure.CimInstance]$DiskImage,

        [Parameter(ValueFromPipeline, ParameterSetName = "ByStorageSubSystem")]
        [ValidateNotNull()]
        [Microsoft.Management.Infrastructure.CimInstance]$StorageSubSystem,

        [Parameter(ValueFromPipeline, ParameterSetName = "ByStoragePool")]
        [ValidateNotNull()]
        [Microsoft.Management.Infrastructure.CimInstance]$StoragePool,

        [Parameter(ValueFromPipeline, ParameterSetName = "ByStorageNode")]
        [ValidateNotNull()]
        [Microsoft.Management.Infrastructure.CimInstance]$StorageNode,

        [Parameter(ValueFromPipeline, ParameterSetName = "ByStorageFileServer")]
        [ValidateNotNull()]
        [Microsoft.Management.Infrastructure.CimInstance]$StorageFileServer,

        [Parameter(ValueFromPipeline, ParameterSetName = "ByFileShare")]
        [ValidateNotNull()]
        [Microsoft.Management.Infrastructure.CimInstance]$FileShare,

        [Parameter(ValueFromPipeline, ParameterSetName = "ByStorageJob")]
        [ValidateNotNull()]
        [Microsoft.Management.Infrastructure.CimInstance]$StorageJob,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = "ByFilePath")]
        [ValidateNotNullOrEmpty()]
        [Alias("FullName")]
        [string]$FilePath,

        [string]$ComputerName,
        [pscredential]$Credential,
        [System.Management.Automation.Runspaces.PSSession]$Session
    )
    Begin {
        if ($Session -and $ComputerName) {
            throw "Incompatible arguments : you can't use Session and ComputerName at the same time"
        }
        $oScriptBlock = {
            Param(
                [object]$Params
            )
            Storage\Get-Volume @Params
        }
    }
    Process {
        $hParams = Split-RemoteAndNativeParameters
        $hRemoteParams = $hParams.Remote
        Invoke-Command @hRemoteParams -ScriptBlock $oScriptBlock -ArgumentList $hParams.Native
    }
}

