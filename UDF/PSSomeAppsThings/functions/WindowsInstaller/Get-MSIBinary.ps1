function Get-MSIBinary {
    <#
    .SYNOPSIS
        Extracts a binary stream from an MSI file

    .DESCRIPTION
        Reads a named binary stream from the _Streams table of an MSI database
        and writes it to a file on disk.

    .PARAMETER MSIFile
        MSI file object from Open-MSIFile. Falls back to $global:MSIFile if not provided.

    .PARAMETER Name
        Name of the binary stream to extract

    .PARAMETER OutputPath
        File path where the binary data will be written

    .EXAMPLE
        Get-MSIBinary -Name "CustomAction.dll" -OutputPath "C:\Temp\CustomAction.dll"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
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