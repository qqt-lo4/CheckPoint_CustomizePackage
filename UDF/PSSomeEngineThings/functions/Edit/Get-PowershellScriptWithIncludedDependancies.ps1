function Get-PowershellScriptWithIncludedDependancies {
    <#
    .SYNOPSIS
        Merges a PowerShell script with its dependencies into a single script

    .DESCRIPTION
        Takes a PowerShell script and inline-includes all dot-sourced files and imported modules
        into a single combined script. Useful for creating standalone scripts from modular code.

    .PARAMETER powershellScript
        PowerShell script content as string or array of lines.

    .PARAMETER powershellFile
        Path to a PowerShell script file.

    .PARAMETER newPSScriptRootValue
        New value to use for $PSScriptRoot resolution. Default: current $PSScriptRoot.

    .OUTPUTS
        [String[]]. Array of lines for the combined script with all dependencies included.

    .EXAMPLE
        Get-PowershellScriptWithIncludedDependancies -powershellFile "C:\Scripts\MyScript.ps1"

    .EXAMPLE
        $content = Get-Content "C:\Scripts\MyScript.ps1"
        Get-PowershellScriptWithIncludedDependancies -powershellScript $content -newPSScriptRootValue "C:\Scripts"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, ParameterSetName = "Script")]
        [object]$powershellScript,
        [Parameter(Mandatory, ParameterSetName = "File")]
        [string]$powershellFile,
        [string]$newPSScriptRootValue = ""
    )
    $newScriptContent = @()
    $oldContent = switch ($PSCmdlet.ParameterSetName) {
        "Script" {
            if ($powershellScript -is [string]) {
                $powershellScript -split "`n"
            } elseif ($powershellScript -is [array]) {
                $powershellScript
            }
        }
        "File" {
            Get-Content $powershellFile
        }
    }
    $newRoot = if ($newPSScriptRootValue -eq "") { $PSScriptRoot } else { $newPSScriptRootValue }
    foreach($line in $oldContent) {
        if($line.Trim() -imatch '^\. (\$psscriptroot.*)'){
            $includedFile = $Matches.1 -ireplace '\$PSScriptRoot', $newRoot
            $newScriptContent += $(Get-Content $includedFile)
            $newScriptContent += ""
        }
        elseif($line.Trim() -imatch '^Import-Module\s+"(\$psscriptroot[^"]+)"' -or
               $line.Trim() -imatch '^Import-Module\s+(\$psscriptroot[^\s]+)') {
            $modulePath = $Matches.1 -ireplace '\$PSScriptRoot', $newRoot
            foreach ($ps1File in (Get-ChildItem -Path $modulePath -Filter '*.ps1' -File -Recurse)) {
                $newScriptContent += $(Get-Content $ps1File.FullName)
                $newScriptContent += ""
            }
        } else {
            $newScriptContent += $line
        }
    }
    return $newScriptContent
}