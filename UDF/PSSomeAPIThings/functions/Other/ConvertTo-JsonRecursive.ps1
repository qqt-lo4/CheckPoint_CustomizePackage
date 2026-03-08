function ConvertTo-JsonRecursive {
    <#
    .SYNOPSIS
        Converts an object to JSON with full recursive depth support

    .DESCRIPTION
        Recursively serializes any PowerShell object to JSON without the depth
        limitations of ConvertTo-Json. Handles hashtables, arrays, PSObjects,
        dates (ISO 8601), GUIDs, booleans, numbers, and nested structures.

    .PARAMETER InputObject
        The object to convert to JSON.

    .PARAMETER Compress
        If specified, outputs minified JSON without indentation or newlines.

    .PARAMETER IndentLevel
        The starting indentation level. Used internally for recursive calls.

    .OUTPUTS
        [string]. The JSON string representation of the input object.

    .EXAMPLE
        $data | ConvertTo-JsonRecursive

    .EXAMPLE
        ConvertTo-JsonRecursive -InputObject $hashtable -Compress

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$InputObject,
        
        [Parameter(Mandatory = $false)]
        [switch]$Compress,
        
        [Parameter(Mandatory = $false)]
        [int]$IndentLevel = 0
    )
    
    begin {
        # Set indentation based on the Compress parameter
        $indent = ''
        $newLine = ''
        $tab = ''
        
        if (-not $Compress) {
            $tab = '    ' # 4 spaces for indentation
            $newLine = "`n"
            $indent = $tab * $IndentLevel
        }
    }
    
    process {
        # Internal recursive function
        function Format-ValueAsJson {
            param (
                [Parameter(Mandatory = $true)]
                [AllowNull()]
                [object]$Value,
                
                [Parameter(Mandatory = $false)]
                [int]$CurrentIndentLevel = $IndentLevel
            )
            
            $currentIndent = if (-not $Compress) { $tab * $CurrentIndentLevel } else { '' }
            $nextIndent = if (-not $Compress) { $tab * ($CurrentIndentLevel + 1) } else { '' }
            
            # Handle null values
            if ($null -eq $Value) {
                return "null"
            }
            
            # Handle boolean values
            if ($Value -is [bool]) {
                return if ($Value) { "true" } else { "false" }
            }
            
            # Handle numeric values
            if ($Value -is [int] -or $Value -is [long] -or $Value -is [double] -or $Value -is [decimal]) {
                # Use invariant culture to avoid decimal separator issues
                return ([string]$Value).Replace(',', '.')
            }
            
            # Handle dates (convert to ISO 8601 format)
            if ($Value -is [datetime]) {
                return """$($Value.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'))"""
            }
            
            # Handle GUIDs
            if ($Value -is [guid]) {
                return """$Value"""
            }
            
            # Handle strings
            if ($Value -is [string]) {
                # Escape special characters
                $escaped = $Value.Replace('\', '\\').
                                  Replace('"', '\"').
                                  Replace("`n", '\n').
                                  Replace("`r", '\r').
                                  Replace("`t", '\t').
                                  Replace("`b", '\b').
                                  Replace("`f", '\f')
                return """$escaped"""
            }
            
            # Handle arrays
            if ($Value -is [array] -or $Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string] -or $Value -is [System.Collections.IDictionary])) {
                $arrayItems = @()
                
                foreach ($item in $Value) {
                    $formattedItem = Format-ValueAsJson -Value $item -CurrentIndentLevel ($CurrentIndentLevel + 1)
                    $arrayItems += "$nextIndent$formattedItem"
                }
                
                if ($arrayItems.Count -eq 0) {
                    return "[]"
                }
                else {
                    $arrayJson = "$newLine" + ($arrayItems -join ",$newLine") + "$newLine$currentIndent"
                    return "[$arrayJson]"
                }
            }
            
            # Handle hashtables and dictionaries
            if ($Value -is [System.Collections.IDictionary]) {
                return Format-HashtableAsJson -Hashtable $Value -CurrentIndentLevel $CurrentIndentLevel
            }
            
            # Handle PSObject objects (convert to hashtable then process)
            if ($Value -is [PSObject]) {
                $hashtable = @{}
                foreach ($property in $Value.PSObject.Properties) {
                    $hashtable[$property.Name] = $property.Value
                }
                return Format-HashtableAsJson -Hashtable $hashtable -CurrentIndentLevel $CurrentIndentLevel
            }
            
            # For any other type, convert to string
            return """$Value"""
        }
        
        # Dedicated function for formatting hashtables
        function Format-HashtableAsJson {
            param (
                [Parameter(Mandatory = $true)]
                [System.Collections.IDictionary]$Hashtable,
                
                [Parameter(Mandatory = $false)]
                [int]$CurrentIndentLevel = $IndentLevel
            )
            
            $currentIndent = if (-not $Compress) { $tab * $CurrentIndentLevel } else { '' }
            $nextIndent = if (-not $Compress) { $tab * ($CurrentIndentLevel + 1) } else { '' }
            
            $properties = @()
            
            foreach ($key in $Hashtable.Keys) {
                $value = $Hashtable[$key]
                $formattedValue = Format-ValueAsJson -Value $value -CurrentIndentLevel ($CurrentIndentLevel + 1)
                
                # Escape the key if necessary
                $escapedKey = $key.Replace('\', '\\').
                                   Replace('"', '\"').
                                   Replace("`n", '\n').
                                   Replace("`r", '\r').
                                   Replace("`t", '\t')
                
                $properties += "$nextIndent""$escapedKey"": $formattedValue"
            }
            
            if ($properties.Count -eq 0) {
                return "{}"
            }
            else {
                $propertiesJson = "$newLine" + ($properties -join ",$newLine") + "$newLine$currentIndent"
                return "{$propertiesJson}"
            }
        }
        
        # Call the recursive function with the input object
        return Format-ValueAsJson -Value $InputObject
    }
}