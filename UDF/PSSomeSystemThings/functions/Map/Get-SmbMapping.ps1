function Get-SmbMapping {
    <#
    .SYNOPSIS
        Retrieves SMB mappings with persistence information

    .DESCRIPTION
        Wraps the built-in Get-SmbMapping cmdlet and adds a Persistent property indicating
        whether each mapping is configured to reconnect at logon (via HKCU:\Network registry).

    .PARAMETER LocalPath
        Filter by local drive path(s).

    .PARAMETER RemotePath
        Filter by remote UNC path(s).

    .PARAMETER CimSession
        CIM session(s) for remote execution.

    .PARAMETER ThrottleLimit
        Maximum number of concurrent operations.

    .PARAMETER AsJob
        Run as a background job.

    .OUTPUTS
        [PSObject[]]. SMB mapping objects with added Persistent property.

    .EXAMPLE
        Get-SmbMapping

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdletBinding(DefaultParameterSetName='Query (cdxml)', PositionalBinding=$false, HelpUri='http://go.microsoft.com/fwlink/?LinkID=241947')]
    [Alias('gsmbm')]
    [OutputType('SMBShare')]
    #[OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    #[OutputType('Microsoft.Management.Infrastructure.CimInstance#ROOT/Microsoft/Windows/SMB/MSFT_SmbMapping')]

    Param(
        [Parameter(ParameterSetName='Query (cdxml)', Position=1, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [string[]]
        ${LocalPath},

        [Parameter(ParameterSetName='Query (cdxml)', Position=2, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [string[]]
        ${RemotePath},

        [Parameter(ParameterSetName='Query (cdxml)')]
        [Alias('Session')]
        [ValidateNotNullOrEmpty()]
        [CimSession[]]
        ${CimSession},

        [Parameter(ParameterSetName='Query (cdxml)')]
        [int]
        ${ThrottleLimit},

        [Parameter(ParameterSetName='Query (cdxml)')]
        [switch]
        ${AsJob}
    )

    $oResult = SmbShare\Get-SmbMapping @PSBoundParameters
    $persistentMaps = (Get-ChildItem "HKCU:\Network").Name 
    if ($persistentMaps) {
        $persistentMaps = $persistentMaps | ForEach-Object { $_.Split("\")[-1] } | ForEach-Object { $_ + ":"}
    }

    # create a PSPropertySet with the default property names
    [string[]]$visible = 'Status','LocalPath','RemotePath','Persistent'
    [Management.Automation.PSMemberInfo[]]$visibleProperties = [System.Management.Automation.PSPropertySet]::new('DefaultDisplayPropertySet',$visible)
    
    foreach ($share in $oResult) {
        $persistent = ($share.LocalPath -in $persistentMaps)
        $share = $share | Select-Object -Property *
#        $share.PSObject.TypeNames.Insert(0, "SMBShare")
        $share | Add-Member -NotePropertyName "Persistent" -NotePropertyValue $persistent
        $share | Add-Member -MemberType MemberSet -Name PSStandardMembers -Value $visibleProperties -Force
        $share
    }
}