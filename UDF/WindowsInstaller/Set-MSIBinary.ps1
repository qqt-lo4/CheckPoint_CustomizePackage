function Set-MSIBinary {
    Param(
        [object]$MSIFile,
        [Parameter(Mandatory, Position = 0)]
        [string]$Name, 
        [Parameter(Mandatory, Position = 1)]
        [string]$InputPath
    )
    Begin {
        $oMSIFile = if ($MSIFile) {
            $MSIFile
        } elseif ($global:MSIFile) {
            $global:MSIFile
        } else {
            throw [System.ArgumentNullException] "MSI File not opened, please use ""Open-MSIFile"""
        }
        $sInputPath = Resolve-Path -Path $InputPath
        if (-not (Test-Path -Path $sInputPath -PathType Leaf)) {
            throw [System.IO.FileNotFoundException] "Input path not found"
        }
        $oMSIFile.OpenDatabase([MsiOpenDatabaseMode]::msiOpenDatabaseModeTransact)
    }
    Process {
        [__comobject]$View = $oMSIFile.GetDatabase().OpenView("SELECT Data FROM Binary WHERE Name = '" + $Name + "'");
        $View.Execute() | Out-Null
        $Record = $View.Fetch()

        if ($null -ne $Record) {
            $Record.SetStream(1, $InputPath)
            $View.Modify(([MsiViewModify]::msiViewModifyReplace).Value__, $Record)
        } else {
            $View.Close() | Out-Null
            if ($View) {[Runtime.Interopservices.Marshal]::ReleaseComObject($View) | Out-Null}
            if ($Record) {[Runtime.Interopservices.Marshal]::ReleaseComObject($Record) | Out-Null}
            $View = $oMSIFile.GetDatabase().OpenView("SELECT * FROM Binary");
            $Record = $oMSIFile.GetWIObject().CreateRecord(2)
            $Record.StringData(1) = $Name
            $Record.SetStream(2, $InputPath)
            $View.Modify(([MsiViewModify]::msiViewModifyInsert).Value__, $Record)
        }
        $oMSIFile.Commit()
        $View.Close() | Out-Null
        if ($Record) {[Runtime.Interopservices.Marshal]::ReleaseComObject($Record) | Out-Null}
        if ($View) {[Runtime.Interopservices.Marshal]::ReleaseComObject($View) | Out-Null}
    }
}