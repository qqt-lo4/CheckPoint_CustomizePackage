function Get-WingetPackages {
    <#
    .SYNOPSIS
        Retrieves packages from the Winget database
    
    .DESCRIPTION
        Queries the Winget SQLite database for package information with optional filtering
    
    .PARAMETER DatabasePath
        Path to the SQLite database file (optional if $Global:WingetCatalog is set)
    
    .PARAMETER PackageName
        Filter by package name (supports wildcards with LIKE syntax)
    
    .PARAMETER PackageId
        Filter by exact package ID
    
    .PARAMETER Publisher
        Filter by publisher name (supports wildcards with LIKE syntax)
    
    .PARAMETER RowId
        Filter by specific rowid
    
    .PARAMETER Limit
        Maximum number of results to return (default: 100)
    
    .EXAMPLE
        Get-WingetPackages -Limit 10
    
    .EXAMPLE
        Get-WingetPackages -PackageName "%Microsoft%"
    
    .EXAMPLE
        Get-WingetPackages -PackageId "Microsoft.PowerShell"
        
    .EXAMPLE
        Get-WingetPackages -Publisher "%Microsoft%" -Limit 20
        
    .EXAMPLE
        Get-WingetPackages -RowId 42

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    
    [CmdletBinding(DefaultParameterSetName="All")]
    Param(
        [Parameter(Mandatory=$false)]
        [string]$DatabasePath,
        
        [Parameter(Mandatory=$true, ParameterSetName="ByName")]
        [Alias("Name")]
        [string]$PackageName,
        
        [Parameter(Mandatory=$true, ParameterSetName="ById")]
        [Alias("Id")]
        [string]$PackageId,
        
        [Parameter(Mandatory=$true, ParameterSetName="ByPublisher")]
        [string]$Publisher,
        
        [Parameter(Mandatory=$true, ParameterSetName="ByRowId")]
        [int]$RowId,
        
        [Parameter(Mandatory=$false)]
        [int]$Limit = 100
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
        
        # Build query based on parameter set
        $sqlParameters = @{ limit = $Limit }
        $needsPublisher = $PSCmdlet.ParameterSetName -eq "ByPublisher"
        
        if ($needsPublisher) {
            # Query with publisher JOIN (only when filtering by publisher)
            $query = @"
SELECT p.*, np.norm_publisher as publisher
FROM packages p
LEFT JOIN norm_publishers2 np ON p.rowid = np.package
"@
            $tablePrefix = "p."
        } else {
            # Query without publisher (faster)
            $query = "SELECT * FROM packages"
            $tablePrefix = ""
        }
        
        # Add WHERE clause based on parameter set
        $whereClause = ""
        switch ($PSCmdlet.ParameterSetName) {
            "ByName" {
                $whereClause = " WHERE ${tablePrefix}name LIKE @packageName"
                $sqlParameters['packageName'] = $PackageName
            }
            "ById" {
                $whereClause = " WHERE ${tablePrefix}id = @packageId"
                $sqlParameters['packageId'] = $PackageId
            }
            "ByPublisher" {
                $whereClause = " WHERE np.norm_publisher LIKE @publisher"
                $sqlParameters['publisher'] = $Publisher
            }
            "ByRowId" {
                $whereClause = " WHERE ${tablePrefix}rowid = @rowid"
                $sqlParameters['rowid'] = $RowId
            }
            "All" {
                # No WHERE clause, get all packages
                $whereClause = ""
            }
        }
        
        $query += $whereClause + " LIMIT @limit;"
        
        Write-Verbose "Executing query: $query"
        Write-Verbose "Parameter set: $($PSCmdlet.ParameterSetName)"
        
        $packages = Invoke-SqliteQuery -DataSource $sDatabasePath -Query $query -SqlParameters $sqlParameters
        
        return $packages
    }
    catch {
        Write-Error "Error retrieving packages: $_"
        return $null
    }
}
