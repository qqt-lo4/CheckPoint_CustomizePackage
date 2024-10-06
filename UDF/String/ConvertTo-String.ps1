function ConvertTo-String {
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