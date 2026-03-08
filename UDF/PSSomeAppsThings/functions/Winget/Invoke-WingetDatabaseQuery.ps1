function Invoke-WingetDatabaseQuery {
    <#
    .SYNOPSIS
        Executes a custom SQL query on the Winget database
    
    .DESCRIPTION
        Allows execution of custom SQL queries on the Winget SQLite database
    
    .PARAMETER DatabasePath
        Path to the SQLite database file
    
    .PARAMETER Query
        SQL query to execute
    
    .EXAMPLE
        $catalog = Get-WingetPackageCatalog
        Invoke-WingetDatabaseQuery -DatabasePath $catalog.DatabasePath -Query "SELECT DISTINCT publisher FROM manifest LIMIT 20;"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)]
        [string]$DatabasePath,
        
        [Parameter(Mandatory=$true, Position = 0)]
        [string]$Query
    )
    
    try {
        # # Ensure PSSQLite is available
        # Import-InstalledModule -Name PSSQLite
        
        # Check if database exists
        $sDatabasePath = if ([string]::IsNullOrEmpty($DatabasePath)) {
            if ($Global:WingetCatalog) {
                $Global:WingetCatalog.DatabasePath
            } else {
                throw "No database path provided and `$Global:WingetCatalog is not set. Run Get-WingetPackageCatalog first."
            }
        } else {
            $DatabasePath
        }
        
        if (-not (Test-Path $sDatabasePath)) {
            throw "Database file not found: $sDatabasePath"
        }
        
        Write-Verbose "Executing query: $Query"
        
        $results = Invoke-SqliteQuery -DataSource $sDatabasePath -Query $Query
        
        return $results
    }
    catch {
        Write-Error "Error executing query: $_"
        return $null
    }
}
