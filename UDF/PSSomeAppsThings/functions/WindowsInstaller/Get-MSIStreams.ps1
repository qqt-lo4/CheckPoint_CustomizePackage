function Get-MSIStreams {
    <#
    .SYNOPSIS
        Lists all streams in an MSI database

    .DESCRIPTION
        Queries the _Streams table of an MSI database to retrieve the names
        of all embedded binary streams (e.g., custom actions, icons, cabs).

    .PARAMETER MSIFile
        MSI file object from Open-MSIFile. Falls back to $global:MSIFile if not provided.

    .OUTPUTS
        System.String[]. Names of all streams in the MSI database.

    .EXAMPLE
        Get-MSIStreams

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
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