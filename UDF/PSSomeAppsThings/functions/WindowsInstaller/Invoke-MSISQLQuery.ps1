function Invoke-MSISQLQuery {
    <#
    .SYNOPSIS
        Executes a SQL query against an MSI database

    .DESCRIPTION
        Runs a SQL query on an MSI database using the Windows Installer COM API.
        Automatically resolves column headers from the _Columns metadata table
        and returns results as PSCustomObjects. Supports full SELECT syntax or
        simple table name input.

    .PARAMETER MSIFile
        MSI file object from Open-MSIFile. Falls back to $global:MSIFile if not provided.

    .PARAMETER query
        SQL query string or table name. If a table name is provided, it is expanded
        to "SELECT * FROM <table>".

    .OUTPUTS
        PSCustomObject[]. Query result rows with named properties.

    .EXAMPLE
        Invoke-MSISQLQuery -query "SELECT * FROM Property WHERE Property = 'ProductVersion'"

    .EXAMPLE
        Invoke-MSISQLQuery -query "File"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
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