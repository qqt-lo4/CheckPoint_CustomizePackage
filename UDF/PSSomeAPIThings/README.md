# PSSomeAPIThings

A PowerShell module for API communication and URL management: GraphQL queries, JSON serialization, SSL handling, and URL parsing/building utilities.

## Features

### GraphQL (2 functions)

| Function | Description |
|----------|-------------|
| `Invoke-GraphQLQuery` | Lightweight GraphQL client with variables, headers, sessions, SSL bypass, and automatic error handling |

### URL (8 functions)

| Function | Description |
|----------|-------------|
| `Convert-HashtableToURLArguments` | Converts a hashtable to a URL-encoded query string |
| `Convert-UrlToObject` | Parses a URL string into a structured object with decoded query parameters |
| `ConvertTo-URL` | Builds a complete URL from a base URL and query parameters hashtable |
| `ConvertTo-URLArguments` | Converts a hashtable to a URL-encoded query string with nested hashtable and boolean support |
| `Get-DomainFromHostname` | Extracts the domain name from a hostname |
| `Get-URLDomain` | Extracts the top-level domain from a URL or hostname |
| `Get-URLObject` | Parses a URL into its components including decoded query parameters |
| `Get-URLtld` | Extracts the top-level domain (TLD) from a URL or hostname |

### Other (3 functions)

| Function | Description |
|----------|-------------|
| `ConvertTo-JsonRecursive` | Converts an object to JSON with full recursive depth support (no depth limitation) |
| `Invoke-IgnoreSSL` | Disables SSL certificate validation for web requests (PowerShell 5 and 7+) |
| `Set-UseUnsafeHeaderParsing` | Enables or disables unsafe HTTP header parsing via .NET reflection |

## Requirements

- **PowerShell** 5.1 or later
- **System.Web** assembly (for URL encoding functions)

## Installation

```powershell
# Clone or copy the module to a PowerShell module path
Copy-Item -Path ".\PSSomeAPIThings" -Destination "$env:USERPROFILE\Documents\PowerShell\Modules\PSSomeAPIThings" -Recurse

# Or import directly
Import-Module ".\PSSomeAPIThings\PSSomeAPIThings.psd1"
```

## Quick Start

### Send a GraphQL query
```powershell
$uri = "https://api.example.com/graphql"

$query = '
    query GetUsers {
        users {
            id
            name
            email
        }
    }
'

# Get results as objects (returns .data directly)
$result = Invoke-GraphQLQuery2 -Query $query -Uri $uri
$result.users | Format-Table

# Get full response (with .data and .errors)
Invoke-GraphQLQuery2 -Query $query -Uri $uri -Raw
```

### Build and parse URLs
```powershell
# Build a URL with query parameters
$url = ConvertTo-URL -URL "https://api.example.com/search" -Arguments @{
    q = "powershell modules"
    page = 1
    limit = 25
}

# Parse a URL into components
$parsed = Get-URLObject -urlcommand "https://api.example.com/v1/search?q=hello&page=1"
$parsed.arguments  # Decoded query parameters as hashtable

# Extract domain from hostname
Get-DomainFromHostname -Hostname "api.sub.example.com"  # Returns "sub.example.com"
```

### Handle SSL and headers
```powershell
# Ignore SSL certificate errors (dev/test environments)
Invoke-IgnoreSSL

# Enable unsafe header parsing for malformed responses
Set-UseUnsafeHeaderParsing -Enable
```

## Module Structure

```
PSSomeAPIThings/
├── PSSomeAPIThings.psd1    # Module manifest
├── PSSomeAPIThings.psm1    # Module loader (dot-sources all .ps1 files)
├── README.md               # This file
├── LICENSE                  # PolyForm Noncommercial License
├── GraphQL/                 # GraphQL query/mutation support
├── Other/                   # JSON, SSL, and header utilities
└── URL/                     # URL parsing and building functions
```

## Author

**Loïc Ade**

## License

This project is licensed under the [PolyForm Noncommercial License 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/). See the [LICENSE](LICENSE) file for details.

In short:
- **Non-commercial use only** — You may use, modify, and distribute this software for any non-commercial purpose.
- **Attribution required** — You must include a copy of the license terms with any distribution.
- **No warranty** — The software is provided as-is.
