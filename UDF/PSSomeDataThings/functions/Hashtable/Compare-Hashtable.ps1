function Compare-Hashtable {
    <#
    .SYNOPSIS
        Compares two hashtables and returns an array of differences

    .DESCRIPTION
        Computes differences between two hashtables. Results are returned as objects
        with properties: "key" (differing key name), "side" ("<=" left-only, "!=" different,
        "=>" right-only), "lvalue" and "rvalue" (respective values).

    .PARAMETER Left
        The left-hand side hashtable to compare

    .PARAMETER Right
        The right-hand side hashtable to compare

    .OUTPUTS
        PSCustomObject[]. Difference objects with key, lvalue, rvalue, and side properties.

    .EXAMPLE
        Compare-Hashtable @{ a = 1; b = 2; c = 3 } @{ b = 2; c = 4; e = 5 }

    .EXAMPLE
        $left = @{ a = 1; b = 2; c = 3; f = $null; g = 6 }
        $right = @{ b = 2; c = 4; e = 5; f = $null; g = $null }
        Compare-Hashtable $left $right

    .LINK
        https://gist.github.com/dbroeglin/c6ce3e4639979fa250cf

    .NOTES
        Version : 1.0.0
    #>	
[CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Hashtable]$Left,

        [Parameter(Mandatory = $true)]
        [Hashtable]$Right		
    )
    
    function New-Result($Key, $LValue, $Side, $RValue) {
        New-Object -Type PSObject -Property @{
                    key    = $Key
                    lvalue = $LValue
                    rvalue = $RValue
                    side   = $Side
            }
    }
    [Object[]]$Results = $Left.Keys | ForEach-Object {
        if ($Left.ContainsKey($_) -and !$Right.ContainsKey($_)) {
            New-Result $_ $Left[$_] "<=" $Null
        } else {
            $LValue, $RValue = $Left[$_], $Right[$_]
            if ($LValue -ne $RValue) {
                New-Result $_ $LValue "!=" $RValue
            }
        }
    }
    $Results += $Right.Keys | ForEach-Object {
        if (!$Left.ContainsKey($_) -and $Right.ContainsKey($_)) {
            New-Result $_ $Null "=>" $Right[$_]
        } 
    }
    $Results 
}
