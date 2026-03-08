function ConvertTo-OneLineScriptBlock {
    <#
    .SYNOPSIS
        Converts a script block to a single line

    .DESCRIPTION
        Takes a multi-line script block and converts it to a single line by removing empty
        lines, trimming whitespace, and joining statements with semicolons.

    .PARAMETER ScriptBlock
        The script block to convert.

    .OUTPUTS
        [String]. Single-line representation of the script block.

    .EXAMPLE
        ConvertTo-OneLineScriptBlock -ScriptBlock { Get-Process; Get-Service }

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [scriptblock]$ScriptBlock
    )
    $aString = $ScriptBlock.ToString().Split("`n")
    $aResult = @()
    foreach ($item in $aString) {
        if ($item.Trim() -ne "") {
            $aResult += $item.Trim()
        }
    }
    return $aResult -join " ; "
}