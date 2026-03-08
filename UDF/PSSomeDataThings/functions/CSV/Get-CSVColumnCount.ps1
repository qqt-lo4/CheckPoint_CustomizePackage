function Get-CSVColumnCount {
    <#
    .SYNOPSIS
        Counts the number of columns in a CSV file

    .DESCRIPTION
        Reads the first line of a CSV file and counts the number of fields,
        handling quoted fields with embedded commas and escaped double quotes.

    .PARAMETER csvPath
        Path to the CSV file

    .OUTPUTS
        System.Int32. The number of columns in the CSV file.

    .EXAMPLE
        Get-CSVColumnCount "C:\Data\export.csv"

    .NOTES
        Original link : http://sp.ntpcug.org/PowerShell/Shared%20Documents/Larry_Weiss_Get-ColumnCount_function.ps1
        Version : 1.0.0
    #>

    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$csvPath
    )

    $columnCount = 0
    $insideQuotedField = $false
    $headerLine = @(Get-Content $csvPath -TotalCount 1)[0]
    $lastIndex = $headerLine.Length - 1

    for ($i = 0; $i -le $lastIndex; $i++) {
        $char = $headerLine[$i]

        # Handle double-quote logic
        if ($char -eq '"') {
            if ($insideQuotedField) {
                if (($i -ne $lastIndex) -and ($headerLine[$i + 1] -eq '"')) {
                    $i++ # Skip escaped double-quote ("")
                }
                else {
                    $insideQuotedField = $false
                }
            }
            else {
                $insideQuotedField = $true
            }
        }

        # Count commas that are not inside quoted fields
        if (($char -eq ',') -and (-not $insideQuotedField)) {
            $columnCount++
        }
    }

    return $columnCount + 1
}

# function Get-CSVColumnCount {
#     <#
#     .SYNOPSIS
#         Counts the number of columns in a CSV file

#     .DESCRIPTION
#         Reads the first line of a CSV file and counts the number of fields,
#         handling quoted fields with embedded commas and escaped double quotes.

#     .PARAMETER csvPath
#         Path to the CSV file

#     .OUTPUTS
#         System.Int32. The number of columns in the CSV file.

#     .EXAMPLE
#         Get-CSVColumnCount "C:\Data\export.csv"

#     .NOTES
#         Original link : http://sp.ntpcug.org/PowerShell/Shared%20Documents/Larry_Weiss_Get-ColumnCount_function.ps1
#         Version : 1.0.0
#     #>

#     param(
#         [Parameter(Mandatory, Position = 0)]
#         [string]$csvPath
#     )

#     # All code below expects the CSV file to be well-formed
#     # ------------------------------------------------------

#     # Examine the first record to learn the number of fields in each record
#     # ----------------------------------------------------------------------
#     $n = 0                                # $n will be the number of fields in a record in this file
#     $q = $false                           # if $q is $true then we are inside a quoted field
#     $s = @(gc $csvPath -TotalCount 1)[0]  # read the first line of the CSV
#     $m = $s.length - 1                    # $m is the maximum index for the string
#     for ($i = 0; $i -le $m; $i++) {
#         $c = $s[$i]
#         if ($c -eq '"') {
#             if ($q) {
#                 if (($i -ne $m) -and ($s[$i+1] -eq '"')) {
#                     $i++ # ignore two consecutive doublequotes inside a doublequote wrapped field
#                 } else  { 
#                     $q = $false
#                 }
#             } else {
#                 $q = $true
#             }
#         }
#         if (($c -eq ',') -and (!($q))) {$n++} # count commas except those in doublequote wrapped fields
#     }
#     $n++

#     return $n
# }