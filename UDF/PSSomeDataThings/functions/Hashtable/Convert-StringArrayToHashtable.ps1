
function Convert-StringArrayToHashtable {
    <#
    .SYNOPSIS
        Converts key:value string lines to an ordered hashtable

    .DESCRIPTION
        Parses an array of "key : value" formatted strings into an ordered hashtable.
        Can merge into an existing hashtable if provided.

    .PARAMETER Lines
        String array of "key : value" lines to parse

    .PARAMETER ExistingHash
        Optional existing ordered dictionary to merge into

    .OUTPUTS
        OrderedDictionary. Parsed key-value pairs.

    .EXAMPLE
        "Name: John", "Age: 30" | Convert-StringArrayToHashtable

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [AllowEmptyString()]
        [string[]]$Lines,
        [System.Collections.Specialized.OrderedDictionary]$ExistingHash = @{}
    )
    Begin {
        $aLines = @()
    }
    Process {
        $aLines += $Lines
    }
    End {
        foreach ($line in $aLines) {
            if ($line -match '^\s*(.+?)\s*:\s*(.*)$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                $ExistingHash[$key] = $value
            }
        }
    
        return $ExistingHash    
    }
}
