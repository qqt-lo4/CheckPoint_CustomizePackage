function Get-FunctionCode {
    <#
    .SYNOPSIS
    Extracts the source code of a function for embedding in scripts
    
    .DESCRIPTION
    Returns the complete source code of a PowerShell function including its
    definition, which can be embedded into generated scripts or scheduled tasks.
    
    .PARAMETER FunctionName
    The name of the function to extract
    
    .EXAMPLE
    $code = Get-FunctionCode -FunctionName "Get-DeviceMSAToken"
    
    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
        Useful for creating self-contained scripts that need to run in isolated contexts
        like scheduled tasks or elevated processes.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$FunctionName
    )
    
    $func = Get-Item "Function:\$FunctionName" -ErrorAction SilentlyContinue
    if ($func) {
        $functionBody = $func.ScriptBlock.ToString()
        return @"
function $FunctionName {
$functionBody
}
"@
    } else {
        throw [System.ArgumentException] "Function '$FunctionName' not found"
    }
}
