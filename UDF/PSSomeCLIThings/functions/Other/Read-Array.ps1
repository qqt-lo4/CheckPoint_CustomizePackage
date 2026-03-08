function Read-Array {
    <#
    .SYNOPSIS
        Reads a multi-line list from user input via Read-Host.

    .DESCRIPTION
        Prompts the user to enter items one per line using Read-Host in a loop.
        Input continues until an empty line (or a custom end pattern) is entered.
        Optionally groups items by regex patterns using GroupByProperties (an ordered
        dictionary where each key maps to a regex and options). Returns either a
        plain array of strings or a hashtable of grouped results.

    .PARAMETER Header
        Prompt message displayed before input begins.
        Default: "Please enter a list of items, a new line per item. Finish the list by entering an empty item:"

    .PARAMETER EndList
        Regex pattern that signals the end of input. Default: "^$" (empty line).

    .PARAMETER GroupByProperties
        An ordered dictionary defining regex-based grouping. Each key is a group name
        with a value containing a Regex property and an optional IgnoreOtherRegex property.
        Items not matching any group are placed in the "Other" group.

    .OUTPUTS
        [string[]] when GroupByProperties is not specified.
        [hashtable] when GroupByProperties is specified, with keys for each group plus "Other".

    .EXAMPLE
        $items = Read-Array
        # User enters items one per line, empty line to finish

        Reads a simple list of strings from user input.

    .EXAMPLE
        $grouped = Read-Array -GroupByProperties ([ordered]@{
            IPs = @{ Regex = '^\d+\.\d+\.\d+\.\d+$' }
            Names = @{ Regex = '^[a-zA-Z]+$' }
        })

        Groups user input into IPs, Names, and Other categories.

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [string]$Header = "Please enter a list of items, a new line per item. Finish the list by entering an empty item:",
        [string]$EndList = "^$",
        [System.Collections.Specialized.OrderedDictionary]$GroupByProperties
    )

    if ($GroupByProperties) {
        $hResult = @{}
        foreach ($sKey in $GroupByProperties.Keys) {
            $hResult.$sKey = @()
        }
        $hResult.Other = @()
    }

    Write-Host $Header
    $aResult = @()
    $sNewLine = Read-Host
    while ($sNewLine -notmatch $EndList) {
        if ($GroupByProperties) {
            $bFoundRegex = $false
            foreach ($sKey in $GroupByProperties.Keys) {
                if ($sNewLine -match $GroupByProperties.$sKey.Regex) {
                    $bFoundRegex = $true
                    $hResult.$sKey += $sNewLine
                    if ($GroupByProperties.$sKey.IgnoreOtherRegex) {
                        break
                    }
                }
            }
            if (-not $bFoundRegex) {
                $hResult.Other += $sNewLine
            }
        }
        $aResult += $sNewLine
        $sNewLine = Read-Host
    }
    if ($GroupByProperties) {
        return $hResult
    } else {
        return $aResult
    }
}