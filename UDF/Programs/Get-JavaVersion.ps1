function Get-JavaVersion {
    Param(
        [string]$ComputerName,
        [pscredential]$Credential,
        [System.Management.Automation.Runspaces.PSSession]$Session
    )
    $allPrograms = Get-InstalledPrograms @PSBoundParameters
    $jre = $allPrograms | Where-Object { $_.Name -match "^Java [0-9]+ Update [0-9]+ \(64-bit\)$" }
    $jre | ForEach-Object { $_.Version = [version]$_.Version }
    $jre = $jre | Sort-Object -Property Version -Descending
    $jre
}