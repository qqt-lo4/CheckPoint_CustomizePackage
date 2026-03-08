function Test-IsCurrentUserLocalAdmin {
    <#
    .SYNOPSIS
        Tests if the current user is a member of the local Administrators group

    .DESCRIPTION
        Uses Get-CurrentUserGroups to check if the current user's claims include
        the well-known Administrators group SID (S-1-5-32-544).

    .OUTPUTS
        [bool]. $true if the user is a local administrator, $false otherwise.

    .EXAMPLE
        Test-IsCurrentUserLocalAdmin

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    $oLocalAdminGroup = Get-CurrentUserGroups | Where-Object { $_.SID -eq "S-1-5-32-544"}
    return $oLocalAdminGroup -ne $null
}