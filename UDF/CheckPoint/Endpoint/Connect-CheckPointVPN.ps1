function Connect-CheckPointVPN {
    Param(
        [string]$tracexe = $(Get-CheckPointTracExe),

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SiteName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Password
    )

    if (Test-Path -Path $tracexe -PathType Leaf) {
        $sResult = $(& $tracexe "connect" "-s" $sitename "-u" $Username "-p" $Password)
        $bSuccess = $sResult[-1] -eq "Connection was successfully established"
        return New-Object PSObject -Property @{
            "Success" = $bSuccess
            "CommandResult" = $sResult
        }
    } else {
        throw [System.IO.FileNotFoundException] "trac.exe file does not exists"
    }
}