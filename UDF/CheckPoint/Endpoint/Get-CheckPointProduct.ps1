function Get-CheckPointProduct {
    Param(
        [Microsoft.Win32.RegistryKey]$regkey = $(Get-CheckPointRegKey)
    )
    if ($regkey -and ($regkey -isnot [array])) {
        $regkey.GetValue("DisplayName")
    } else {
        return ""
    }
}