function Get-PowershellScriptDependencies {
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
    }
    if ($replacePSScriptRoot) {
        $result = $result | ForEach-Object { $_ -ireplace '\$PSScriptRoot', $PSScriptRoot }
    }
    return $result
}
