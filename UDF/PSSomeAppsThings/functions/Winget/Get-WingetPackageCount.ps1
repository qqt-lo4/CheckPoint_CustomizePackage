function Get-WingetPackageCount {
    <#
    .SYNOPSIS
        Gets the total number of packages in the Winget database
    
    .DESCRIPTION
        Counts all packages available in the Winget SQLite database
    
    .PARAMETER DatabasePath
        Path to the SQLite database file
    
    .EXAMPLE
        $catalog = Get-WingetPackageCatalog
        Get-WingetPackageCount -DatabasePath $catalog.DatabasePath

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$DatabasePath
    )
    
    try {
        # # Ensure PSSQLite is available
        # if (-not (Get-Module -Name "PSSQLite")) {
        #     Import-Module PSSQLite -ErrorAction Stop
        # }
        
        # Check if database exists
        if (-not (Test-Path $DatabasePath)) {
            throw "Database file not found: $DatabasePath"
        }
        
        $query = "SELECT COUNT(*) as count FROM manifest;"
        $result = Invoke-SqliteQuery -DataSource $DatabasePath -Query $query
        
        return $result.count
    }
    catch {
        Write-Error "Error counting packages: $_"
        return $null
    }
}