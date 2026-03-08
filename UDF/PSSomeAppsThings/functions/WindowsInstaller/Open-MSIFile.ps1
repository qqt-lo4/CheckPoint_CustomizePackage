enum MsiOpenDatabaseMode {
    msiOpenDatabaseModeReadOnly = 0
    msiOpenDatabaseModeTransact = 1
    msiOpenDatabaseModeDirect = 2
    msiOpenDatabaseModeCreate = 3
    msiOpenDatabaseModeCreateDirect = 4
    msiOpenDatabaseModePatchFile = 32 # 0x00000020
}

enum MsiViewModify {
    msiViewModifySeek = -1 # 0xFFFFFFFF
    msiViewModifyRefresh = 0
    msiViewModifyInsert = 1
    msiViewModifyUpdate = 2
    msiViewModifyAssign = 3
    msiViewModifyReplace = 4
    msiViewModifyMerge = 5
    msiViewModifyDelete = 6
    msiViewModifyInsertTemporary = 7
    msiViewModifyValidate = 8
    msiViewModifyValidateNew = 9
    msiViewModifyValidateField = 10 # 0x0000000A
    msiViewModifyValidateDelete = 11 # 0x0000000B
}

function Open-MSIFile {
    <#
    .SYNOPSIS
        Opens an MSI file for database operations

    .DESCRIPTION
        Creates a WindowsInstaller COM wrapper object for the specified MSI file.
        The returned object provides methods to open the database in various modes,
        execute queries, and commit changes. Can optionally store the object in a
        global variable for use by other MSI functions.

    .PARAMETER Path
        Path to the MSI file to open

    .PARAMETER GlobalVar
        If specified, stores the MSI object in $global:MSIFile for use by other
        MSI functions without explicitly passing the object.

    .OUTPUTS
        WindowsInstaller. A COM wrapper object with OpenDatabase(), GetDatabase(),
        Commit(), and GetWIObject() methods.

    .EXAMPLE
        $msi = Open-MSIFile "C:\Temp\Setup.msi"

    .EXAMPLE
        Open-MSIFile "C:\Temp\Setup.msi" -GlobalVar
        Get-MSIProperty -Name "ProductVersion"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,
        [switch]$GlobalVar
    )
    Begin {
        $sPath = Resolve-Path $Path
        if (-not (Test-Path -Path $sPath -PathType Leaf)) {
            throw [System.IO.FileNotFoundException] "MSI path file not found"
        }
        class WindowsInstaller {
            hidden [object] $WIComObject
            hidden [string] $File
            hidden [object] $Database 
            hidden [MsiOpenDatabaseMode] $OpenMode
        
            WindowsInstaller([string]$File) {
                $this.File = $File
                $this.WIComObject = New-Object -ComObject WindowsInstaller.Installer
            }
        
            [void] Commit() {
                if ($this.Database) {
                    $this.Database.Commit()
                    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($this.Database) | Out-Null
                    $this.Database = $null
                }
            }
        
            [object] GetDatabase() {
                return $this.Database
            }
        
            [void] OpenDatabase([MsiOpenDatabaseMode]$OpenMode) {
                if ($null -eq $this.Database) {
                    $this.Database = $this.WIComObject.OpenDatabase($this.File, $OpenMode.Value__)
                    $this.OpenMode = $OpenMode
                } else {
                    if ($this.OpenMode -ne $OpenMode) {
                        $this.commit()
                        $this.Database = $this.WIComObject.OpenDatabase($this.File, $OpenMode.Value__)
                        $this.OpenMode = $OpenMode
                    }
                }
            }

            [object] GetWIObject() {
                return $this.WIComObject
            }
        }
    }
    Process {
        $oResult = New-Object -TypeName WindowsInstaller -ArgumentList $sPath
        if ($GlobalVar.IsPresent) {
            $global:MSIFile = $oResult
        } else {
            return $oResult
        }
    }
}
