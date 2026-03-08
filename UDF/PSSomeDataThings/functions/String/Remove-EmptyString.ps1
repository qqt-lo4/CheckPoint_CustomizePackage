function Remove-EmptyString {
    <#
    .SYNOPSIS
        Removes empty lines from a string array

    .DESCRIPTION
        Filters out empty or whitespace-only lines from text input. By default removes
        all empty lines. With -TrimOnly, removes only leading and trailing empty lines
        while preserving empty lines in the middle of the text.

    .PARAMETER InputObject
        The string or string array to process. Accepts pipeline input.

    .PARAMETER TrimOnly
        If specified, only removes empty lines at the beginning and end of the input,
        preserving empty lines within the content.

    .OUTPUTS
        System.String[]. The filtered lines.

    .EXAMPLE
        "Line1", "", "Line2", "", "Line3" | Remove-EmptyString
        # Returns "Line1", "Line2", "Line3"

    .EXAMPLE
        "Line1", "", "Line2", "", "Line3" | Remove-EmptyString -TrimOnly
        # Returns "Line1", "", "Line2", "", "Line3" (no leading/trailing blanks)

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string[]]$InputObject,
        
        [Parameter(Mandatory = $false)]
        [switch]$TrimOnly
    )
    Process {
        $sInputObject = if ($InputObject.Count -gt 1) { 
            $InputObject
        } else {
            $InputObject.Split("`r`n")
        }
        
        if ($TrimOnly) {
            # Enlever uniquement les lignes vides au début et à la fin
            $firstNonEmpty = 0
            $lastNonEmpty = $sInputObject.Count - 1
            
            # Trouver la première ligne non vide
            for ($i = 0; $i -lt $sInputObject.Count; $i++) {
                if ($sInputObject[$i].Trim() -ne "") {
                    $firstNonEmpty = $i
                    break
                }
            }
            
            # Trouver la dernière ligne non vide
            for ($i = $sInputObject.Count - 1; $i -ge 0; $i--) {
                if ($sInputObject[$i].Trim() -ne "") {
                    $lastNonEmpty = $i
                    break
                }
            }
            
            # Retourner la plage sans les lignes vides de début et fin
            if ($firstNonEmpty -le $lastNonEmpty) {
                $sInputObject[$firstNonEmpty..$lastNonEmpty]
            }
        } else {
            # Comportement par défaut : enlever toutes les lignes vides
            $sInputObject | Where-Object { $_.Trim() -ne "" }
        }
    }
}