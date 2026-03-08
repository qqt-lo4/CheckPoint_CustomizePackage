function Write-ScriptCommentDoc {
    <#
    .SYNOPSIS
        Writes comment documentation to a file

    .DESCRIPTION
        Extracts comment documentation from a named region in a PowerShell script and
        writes it to a destination file.

    .PARAMETER regionName
        Name of the region containing the comments to extract.

    .PARAMETER powershellScript
        PowerShell script content as string or array.

    .PARAMETER powershellFile
        Path to PowerShell script file.

    .PARAMETER destination
        Path to the destination file where comments will be written.

    .OUTPUTS
        None. Writes content to the specified destination file.

    .EXAMPLE
        Write-ScriptCommentDoc -powershellFile "C:\Scripts\MyScript.ps1" -regionName "usage" -destination "C:\Docs\usage.txt"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, ParameterSetName = "Script")]
        [Parameter(Mandatory, ParameterSetName = "File")]
        [string]$regionName,
        [Parameter(Mandatory, ParameterSetName = "Script")]
        [object]$powershellScript,
        [Parameter(Mandatory, ParameterSetName = "File")]
        [string]$powershellFile,
        [Parameter(Mandatory, ParameterSetName = "Script")]
        [Parameter(Mandatory, ParameterSetName = "File")]
        [string]$destination
    )
    $PSBoundParameters.Remove('destination') | Out-Null
    $region = Get-ScriptCommentRegion @PSBoundParameters
    New-Item -Path $destination -Force | Out-Null
    $region | Out-File $destination
}
