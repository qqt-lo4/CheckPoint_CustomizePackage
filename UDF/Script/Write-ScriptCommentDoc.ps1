function Write-ScriptCommentDoc {
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
