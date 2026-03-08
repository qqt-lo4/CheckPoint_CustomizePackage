function Test-PSDrive {
    <#
    .SYNOPSIS
        Tests if a PowerShell drive exists

    .DESCRIPTION
        Verifies the existence of a PowerShell drive with optional filtering by provider and root path.
        Returns true if a matching drive is found, false otherwise.

    .PARAMETER Name
        Name of the PowerShell drive to test.

    .PARAMETER PSProvider
        Optional provider name to filter by (e.g., "FileSystem", "Registry").

    .PARAMETER Root
        Optional root path to filter by.

    .OUTPUTS
        [Boolean]. True if drive exists and matches criteria, false otherwise.

    .EXAMPLE
        Test-PSDrive -Name "C"

    .EXAMPLE
        Test-PSDrive -Name "MyDrive" -PSProvider "FileSystem" -Root "\\server\share"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name,
        [Parameter(Position = 1)]
        [string]$PSProvider,
        [Parameter(Position = 2)]
        [string]$Root
    )

    $oPSdrive = Get-PSDrive -Name $Name -ErrorAction SilentlyContinue
    if ($PSProvider) {
        $oPSdrive = $oPSdrive | Where-Object { $_.Provider.Name -ieq $PSProvider }
    }
    if ($Root) {
        $oPSdrive = $oPSdrive | Where-Object { $_.DisplayRoot -ieq $Root }
    }
    return ($null -ne $oPSdrive)
}