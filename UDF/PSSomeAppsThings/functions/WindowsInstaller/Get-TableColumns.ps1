function Get-TableColumns {
    <#
    .SYNOPSIS
        Gets column definitions from an MSI database table

    .DESCRIPTION
        Queries the _Columns metadata table of an MSI database to retrieve
        column information (Table, Number, Name, Type) for a specific table or all tables.

    .PARAMETER MSIFile
        MSI file object from Open-MSIFile. Falls back to $global:MSIFile if not provided.

    .PARAMETER Table
        Optional table name to filter columns for. If omitted, returns columns for all tables.

    .OUTPUTS
        PSCustomObject[]. Column definitions with Table, Number, Name, and Type properties.

    .EXAMPLE
        Get-TableColumns -Table "Property"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$MSIFile,
        [Parameter(Position = 0)]
        [string]$Table
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
        $oMSIFile.OpenDatabase([MsiOpenDatabaseMode]::msiOpenDatabaseModeReadOnly)
        $sSQLQuery = "SELECT * FROM ``_Columns``"
        if ($Table) {
            $sSQLQuery += " WHERE ``Table`` = '$($Table)'"
        }
        $_ColumnsView = $oMSIFile.Database.OpenView($sSQLQuery);
        if ($_ColumnsView) {
            # Execute the View object
            $_ColumnsView.Execute()
            # Place the objects in a PSObject
            $_Columns = @()
            $_ColumnsRow = $_ColumnsView.Fetch()
            while($null -ne $_ColumnsRow) {
                $hash = @{
                    'Table' = $_ColumnsRow.StringData(1) #Get-ObjectProperty -InputObject $_ColumnsRow -PropertyName 'StringData' -ArgumentList @(1)
                    'Number' = $_ColumnsRow.StringData(2)
                    'Name' = $_ColumnsRow.StringData(3)
                    'Type' = $_ColumnsRow.StringData(4)
                }
                $_Columns += New-Object -TypeName PSObject -Property $hash
                
                $_ColumnsRow = $_ColumnsView.Fetch()
            }
            $result = $_Columns #| Select-Object -ExpandProperty Name
            [Runtime.Interopservices.Marshal]::ReleaseComObject($_ColumnsView) | Out-Null
            return $result
        } else {
            return $null
        }
    }
}