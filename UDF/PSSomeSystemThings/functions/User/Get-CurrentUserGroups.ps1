function Get-CurrentUserGroups {
    <#
    .SYNOPSIS
        Get current user groups
    .DESCRIPTION
        Get current user groups. Can also execute this function with $Credential 
    .EXAMPLE
        PS C:\> Get-CurrentUserGroups
        Get current user groups

    .EXAMPLE
        PS C:\> $Cred = Get-Credential
        PS C:\> Get-CurrentUserGroups -Credential $Cred
        Get $Cred user groups

    .PARAMETER $Credential
        Get $Credential user's groups

    .OUTPUTS
        List of groups with SID, type and DOMAIN\GROUPNAME info
        
    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
        Based on: https://jorgequestforknowledge.wordpress.com/2017/06/08/whoami-the-powershell-way/
    #>

    Param(
        [pscredential]$Credential,
        [string]$Filter,
        [switch]$Regex
    )

    $sb = {
        foreach ($item in ([Security.Principal.WindowsIdentity]::GetCurrent()).Claims ) {
            $sGroupName = try {
                ((New-Object System.Security.Principal.SecurityIdentifier($item.Value)).Translate([System.Security.Principal.NTAccount])).Value
            } catch {
                $item.Value
            }
            if ($sGroupName -match "^(.+)\\(.+)$") {
                $sDomain = $Matches.1
                $sShortGroupName = $Matches.2
            } else {
                $sDomain = ""
                $sShortGroupName = $sGroupName
            }
            $sGroupSID = $item.Value
            $sGroupType = $item.Type
            $hGroup = [ordered]@{
                "Domain" = $sDomain
                "Domain Object Name" = $sGroupName
                "Name" = $sShortGroupName
                "SID" = $sGroupSID
                "Type" = $sGroupType
                "Claim" = $item
            }
            New-Object -TypeName PSObject -Property $hGroup
        }
    }

    if ($Credential) {
        $result = Invoke-Command -ScriptBlock $sb -Credential $Credential -ComputerName $env:COMPUTERNAME
        $result = $result | Select-Object -Property * -ExcludeProperty @("RunspaceId", "PSSourceJobInstanceId")
    } else {
        $result = (. $sb)
    }
    if ($Filter) {
        if ($Regex.IsPresent) {
            return $result | Where-Object { $_."Domain Object Name" -match $Filter }
        } else {
            return $result | Where-Object { $_."Domain Object Name" -like $Filter }
        }
    } else {
        return $result
    }
}