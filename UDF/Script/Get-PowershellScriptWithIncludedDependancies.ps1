function Get-PowershellScriptWithIncludedDependancies {
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
        } else {
            $newScriptContent += $line
        }
    }
    return $newScriptContent
}