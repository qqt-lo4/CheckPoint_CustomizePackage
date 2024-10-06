function Get-MSIProperty {
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