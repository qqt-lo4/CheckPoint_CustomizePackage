function Split-TextOnBlankLines {
    <#
    .SYNOPSIS
        Splits text into blocks separated by blank lines

    .DESCRIPTION
        Divides a multiline text string into an array of text blocks, splitting
        on sequences of two or more consecutive newlines. Empty blocks are excluded.

    .PARAMETER Text
        The multiline text to split. Accepts pipeline input.

    .OUTPUTS
        System.String[]. An array of non-empty text blocks.

    .EXAMPLE
        $text = "Block1 line1`nBlock1 line2`n`nBlock2 line1"
        $text | Split-TextOnBlankLines
        # Returns two blocks

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Text
    )
    
    process {
        # Diviser le texte en blocs séparés par des lignes vides
        # On utilise -split avec une regex qui capture une ou plusieurs lignes vides
        $blocks = $Text -split '(?:\r?\n){2,}' | Where-Object { $_.Trim() -ne '' }
        
        return $blocks
    }
}