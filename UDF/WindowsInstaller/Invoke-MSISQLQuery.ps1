function Invoke-MSISQLQuery {
    Param(
        [object]$MSIFile,
        [Parameter(Mandatory, Position = 0)]
        [string]$query
    )
    Begin {
        $oMSIFile = if ($MSIFile) {
            $MSIFile
        } elseif ($global:MSIFile) {
            $global:MSIFile
        } else {
            throw [System.ArgumentNullException] "MSI File not opened, please use ""Open-MSIFile"""
        }
        $oMSIFile.OpenDatabase([MsiOpenDatabaseMode]::msiOpenDatabaseModeReadOnly)

        # Get main query
        $sql, $table = if ($query -imatch "^select (?<columns>.+) from (?<table>[a-zA-Z0-9]+)( (?<where>where .+))?") {
            $query, $Matches.table
        } else {
            "SELECT * FROM $query", $query
        }

        # Get Columns headers
        $sSQLQueryColumns = "SELECT * FROM ``_Columns``"
        if ($table) {
            $sSQLQueryColumns += " WHERE ``Table`` = '$($table)'"
        }
        $_ColumnsView = $oMSIFile.Database.OpenView($sSQLQueryColumns);
        $headers = @()
        if ($_ColumnsView) {
            # Execute the View object
            $_ColumnsView.Execute() | Out-Null
            # Place the objects in a PSObject
            $_ColumnsRow = $_ColumnsView.Fetch()
            while($null -ne $_ColumnsRow) {
                $hash = @{
                    'Table' = $_ColumnsRow.StringData(1) #Get-ObjectProperty -InputObject $_ColumnsRow -PropertyName 'StringData' -ArgumentList @(1)
                    'Number' = $_ColumnsRow.StringData(2)
                    'Name' = $_ColumnsRow.StringData(3)
                    'Type' = $_ColumnsRow.StringData(4)
                }
                $headers += New-Object -TypeName PSObject -Property $hash
                
                $_ColumnsRow = $_ColumnsView.Fetch()
            }
            #$headers = $_Columns #| Select-Object -ExpandProperty Name
            [Runtime.Interopservices.Marshal]::ReleaseComObject($_ColumnsView) | Out-Null
        }
    }
    Process {
        if ($headers) {
            $TableView = $oMSIFile.GetDatabase().OpenView($sql);
            # Execute the View object
            $TableView.Execute() | Out-Null
            # Place the objects in a PSObject
            $Rows = @()
            # Fetch the first record
            $Row = $TableView.Fetch()
            while($null -ne $Row) {
                $hash = @{}
                foreach ($header in $headers) {
                    $fieldName = $header.Name
                    $hashValue = $row.StringData([int]$header.Number)
                    $hash.Add($fieldName, $hashValue)
                }
                $oNewLine = New-Object -TypeName PSObject -Property $hash
                $Rows += $oNewLine
                
                # Fetch the next record
                $Row = $TableView.Fetch()
            }
            if ($TableView) {[Runtime.Interopservices.Marshal]::ReleaseComObject($TableView) | Out-Null}
            if ($Row) {[Runtime.Interopservices.Marshal]::ReleaseComObject($Row) | Out-Null}
            return $Rows
        } else {
            return $null
        }
    }
}