function Get-MSIProperty {
    <#
    .SYNOPSIS
        Gets properties from an MSI database

    .DESCRIPTION
        Queries the Property table of an MSI database to retrieve one or all properties.
        Returns objects with Property and Value columns.

    .PARAMETER MSIFile
        MSI file object from Open-MSIFile. Falls back to $global:MSIFile if not provided.

    .PARAMETER Name
        Optional property name to retrieve. If omitted, returns all properties.

    .OUTPUTS
        PSCustomObject[]. Property/Value pairs from the MSI database.

    .EXAMPLE
        Get-MSIProperty -Name "ProductVersion"

    .EXAMPLE
        Get-MSIProperty | Format-Table

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$MSIFile,
        [Parameter(Position = 0)]
        [string]$Name
    )
    Begin {
        $oMSIFile = if ($MSIFile) {
            $MSIFile
        } elseif ($global:MSIFile) {
            $global:MSIFile
        } else {
            throw [System.ArgumentNullException] "MSI File not opened, please use ""Open-MSIFile"""
        }
    }
    Process {
        $sSQLQuery = if ($Name) {
            "Select * from Property Where Property = '$Name'"
        } else {
            "Select * from Property"
        }
        # Build default properties set for each property
        $defaultProperties = @('Property','Value')
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet',[string[]]$defaultProperties)
        $newLinePSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
        $result = Invoke-MSISQLQuery -MSIFile $oMSIFile -query $sSQLQuery
        $result | Add-Member MemberSet PSStandardMembers $newLinePSStandardMembers
        return $result
    }
}