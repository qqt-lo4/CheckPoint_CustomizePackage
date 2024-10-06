function Disconnect-CheckPointVPN {
    Param(
        [string]$tracexe = $(Get-CheckPointTracExe)
    )

    if (Test-Path -Path $tracexe -PathType Leaf) {
        $sResult = $(& $tracexe "disconnect")
        $bSuccess = $sResult[-1] -eq "Connection was successfully disconnected"
        return New-Object PSObject -Property @{
            "Success" = $bSuccess
            "CommandResult" = $sResult
        }
    } else {
        throw [System.IO.FileNotFoundException] "trac.exe file does not exists"
    }
}