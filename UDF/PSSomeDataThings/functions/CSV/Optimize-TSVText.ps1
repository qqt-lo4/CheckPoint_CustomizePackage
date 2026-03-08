function Optimize-TSVText {
    <#
    .SYNOPSIS
        Preprocesses TSV/fixed-width text data for parsing

    .DESCRIPTION
        Cleans up text table data by removing leading/trailing empty lines,
        stripping left-side whitespace, and identifying content boundaries
        (header line, separator line, first/last data line).

    .PARAMETER dataArray
        String array containing the text data

    .PARAMETER file
        Path to a file containing the text data

    .OUTPUTS
        PSCustomObject with Data (cleaned lines), InputData (original), FirstContentLine,
        and LastContentLine properties.

    .EXAMPLE
        $cleaned = Optimize-TSVText -dataArray $rawOutput

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
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
            return ($InputObject -Match "^( |-)+(`r`n|`n|`r)?$")
        }
    }
    Process {
        $hResult = @{}
        $aTempData = if ($PSCmdlet.ParameterSetName -eq "array") {
            if ($dataArray.Count -eq 1) {
                $dataArray.Split("`n")
            } else {
                $dataArray
            }
        } else {
            Get-Content -Path $file
        }
        $hResult.InputData = $aTempData
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
        $hResult.Data = $data
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
        if ($bContainsLines) {
            $hResult.FirstContentLine = $iFirstRowContent
            $hResult.LastContentLine = $data.Count - 1
        } else {
            $hResult.FirstContentLine = -1
            $hResult.LastContentLine = -1
        }
        return [pscustomobject]$hResult
    }
}