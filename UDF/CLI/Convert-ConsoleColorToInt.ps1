function Convert-ConsoleColorToInt {
    [CmdletBinding(DefaultParameterSetName = "FG")]
    Param(
        [Parameter(Mandatory, Position = 0)]
        [System.ConsoleColor]$Color,
        [Parameter(ParameterSetName = "FG")]
        [Alias("ForegroundColor", "Foreground")]
        [switch]$FG,
        [Parameter(ParameterSetName = "BG")]
        [Alias("BackgroundColor", "Background")]
        [switch]$BG
    )
    if ($PSCmdlet.ParameterSetName -eq "FG") {
        switch ($Color) {
            "Black"       { return 90 }
            "Blue"        { return 94 }
            "Cyan"        { return 96 }
            "DarkBlue"    { return 34 }
            "DarkCyan"    { return 36 }
            "DarkGray"    { return 30 }
            "DarkGreen"   { return 32 }
            "DarkMagenta" { return 35 }
            "DarkRed"     { return 31 }
            "DarkYellow"  { return 33 }
            "Gray"        { return 37 }
            "Green"       { return 92 }
            "Magenta"     { return 95 }
            "Red"         { return 91 }
            "White"       { return 97 }
            "Yellow"      { return 93 }
        }    
    } else {
        switch ($Color) {
            "Black"       { return 100 }
            "Blue"        { return 104 }
            "Cyan"        { return 106 }
            "DarkBlue"    { return  44 }
            "DarkCyan"    { return  46 }
            "DarkGray"    { return  40 }
            "DarkGreen"   { return  42 }
            "DarkMagenta" { return  45 }
            "DarkRed"     { return  41 }
            "DarkYellow"  { return  43 }
            "Gray"        { return  47 }
            "Green"       { return 102 }
            "Magenta"     { return 105 }
            "Red"         { return 101 }
            "White"       { return 107 }
            "Yellow"      { return 103 }
        } 
    }
}