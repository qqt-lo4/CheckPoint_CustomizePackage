function Get-MSIBinary {
    Param(
        [object]$MSIFile,
        [Parameter(Mandatory, Position = 0)]
        [string]$Name, 
        [Parameter(Mandatory, Position = 1)]
        [string]$OutputPath
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
        $msiReadStreamBytes = 1
        $ViewBinary = $oMSIFile.GetDatabase().OpenView("SELECT Name, Data FROM _Streams WHERE Name = '$Name'")
        $ViewBinary.Execute() | Out-Null
        $Binary = $ViewBinary.Fetch()
        if ($Binary) {
            $DataSize = $Binary.DataSize(2)
            $BinaryData = $Binary.ReadStream(2, $DataSize, $msiReadStreamBytes)
            [IO.File]::WriteAllBytes($OutputPath, $BinaryData.ToCharArray())
            [Runtime.Interopservices.Marshal]::ReleaseComObject($Binary) | Out-Null
        }
        $ViewBinary.Close() | Out-Null
        [Runtime.Interopservices.Marshal]::ReleaseComObject($ViewBinary) | Out-Null
        $oMSIFile.Commit()
    }
}