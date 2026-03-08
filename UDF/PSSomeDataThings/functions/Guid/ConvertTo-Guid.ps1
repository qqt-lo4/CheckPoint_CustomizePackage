function ConvertTo-Guid {
    <#
    .SYNOPSIS
        Converts a Windows Installer package code or product ID to a GUID

    .DESCRIPTION
        Reverses the character shuffling used by Windows Installer to encode
        GUIDs as registry key names (PackageCode/ProductId format).

    .PARAMETER PackageCode
        A Windows Installer package code string (32 hex characters, shuffled)

    .PARAMETER ProductId
        A Windows Installer product ID string (32 hex characters, shuffled)

    .OUTPUTS
        System.Guid. The decoded GUID.

    .EXAMPLE
        ConvertTo-Guid -PackageCode "1234567890ABCDEF1234567890ABCDEF"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, ParameterSetName = "PackageCode")]
        [string]$PackageCode,
        [Parameter(Mandatory, ParameterSetName = "ProductId")]
        [string]$ProductId
    )
    $aItemToGuidIndex = @(
        7, 6, 5, 4, 3, 2, 1, 0, 
        11, 10, 9, 8, 
        15, 14, 13, 12, 
        17, 16, 19, 18, 
        21, 20, 23, 22, 25, 24, 27, 26, 29, 28, 31, 30
    )
    switch ($PSCmdlet.ParameterSetName) {
        { $_ -in @("PackageCode", "ProductId") } {
            $sInputString = $PSBoundParameters[$PSCmdlet.ParameterSetName]
            $sResult = -join ($aItemToGuidIndex | ForEach-Object{$sInputString[$_]})
            return [guid]::Parse($sResult)
        }
        default {
            throw "Impossible Exception"
        }
    }
}