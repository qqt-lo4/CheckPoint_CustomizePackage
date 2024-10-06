function Get-RootScriptPath {
    Param(
        [switch]$FullPath
    )
    $scriptCallStack = Get-PSCallStack | Where-Object { $_.Command -ne '<ScriptBlock>' } 
    $rootScriptFullPath = $scriptCallStack[-1].InvocationInfo.InvocationName
    $rootScriptName = $scriptCallStack[-1].InvocationInfo.MyCommand.Name
    $sResult = if (($rootScriptFullPath.Length - $rootScriptName.Length) -lt 0) {
        ""
    } else {
        $rootScriptFullPath.Remove($rootScriptFullPath.Length - $rootScriptName.Length)
    }
    if ($FullPath.IsPresent) {
        if ($sResult -eq "") {
            (Resolve-Path -Path ".").Path
        } else {
            (Resolve-Path -Path $sResult).Path
        }
    } else {
        return $sResult
    }
}
