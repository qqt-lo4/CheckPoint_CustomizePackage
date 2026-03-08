function ConvertFrom-AlignedText {
    <#
    .SYNOPSIS
        Converts column-aligned text output into structured objects

    .DESCRIPTION
        Parses fixed-width column-aligned text (such as CLI output) by detecting
        column positions from the header line and extracting values accordingly.
        Supports multiline input, skips separator lines, and can output either
        PSCustomObject or ordered hashtable.

    .PARAMETER InputObject
        The text lines to parse. Accepts pipeline input and multiline strings.

    .PARAMETER HeaderLineIndex
        The zero-based index of the header line. Defaults to 0.

    .PARAMETER AsHashtable
        If specified, returns ordered hashtables instead of PSCustomObject.

    .OUTPUTS
        PSCustomObject or System.Collections.Specialized.OrderedDictionary.
        One object per data line with properties matching column headers.

    .EXAMPLE
        "Name    Age    City`nJohn    30     Paris`nJane    25     Lyon" | ConvertFrom-AlignedText

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string[]]$InputObject,
        
        [Parameter(Mandatory = $false)]
        [int]$HeaderLineIndex = 0,
        
        [Parameter(Mandatory = $false)]
        [switch]$AsHashtable
    )
    
    Begin {
        $allLines = @()
    }
    
    Process {
        # Collecter toutes les lignes
        foreach ($item in $InputObject) {
            if ($item.Contains("`n") -or $item.Contains("`r")) {
                # Si c'est une chaîne multiligne, la découper
                $allLines += $item -split "`r?`n"
            } else {
                # Sinon, ajouter telle quelle
                $allLines += $item
            }
        }
    }
    
    End {
        # Enlever les lignes vides
        $allLines = $allLines | Where-Object { $_ -and $_.Trim() -ne "" }
        
        if ($allLines.Count -le $HeaderLineIndex) {
            Write-Warning "Pas assez de lignes dans l'entrée"
            return
        }
        
        # Récupérer la ligne d'en-tête
        $headerLine = $allLines[$HeaderLineIndex]
        
        # Détecter les positions des colonnes en cherchant les débuts de mots dans l'en-tête
        $columnPositions = @()
        $columnNames = @()
        
        # Trouver chaque colonne (séquence de non-espaces)
        $matches = [regex]::Matches($headerLine, '\S+')
        
        foreach ($match in $matches) {
            $columnPositions += $match.Index
            $columnNames += $match.Value.Trim()
        }
        
        # Ajouter une position de fin fictive pour faciliter l'extraction
        $columnPositions += $headerLine.Length + 100  # Marge de sécurité
        
        # Traiter les lignes de données (après l'en-tête)
        $dataLines = $allLines[($HeaderLineIndex + 1)..($allLines.Count - 1)]
        
        foreach ($line in $dataLines) {
            # Ignorer les lignes de séparation (tirets, etc.)
            if ($line -match '^[\s\-_=]+$') {
                continue
            }
            
            # Créer un objet ordered
            $obj = [ordered]@{}
            
            for ($i = 0; $i -lt $columnNames.Count; $i++) {
                $startPos = $columnPositions[$i]
                $endPos = $columnPositions[$i + 1]
                
                # Extraire la valeur en fonction de la position
                if ($startPos -lt $line.Length) {
                    $length = [Math]::Min($endPos - $startPos, $line.Length - $startPos)
                    $value = $line.Substring($startPos, $length).Trim()
                } else {
                    $value = ""
                }
                
                $obj[$columnNames[$i]] = $value
            }
            
            # Retourner soit la hashtable ordered, soit un PSCustomObject
            if ($AsHashtable) {
                $obj
            } else {
                [PSCustomObject]$obj
            }
        }
    }
}