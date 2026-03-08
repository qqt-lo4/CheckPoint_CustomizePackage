function Convert-TSVWithDashLine {
    <#
    .SYNOPSIS
        Converts a dash-separated TSV table to structured objects

    .DESCRIPTION
        Parses text tables where column headers are separated from data by a dash line
        (e.g., command-line tool output). Supports header renaming, value transformation,
        and PSObject output.

    .PARAMETER dataArray
        String array containing the table text

    .PARAMETER file
        Path to a file containing the table text

    .PARAMETER TranslatedHeaders
        Optional custom header names to replace the original ones

    .PARAMETER TranslateValues
        Hashtable mapping header names to scriptblocks for value conversion

    .PARAMETER ToPSObject
        If specified, returns PSCustomObjects instead of ordered hashtables

    .OUTPUTS
        OrderedDictionary[] or PSCustomObject[]. Parsed table rows.

    .EXAMPLE
        Get-Service | Format-Table | Out-String | Convert-TSVWithDashLine

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
        
    [CmdLetBinding(DefaultParameterSetName = "array")]
    Param(
        [Parameter(Mandatory, ParameterSetName = "array", ValueFromPipeline, Position = 0)]
        [AllowEmptyString()]
        [string[]]$dataArray,
        [Parameter(Mandatory, ParameterSetName = "file")]
        [string]$file,
        [string[]]$TranslatedHeaders,
        [hashtable]$TranslateValues,
        [switch]$ToPSObject
    )
    Begin {
        $aLines = @()
    }
    Process {
        $aLines += $dataArray
    }
    End {
        $oData = if ($PSCmdlet.ParameterSetName -eq "array") {
            Optimize-TSVText $aLines
        } else {
            Optimize-TSVText -file $file
        }
        $headersString = $oData.data[0]
        $separators = @(0)
        if (($oData.data.Count -gt 2) -and ($oData.data[1] -match "^( |-)+(`r`n|`n|`r)?$")) {
            $ssSpace = Select-String -InputObject $oData.data[1] -Pattern "(?<space> -)" -AllMatches
            $separators += ($ssSpace.Matches.Groups | Where-Object { $_.name -eq "space" }).Index
        } else {
            return $null
        }
    
        $longestLineCount = 0
        foreach ($line in $oData.Data) {
            if ($line.ToString().Length -gt $longestLineCount) {
                $longestLineCount = $line.ToString().Length
            }
        }
        $separators += $longestLineCount
    
        $headers = @()
        if ($TranslatedHeaders) {
            $headers = $TranslatedHeaders
        } else {
            for ($k = 0; $k -lt ($separators.Count - 1); $k++) {
                $start = $separators[$k]
                $end = $separators[$k + 1] - 1
                $cellValue = ($headersString[$start..$end] -join "").Trim()
                $headers += $cellValue
            }
        }
    
        $result = @()
        for ($i = $oData.FirstContentLine; $i -le $oData.LastContentLine; $i++) {
            $line = $oData.data[$i]
            $newEntry = [ordered]@{}
            $shift = 0
            for ($j = 0; $j -lt ($separators.Count - 1); $j++) {
                $start = $shift + $separators[$j]
                $end = $separators[$j + 1] - 1
                $nextSeparator = $separators[$j + 1]
                $sNextSeparator = $line[$nextSeparator..$nextSeparator]
                if ($sNextSeparator -ne " ") {
                    $iLastChar = $line.Length
                    $sRemainingString = $line[$nextSeparator..$iLastChar] -join ""
                    $sSplit = $sRemainingString.Split(" ")[0]
                    $end += $sSplit.Length
                    $shift += $sSplit.Length
                }
                $cellValue = ($line[$start..$end] -join "").Trim()
                $oValue = if ($TranslateValues -and ($TranslateValues[$headers[$j]])) {
                    $oFunction = $TranslateValues[$headers[$j]]
                    Invoke-Command -ScriptBlock $oFunction -ArgumentList $oValue
                } else {
                    $cellValue
                }
                $newEntry.Add($headers[$j], $oValue)
            }
            if ($ToPSObject) {
                $result += [pscustomobject]$newEntry
            } else {
                $result += $newEntry
            }
        }
        return $result    
    }
}
