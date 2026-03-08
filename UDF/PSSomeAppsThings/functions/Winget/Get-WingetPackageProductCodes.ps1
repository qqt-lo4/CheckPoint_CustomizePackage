function Get-WingetPackageProductCodes {
    <#
    .SYNOPSIS
        Retrieves product codes for a Winget package

    .DESCRIPTION
        Queries the Winget SQLite database to get all product codes associated with a specific package

    .PARAMETER PackageId
        The exact package ID to retrieve product codes for

    .PARAMETER DatabasePath
        Path to the SQLite database file (optional if $Global:WingetCatalog is set)

    .EXAMPLE
        Get-WingetPackageProductCodes -PackageId "Microsoft.PowerShell"

    .EXAMPLE
        Get-WingetPackageProductCodes -PackageId "7zip.7zip" -DatabasePath "C:\path\to\index.db"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [Alias("Id")]
        [string]$PackageId,

        [Parameter(Mandatory=$false)]
        [string]$DatabasePath
    )

    try {
        # # Ensure PSSQLite is available
        # Import-PSModule -Name PSSQLite

        # Get the package using Get-WingetPackages
        Write-Verbose "Retrieving package: $PackageId"
        $package = if ([string]::IsNullOrEmpty($DatabasePath)) {
            Get-WingetPackages -PackageId $PackageId -Limit 1
        } else {
            Get-WingetPackages -PackageId $PackageId -DatabasePath $DatabasePath -Limit 1
        }

        if (-not $package) {
            Write-Warning "Package not found: $PackageId"
            return $null
        }

        # Get database path
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

        # Query productcodes2 table based on package rowid
        $query = @"
SELECT productcode
FROM productcodes2
WHERE package = @packageRowId
ORDER BY productcode;
"@

        $sqlParameters = @{ packageRowId = $package.rowid }

        Write-Verbose "Executing query: $query"
        Write-Verbose "Package RowId: $($package.rowid)"

        $productCodes = Invoke-SqliteQuery -DataSource $sDatabasePath -Query $query -SqlParameters $sqlParameters

        if ($productCodes) {
            Write-Verbose "Found $($productCodes.Count) product code(s)"
            return $productCodes.productcode
        } else {
            Write-Verbose "No product codes found for package: $PackageId"
            return @()
        }
    }
    catch {
        Write-Error "Error retrieving product codes: $_"
        return $null
    }
}
