function Get-MSIStreams {
    Param(
        [object]$MSIFile 
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
        $oMSIFile.openDatabase([MsiOpenDatabaseMode]::msiOpenDatabaseModeReadOnly)
        $TableView = $oMSIFile.GetDatabase().OpenView("SELECT Name FROM _Streams");
        # Execute the View object
        $TableView.Execute() | Out-Null
        # Place the objects in a PSObject
        $Rows = @()
        # Fetch the first record
        $Row = $TableView.Fetch()
        while($null -ne $Row) {
            $Rows += $row.StringData(1)
            # Fetch the next record
            $Row = $TableView.Fetch()
        }
        if ($TableView) {
            $TableView.Close() | Out-Null
            [Runtime.Interopservices.Marshal]::ReleaseComObject($TableView) | Out-Null
        }
        if ($Row) {[Runtime.Interopservices.Marshal]::ReleaseComObject($Row) | Out-Null}
        return $Rows
    }
}