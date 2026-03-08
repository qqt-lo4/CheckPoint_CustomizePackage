# PSSomeDataThings

A PowerShell module providing data manipulation utilities: array pagination, CSV parsing, hashtable operations, JSON helpers, regex repository, string processing, and type conversion.

## Requirements

- PowerShell 5.1 or later

## Installation

Clone or copy the `PSSomeDataThings` folder into one of your PowerShell module directories:

```powershell
# User scope
$env:USERPROFILE\Documents\PowerShell\Modules\

# System scope
$env:ProgramFiles\PowerShell\Modules\
```

Then import the module:

```powershell
Import-Module PSSomeDataThings
```

## Functions

### Array (7 functions)

| Function | Description |
|----------|-------------|
| `Get-ArrayPage` | Returns a specific page of items from an array with pagination support |
| `Get-ItemIndex` | Finds the index of an item in an array using a scriptblock condition |
| `Get-PaginatedArrayBoundaries` | Calculates start and end boundaries for array pagination |
| `New-ArrayPageExtractor` | Creates a stateful paginator object for navigating through an array |
| `Search-ObjectByProperty` | Searches an array of objects by property value with nested field support |
| `Test-ContainsArray` | Tests whether an array contains all elements of another array |
| `Test-MultipleColumns` | Validates that an object array contains the expected columns |

### CSV (4 functions)

| Function | Description |
|----------|-------------|
| `Convert-FixedWidthTextData` | Parses fixed-width column text into structured objects |
| `Convert-TSVWithDashLine` | Converts TSV text with dash separator lines into objects |
| `Get-CSVColumnCount` | Counts the number of columns in a CSV/TSV string |
| `Optimize-TSVText` | Preprocesses and cleans TSV text data for further parsing |

### DateTime (1 function)

| Function | Description |
|----------|-------------|
| `Convert-EpochDateTime` | Converts Unix epoch timestamps (milliseconds) to DateTime objects |

### Guid (2 functions)

| Function | Description |
|----------|-------------|
| `ConvertTo-Guid` | Converts Windows Installer package codes to standard GUID format |
| `Test-IsGuid` | Tests whether a string is a valid GUID |

### Hashtable (12 functions)

| Function | Description |
|----------|-------------|
| `Clear-EmptyHashtableValues` | Removes null or empty values from a hashtable |
| `Compare-Hashtable` | Compares two hashtables and returns differences |
| `Convert-ArrayToHashtable` | Indexes an array of objects into a hashtable by a specified property |
| `Convert-HashtableValue` | Transforms hashtable values using a scriptblock |
| `Convert-MatchInfoToHashtable` | Extracts named regex capture groups from MatchInfo into a hashtable |
| `Convert-MatchingGroupToHashtable` | Converts regex matching groups to a hashtable |
| `Convert-StringArrayToHashtable` | Parses "key: value" formatted lines into a hashtable |
| `ConvertTo-Hashtable` | Recursively converts PSCustomObject to hashtable |
| `Copy-Hashtable` | Creates a shallow copy of a hashtable with optional property filtering |
| `Merge-Hashtable` | Merges two hashtables into one |
| `Rename-HashtableProperty` | Renames hashtable keys using regex, mapping, or indexed renaming |
| `Select-HashtableProperty` | Selects specific keys from a hashtable with wildcard support |

### Json (2 functions)

| Function | Description |
|----------|-------------|
| `ConvertFrom-Jsonc` | Strips comments from JSONC content before parsing as JSON |
| `Get-JSONFileList` | Retrieves a filtered list of JSON files from a directory |

### Number (2 functions)

| Function | Description |
|----------|-------------|
| `Convert-SizeToInt` | Converts size strings (e.g., "10MB") to byte values |
| `Test-IsBoundValue` | Tests if a value equals the min or max boundary of its type |

### Regex Repository (14 functions)

| Function | Description |
|----------|-------------|
| `Get-DNSRegex` | Returns a regex pattern for DNS hostnames |
| `Get-FragmentRegex` | Returns a regex pattern for URI fragment identifiers |
| `Get-HostPortRegex` | Returns a regex pattern for host:port combinations |
| `Get-HostRegex` | Returns a regex pattern combining IP and DNS host matching |
| `Get-IPRegex` | Returns regex patterns for IPv4 and IPv6 addresses |
| `Get-MacAddressRegex` | Returns a regex pattern for MAC addresses |
| `Get-Networkv4Regex` | Returns a regex pattern for IPv4 CIDR notation |
| `Get-Networkv6Regex` | Returns a regex pattern for IPv6 CIDR notation |
| `Get-PathRegex` | Returns a regex pattern for URI paths |
| `Get-PortRegex` | Returns a regex pattern for port numbers (0-65535) |
| `Get-QueryRegex` | Returns a regex pattern for URI query strings |
| `Get-SchemeRegex` | Returns a regex pattern for URI schemes |
| `Get-URIRegex` | Returns a comprehensive regex pattern for full URIs (RFC 3986) |
| `Get-UserInfoRegex` | Returns a regex pattern for URI user information |

### String (11 functions)

| Function | Description |
|----------|-------------|
| `ConvertFrom-AlignedText` | Converts column-aligned text output into structured objects |
| `ConvertFrom-Base64` | Decodes a Base64-encoded string to plain text |
| `ConvertTo-String` | Converts objects (including SecureString) to string representation |
| `Measure-TextStats` | Measures text statistics such as maximum line width |
| `Remove-EmptyString` | Removes empty lines from a string array |
| `Select-LineRange` | Selects a range of lines using regex delimiters |
| `Select-StringMatchingGroup` | Extracts named regex capture groups from a string |
| `Set-Indent` | Adds indentation to each line of a multiline string |
| `Split-TextOnBlankLines` | Splits text into blocks separated by blank lines |
| `Test-StringEnd` | Tests if a string ends with any of the specified suffixes |
| `Test-StringIsDateTime` | Tests if a value can be parsed as a DateTime |

## Usage

```powershell
Import-Module PSSomeDataThings

# Paginate an array
$page = Get-ArrayPage -InputObject (1..100) -PageSize 10 -PageNumber 3

# Parse column-aligned CLI output
Get-Process | Out-String | ConvertFrom-AlignedText

# Convert a hashtable
$ht = @{ Name = "John"; Age = 30 }
$copy = Copy-Hashtable -InputObject $ht -Include "Name"

# Build a URI regex
$uriPattern = Get-URIRegex
"https://example.com/path?q=1" -match $uriPattern

# Decode Base64
"SGVsbG8gV29ybGQ=" | ConvertFrom-Base64
```

## Author

**Loïc Ade**

## License

This project is licensed under the [PolyForm Noncommercial License 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/). See the [LICENSE](LICENSE) file for details.

In short:
- **Non-commercial use only** — You may use, modify, and distribute this software for any non-commercial purpose.
- **Attribution required** — You must include a copy of the license terms with any distribution.
- **No warranty** — The software is provided as-is.
