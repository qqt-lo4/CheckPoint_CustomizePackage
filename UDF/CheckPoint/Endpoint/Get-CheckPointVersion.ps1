function Get-CheckPointVersion {
    Param(
        [Microsoft.Win32.RegistryKey]$regkey = $(Get-CheckPointRegKey)
    )
    if ($regkey -and ($regkey -isnot [array])) {
        $regkey.GetValue("DisplayVersion")
    } else {
        return ""
    }
}