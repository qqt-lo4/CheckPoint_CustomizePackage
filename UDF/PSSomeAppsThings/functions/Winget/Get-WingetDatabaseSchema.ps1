function Get-WingetDatabaseSchema {
    <#
    .SYNOPSIS
        Retrieves the schema for a specific table in the Winget database
    
    .DESCRIPTION
        Gets the column definitions for a table in the SQLite database
    
    .PARAMETER DatabasePath
        Path to the SQLite database file
    
    .PARAMETER TableName
        Name of the table to inspect
    
    .EXAMPLE
        $catalog = Get-WingetPackageCatalog
        Get-WingetDatabaseSchema -DatabasePath $catalog.DatabasePath -TableName "manifest"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)]
        [string]$DatabasePath,
        
        [Parameter(Mandatory=$true, Position = 0)]
        [string]$TableName
    )
    
    try {
        ## Ensure PSSQLite is available
        #Import-InstalledModule -Name PSSQLite
        
        # Check if database exists
        $sDatabasePath = if ([string]::IsNullOrEmpty($DatabasePath)) {
            if ($Global:WingetCatalog) {
                $Global:WingetCatalog.DatabasePath
            } else {
                throw "No database given"
            }
        } else {
            $DatabasePath
        }
        
        # Query table schema
        $query = "PRAGMA table_info($TableName);"
        $schema = Invoke-SqliteQuery -DataSource $sDatabasePath -Query $query
        
        return $schema
    }
    catch {
        Write-Error "Error retrieving table schema: $_"
        return $null
    }
}
