function Get-CheckPointTracExe {
    Param(
        [Microsoft.Win32.RegistryKey]$regkey = $(Get-CheckPointRegKey)
    )
    return $(Get-CheckPointFile -regkey $regkey -filename "trac.exe")
}