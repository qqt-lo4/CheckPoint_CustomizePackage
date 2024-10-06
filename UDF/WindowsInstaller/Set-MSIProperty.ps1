function Set-MSIProperty {
    Param(
        [object]$MSIFile,
        [Parameter(Mandatory, Position = 0)]
        [string]$Name, 
        [Parameter(Mandatory, Position = 1)]
        [string]$Value
    )
    Begin {
        $oMSIFile = if ($MSIFile) {
            $MSIFile
        } elseif ($global:MSIFile) {
            $global:MSIFile
        } else {
            throw [System.ArgumentNullException] "MSI File not opened, please use ""Open-MSIFile"""
        }
        $oMSIFile.OpenDatabase([MsiOpenDatabaseMode]::msiOpenDatabaseModeTransact)
    }
    Process {
        try {
            ## Open the requested table view from the database
            [__comobject]$View = $oMSIFile.GetDatabase().OpenView("SELECT * FROM Property WHERE Property='$Name'");
            $View.Execute() | Out-Null
    
            ## Retrieve the requested property from the requested table.
            #  https://msdn.microsoft.com/en-us/library/windows/desktop/aa371136(v=vs.85).aspx
            $Record = $View.Fetch()
    
            ## Close the previous view on the MSI database
            $View.Close() | Out-Null
            if ($View) {[Runtime.Interopservices.Marshal]::ReleaseComObject($View) | Out-Null}
    
            ## Set the MSI property
            if ($Record) {
                #  If the property already exists, then create the view for updating the property
                [__comobject]$View = $oMSIFile.GetDatabase().OpenView("UPDATE Property SET Value='$Value' WHERE Property='$Name'")
            } else {
                #  If property does not exist, then create view for inserting the property
                [__comobject]$View = $oMSIFile.GetDatabase().OpenView("INSERT INTO Property (Property, Value) VALUES ('$Name','$Value')")
            }
            #  Execute the view to set the MSI property
            $View.Execute()
        } Catch {
            Throw "Failed to set the MSI Property Name [$Name] with Property Value [$Value]: $($_.Exception.Message)"
        } Finally {
            Try {
                If ($View) {
                    $View.Close()
                    [Runtime.Interopservices.Marshal]::ReleaseComObject($View) | Out-Null
                }
            }
            Catch { }
        }
    }
}
