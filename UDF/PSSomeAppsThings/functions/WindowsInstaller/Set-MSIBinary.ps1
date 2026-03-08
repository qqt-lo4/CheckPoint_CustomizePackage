function Set-MSIBinary {
    <#
    .SYNOPSIS
        Sets or inserts a binary stream in an MSI database

    .DESCRIPTION
        Replaces an existing binary entry in the Binary table of an MSI database,
        or inserts a new one if the name does not exist. The MSI file is opened
        in transact mode and changes are committed automatically.

    .PARAMETER MSIFile
        MSI file object from Open-MSIFile. Falls back to $global:MSIFile if not provided.

    .PARAMETER Name
        Name of the binary entry in the Binary table

    .PARAMETER InputPath
        Path to the file to embed as a binary stream

    .EXAMPLE
        Set-MSIBinary -Name "CustomAction.dll" -InputPath "C:\Build\CustomAction.dll"

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