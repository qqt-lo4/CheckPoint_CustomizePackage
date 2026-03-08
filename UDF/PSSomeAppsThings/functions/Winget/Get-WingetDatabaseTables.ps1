function Get-WingetDatabaseTables {
    <#
    .SYNOPSIS
        Retrieves the list of tables in the Winget SQLite database
    
    .DESCRIPTION
        Queries the SQLite database to get all available tables
    
    .PARAMETER DatabasePath
        Path to the SQLite database file
    
    .EXAMPLE
        $catalog = Get-WingetPackageCatalog
        Get-WingetDatabaseTables -DatabasePath $catalog.DatabasePath
    
    .EXAMPLE
        Get-WingetDatabaseTables -DatabasePath "C:\temp\winget\index.db"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)]
        [string]$DatabasePath
    )
    
    try {
        # # Ensure PSSQLite is available
        # Import-PSModule -Name PSSQLite
        
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

        if (-not (Test-Path $sDatabasePath)) {
            throw "Database file not found: $sDatabasePath"
        }
        
        # Query for all tables
        $query = "SELECT name, type FROM sqlite_master WHERE type='table' ORDER BY name;"
        $tables = Invoke-SqliteQuery -DataSource $sDatabasePath -Query $query
        
        return $tables
    }
    catch {
        Write-Error "Error retrieving database tables: $_"
        return $null
    }
}