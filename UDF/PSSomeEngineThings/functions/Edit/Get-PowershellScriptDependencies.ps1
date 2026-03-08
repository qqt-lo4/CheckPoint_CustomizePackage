function Get-PowershellScriptDependencies {
    <#
    .SYNOPSIS
        Extracts dependency paths from a PowerShell script

    .DESCRIPTION
        Parses a PowerShell script file to find dot-sourced scripts and Import-Module statements
        that use $PSScriptRoot. Returns an array of dependency paths.

    .PARAMETER powershellFile
        Path to the PowerShell script file to analyze.

    .PARAMETER replacePSScriptRoot
        If true, replaces $PSScriptRoot with the actual script root path. Default: true.

    .OUTPUTS
        [String[]]. Array of dependency file paths.

    .EXAMPLE
        Get-PowershellScriptDependencies -powershellFile "C:\Scripts\MyScript.ps1"

    .EXAMPLE
        Get-PowershellScriptDependencies -powershellFile "C:\Scripts\MyScript.ps1" -replacePSScriptRoot $false

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory)]
        [string]$powershellFile,
        [bool]$replacePSScriptRoot = $true
    )
    $result = @()
    foreach($line in Get-Content $powershellFile) {
        $stripped_line = $line.Trim()
        if($stripped_line -imatch '^\. (\$psscriptroot.*)'){
            $result += $Matches.1
        }
        elseif($stripped_line -imatch '^Import-Module\s+"(\$psscriptroot[^"]+)"'){
            $result += $Matches.1
        }
        elseif($stripped_line -imatch '^Import-Module\s+(\$psscriptroot[^\s]+)'){
            $result += $Matches.1
        }
    }
    if ($replacePSScriptRoot) {
        $result = $result | ForEach-Object { $_ -ireplace '\$PSScriptRoot', $PSScriptRoot }
    }
    return $result
}
