function Search-WingetPackages {
    <#
    .SYNOPSIS
        Searches for packages in the Winget database
    
    .DESCRIPTION
        Performs a flexible search across name, id, moniker, and optionally publisher fields in the Winget database
    
    .PARAMETER SearchTerm
        Term to search for (searches in name, id, moniker, and optionally publisher fields)
    
    .PARAMETER DatabasePath
        Path to the SQLite database file (optional if $Global:WingetCatalog is set)
    
    .PARAMETER IncludePublisher
        If specified, includes publisher information and searches in publisher field (slower)
    
    .PARAMETER Limit
        Maximum number of results to return (default: 50)
    
    .EXAMPLE
        Search-WingetPackages "Visual Studio"
    
    .EXAMPLE
        Search-WingetPackages "Microsoft" -Limit 10
    
    .EXAMPLE
        Search-WingetPackages "Adobe" -IncludePublisher

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$SearchTerm,
        
        [Parameter(Mandatory=$false)]
        [string]$DatabasePath,
        
        [Parameter(Mandatory=$false)]
        [switch]$IncludePublisher,
        
        [Parameter(Mandatory=$false)]
        [int]$Limit = 50
    )
    
    try {
        # # Ensure PSSQLite is available
        # Import-PSModule -Name PSSQLite
        
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
        
        # Build query based on IncludePublisher flag
        if ($IncludePublisher) {
            # Slower query with publisher JOIN and search
            $query = @"
SELECT p.*, np.norm_publisher as publisher
FROM packages p
LEFT JOIN norm_publishers2 np ON p.rowid = np.package
WHERE p.name LIKE @searchPattern
   OR p.id LIKE @searchPattern
   OR p.moniker LIKE @searchPattern
   OR np.norm_publisher LIKE @searchPattern
LIMIT @limit;
"@
        } else {
            # Faster query without publisher
            $query = @"
SELECT * FROM packages
WHERE name LIKE @searchPattern
   OR id LIKE @searchPattern
   OR moniker LIKE @searchPattern
LIMIT @limit;
"@
        }
        
        # Create parameter hashtable
        $sqlParameters = @{
            searchPattern = "%$SearchTerm%"
            limit = $Limit
        }
        
        Write-Verbose "Executing search query with parameters: SearchTerm='%$SearchTerm%', Limit=$Limit, IncludePublisher=$IncludePublisher"
        
        $results = Invoke-SqliteQuery -DataSource $sDatabasePath -Query $query -SqlParameters $sqlParameters
        
        return $results
    }
    catch {
        Write-Error "Error searching packages: $_"
        return $null
    }
}