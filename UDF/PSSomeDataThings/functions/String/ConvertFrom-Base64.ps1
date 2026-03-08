function ConvertFrom-Base64 {
    <#
    .SYNOPSIS
        Decodes a Base64-encoded string to plain text

    .DESCRIPTION
        Converts a Base64-encoded string back to its original UTF-8 text representation.
        Accepts pipeline input for batch decoding.

    .PARAMETER EncodedString
        The Base64-encoded string to decode.

    .OUTPUTS
        System.String. The decoded UTF-8 string, or $null on error.

    .EXAMPLE
        "SGVsbG8gV29ybGQ=" | ConvertFrom-Base64
        # Returns "Hello World"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$EncodedString
    )
    
    process {
        try {
            $decodedBytes = [System.Convert]::FromBase64String($EncodedString)
            $decodedString = [System.Text.Encoding]::UTF8.GetString($decodedBytes)
            return $decodedString
        }
        catch {
            Write-Error "Erreur lors du décodage Base64 : $_"
            return $null
        }
    }
}