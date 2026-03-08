function Get-ScriptInfo {
    <#
    .SYNOPSIS
        Extracts script metadata from the "script info" region

    .DESCRIPTION
        Parses the "script info" region of a PowerShell script to extract metadata
        in key=value format (e.g., #Author=Name, #Version=1.0).

    .PARAMETER powershellScript
        PowerShell script content as string or array.

    .PARAMETER powershellFile
        Path to PowerShell script file.

    .OUTPUTS
        [Hashtable]. Metadata key-value pairs from the script info region.

    .EXAMPLE
        Get-ScriptInfo -powershellFile "C:\Scripts\MyScript.ps1"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, ParameterSetName = "Script")]
        [object]$powershellScript,
        [Parameter(Mandatory, ParameterSetName = "File")]
        [string]$powershellFile
    )
    $strRegion = Get-ScriptRegion @PSBoundParameters -regionName "script info"
    $result = @{}
    foreach ($line in $strRegion) {
        if ($line -match "^#([^=]+)=(.+)$") {
            $result.Add($Matches.1, $Matches.2)
        }
    }
    return $result
}
