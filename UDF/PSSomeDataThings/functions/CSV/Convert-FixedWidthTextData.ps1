function Convert-FixedWidthTextData {
    <#
    .SYNOPSIS
        Converts fixed-width text data into structured objects

    .DESCRIPTION
        Parses fixed-width (column-aligned) text output into ordered hashtables.
        Automatically detects column boundaries from header spacing or separator lines.
        Handles leading whitespace and empty lines.

    .PARAMETER dataArray
        String array containing the fixed-width text data

    .PARAMETER file
        Path to a file containing the fixed-width text data

    .OUTPUTS
        OrderedDictionary[]. Parsed rows as ordered hashtables with column headers as keys.

    .EXAMPLE
        $output = netstat -an | Convert-FixedWidthTextData

    .EXAMPLE
        Convert-FixedWidthTextData -file "C:\Temp\report.txt"

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
        [string]$file
    )
    Begin {
        function Test-IsSeparatorLine {
            Param(
                [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
                [string]$InputObject
            )
            return ($InputObject -Match "^( |-)+(`r`n|`n)?$")
        }

        $aTempData = if ($PSCmdlet.ParameterSetName -eq "array") {
            if ($dataArray.Count -eq 1) {
                $dataArray.Split("`n")
            } else {
                $dataArray
            }
        } else {
            Get-Content -Path $file
        }
        # sometimes the data contains empty lines at the beginning and at the end
        # $iFirstNotEmptyLine will contians the first not empty line
        # $iLastNotEmptyLine will contains the last not empty line
        $iFirstNotEmptyLine = 0
        $iLastNotEmptyLine = 0
        $bFirstNotEmptyLineFound = $false
        $bLastNotEmptyLineFound = $false
        for ($i = 0; $i -lt $aTempData.Count; $i++) {
            if ($bFirstNotEmptyLineFound) {
                if (-not $bLastNotEmptyLineFound) {
                    if ($aTempData[$i].Trim() -eq "") {
                        $bLastNotEmptyLineFound = $true
                    } else {
                        $iLastNotEmptyLine = $i
                    }
                }
            } else {
                if (([string]$aTempData[$i]).Trim() -eq "") {
                    $iFirstNotEmptyLine += 1
                } else {
                    $bFirstNotEmptyLineFound = $true
                }
            }
        }
        # now $aTempData contains only not empty lines
        $aTempData = $aTempData[$iFirstNotEmptyLine..$iLastNotEmptyLine]
        # sometimes input contains spaces at the left on all lines
        $ssSepearatorLine = Select-String -InputObject $aTempData[1] -Pattern "^(?<space> +)[^ ]+"
        $data = if ($ssSepearatorLine.Matches.Groups | Where-Object { $_.name -eq "space" }) {
            $sSpace = ($ssSepearatorLine.Matches.Groups | Where-Object { $_.name -eq "space" }).Value.Length
            foreach ($line in $aTempData) {
                $line.SubString($sSpace)
            }
        } else {
            $aTempData
        }
        # test table contains lines 
        $bContainsLines, $iFirstRowContent = if ($data.Count -gt 1) {
            if ((Test-IsSeparatorLine $data[1]) -and ($data.Count -gt 2)) {
                $true, 2
            } else {
                $true, 1
            }
        } else {
            $false, -1
        }
        if (-not $bContainsLines) {
            return $null
        }
    }
    Process {
        $headersString = $data[0]
        $lastchar = ""
        $separators = @(0)
        if (($data.Count -gt 2) -and (Test-IsSeparatorLine $data[1])) {
            $ssSpace = Select-String -InputObject $s -Pattern "(?<space> -)" -AllMatches
            $separators += ($ssSpace.Matches.Groups | Where-Object { $_.name -eq "space" }).Index
        } else {
            for ($i = 0; $i -lt $headersString.Length; $i++) {
                $currentChar = $headersString[$i]
                if (($lastchar -eq " ") -and ($currentChar -ne " ")) {
                    $separatorIsValid = $true
                    foreach ($line in $data) {
                        if (($line.Length -ge $i) -and ($line[$i - 1] -ne " ")) {
                            $separatorIsValid = $false
                        }
                    }
                    if ($separatorIsValid) {
                        $separators += $i 
                    }
                }
                $lastchar = $currentChar
            }
        }
    
        $longestLineCount = 0
        foreach ($line in $data) {
            if ($line.ToString().Length -gt $longestLineCount) {
                $longestLineCount = $line.ToString().Length
            }
        }
        $separators += $longestLineCount
    
        $headers = @()
        $result = @()
        for ($i = 0; $i -lt $data.Count; $i++) {
            $line = $data[$i]
            if ($i -eq 0) {
                for ($k = 0; $k -lt ($separators.Count - 1); $k++) {
                    $start = $separators[$k]
                    $end = $separators[$k + 1] - 1
                    $cellValue = ($headersString[$start..$end] -join "").Trim()
                    $headers += $cellValue
                }
            }
            if ($i -ge $iFirstRowContent) {
                $newEntry = [ordered]@{}
                for ($j = 0; $j -lt ($separators.Count - 1); $j++) {
                    $start = $separators[$j]
                    $end = $separators[$j + 1] - 1
                    $cellValue = ($line[$start..$end] -join "").Trim()
                    $newEntry.Add($headers[$j], $cellValue)
                }
                $result += $newEntry
            }
        }
    }
    End {
        return $result
    }
}
