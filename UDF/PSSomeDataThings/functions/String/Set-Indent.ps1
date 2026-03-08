function Set-Indent {
    <#
    .SYNOPSIS
        Adds indentation to each line of a multiline string

    .DESCRIPTION
        Prepends the specified characters (default: two tabs) to every line of the
        provided text. The text is modified in-place via a reference parameter.

    .PARAMETER CharactersToAdd
        The indentation characters to prepend to each line. Defaults to two tabs.

    .PARAMETER TextToIndent
        A reference to the string variable to indent. Modified in-place.

    .OUTPUTS
        None. The input string is modified by reference.

    .EXAMPLE
        $text = "Line1`nLine2"
        Set-Indent -TextToIndent ([ref]$text) -CharactersToAdd "    "

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [string]$CharactersToAdd = "`t`t",
        [Parameter(Mandatory)]
        [ref]$TextToIndent
    )
    $aText = $TextToIndent.Value.Split("`n")
    $sResult = ""
    foreach ($item in $aText) {
        $sResult += $CharactersToAdd + $item + "`n"
    }
    $TextToIndent.Value = $sResult
}
