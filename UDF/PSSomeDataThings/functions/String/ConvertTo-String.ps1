function ConvertTo-String {
    <#
    .SYNOPSIS
        Converts objects to their string representation

    .DESCRIPTION
        Converts various object types to strings. Handles SecureString by decrypting
        to plain text, passes through regular strings, and calls ToString() on other objects.

    .PARAMETER InputObject
        The object to convert to a string. Accepts pipeline input.

    .OUTPUTS
        System.String. The string representation of the input object.

    .EXAMPLE
        $secureStr | ConvertTo-String
        # Decrypts a SecureString to plain text

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [object]$InputObject
    )
    Begin {}
    Process {
        foreach ($item in $InputObject) {
            if ($item -is [securestring]) {
                [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($item))
            } elseif ($item -is [string]) {
                $item
            } else {
                $item.ToString()
            }
        }
    }
    End {}
}