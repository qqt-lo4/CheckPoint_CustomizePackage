function Update-MSIStream {
    <#
    .SYNOPSIS
        Updates or inserts a stream in an MSI database

    .DESCRIPTION
        Adds or replaces a named stream in the _Streams table of an MSI database.
        Uses the Assign modify mode which inserts or updates as needed.
        The database is opened in transact mode and changes are committed automatically.

    .PARAMETER MSIFile
        MSI file object from Open-MSIFile. Falls back to $global:MSIFile if not provided.

    .PARAMETER Name
        Name of the stream entry in the _Streams table

    .PARAMETER InputPath
        Path to the file to embed as a stream

    .EXAMPLE
        Update-MSIStream -Name "Icon.exe" -InputPath "C:\Build\app.ico"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
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
        [__comobject]$View = $oMSIFile.GetDatabase().OpenView("SELECT `Name`,`Data` FROM _Streams");
        $Record = $oMSIFile.GetWIObject().CreateRecord(2)
        $Record.StringData(1) = $Name
        $View.Execute($Record)
        $Record.SetStream(2, $InputPath)
        $view.Modify(([MsiViewModify]::msiViewModifyAssign).Value__, $Record)
        $oMSIFile.Commit()
        if ($View) {
            $View.Close()
            [Runtime.Interopservices.Marshal]::ReleaseComObject($View) | Out-Null
        }
        if ($Record) {
            [Runtime.Interopservices.Marshal]::ReleaseComObject($Record) | Out-Null
        }
    }
}