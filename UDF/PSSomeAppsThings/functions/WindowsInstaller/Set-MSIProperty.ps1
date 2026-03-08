function Set-MSIProperty {
    <#
    .SYNOPSIS
        Sets a property value in an MSI database

    .DESCRIPTION
        Updates an existing property or inserts a new one in the Property table
        of an MSI database. The database is opened in transact mode.

    .PARAMETER MSIFile
        MSI file object from Open-MSIFile. Falls back to $global:MSIFile if not provided.

    .PARAMETER Name
        The property name to set

    .PARAMETER Value
        The value to assign to the property

    .EXAMPLE
        Set-MSIProperty -Name "ALLUSERS" -Value "1"

    .EXAMPLE
        Set-MSIProperty -Name "ProductVersion" -Value "2.0.0"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
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
