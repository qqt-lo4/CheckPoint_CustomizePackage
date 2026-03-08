function New-CLIDialogProperty {
    <#
    .SYNOPSIS
        Creates a read-only property display element for CLI dialog interfaces.

    .DESCRIPTION
        This function creates a non-interactive property display object for showing labeled
        information in CLI dialogs. It displays a header label followed by text content, with
        support for multi-line text, regex pattern highlighting (using Write-ColoredString),
        aligned layouts, and custom colors. Unlike text boxes, properties are read-only and
        used for displaying information rather than collecting input.

    .PARAMETER Header
        The label text displayed before the property value. This parameter is mandatory and can
        be used at position 0. Example: "Status", "IP Address", "Last Modified".

    .PARAMETER HeaderAlign
        The alignment of the header label. Valid values are "Left" or "Right". Default is "Left".
        Right alignment is useful for creating form-like layouts with aligned separators.

    .PARAMETER HeaderSeparator
        The separator text between the header and property value. Default is " : ".
        Example: " = ", " -> ", " >> ".

    .PARAMETER TextForegroundColor
        The foreground color of the property value text. Default is the current console
        foreground color.

    .PARAMETER TextBackgroundColor
        The background color of the property value text. Default is the current console
        background color.

    .PARAMETER MatchTextForegroundColor
        The foreground color for text matching the Pattern regex. Default is Blue.
        Used to highlight specific parts of the text (e.g., IP addresses, URLs).

    .PARAMETER MatchTextBackgroundColor
        The background color for text matching the Pattern regex. Default is the current
        console background color.

    .PARAMETER HeaderForegroundColor
        The foreground color of the header label. Default is Green.

    .PARAMETER HeaderBackgroundColor
        The background color of the header label. Default is the current console background color.

    .PARAMETER Pattern
        A regular expression pattern to highlight within the text. Matching portions will be
        displayed in MatchTextForegroundColor. Requires Write-ColoredString function.

    .PARAMETER ColorGroups
        Array of regex group numbers to colorize when Pattern is used. Default is @("0")
        which colors the entire match. Use specific group numbers to color only captured groups.

    .PARAMETER AllMatches
        Switch parameter. When specified with Pattern, highlights all matches in the text
        rather than just the first match.

    .PARAMETER SeparatorLocation
        The column position where the separator should be located. Used for aligning multiple
        properties in a list layout. If not specified, uses the header length.

    .PARAMETER Text
        The property value text to display. Can be a string array for multi-line values.
        Default is empty string. Multi-line text is automatically indented to align with
        the first line.

    .PARAMETER Prefix
        A prefix string displayed before the header. Used for indentation or visual hierarchy.
        Default is empty string.

    .PARAMETER Name
        A unique identifier for the property. If not specified, generates a name based on
        the header (e.g., "rowStatus"). Used for identification.

    .OUTPUTS
        Returns a hashtable object with the following members:
        - Properties: Type, Prefix, Header, HeaderAlign, HeaderSeparator, SeparatorLocation, Text,
                     Pattern, ColorGroups, AllMatches, Colors, Name
        - Methods: Draw(), GetTextHeight(), GetTextWidth(), IsDynamicObject()

    .EXAMPLE
        $prop = New-CLIDialogProperty -Header "Status" -Text "Running"
        $prop.Draw()

        Creates a simple property displaying "Status : Running".

    .EXAMPLE
        $ipProp = New-CLIDialogProperty -Header "IP Address" -Text "192.168.1.100" `
            -Pattern "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}" -MatchTextForegroundColor Cyan

        Creates a property with the IP address highlighted in cyan.

    .EXAMPLE
        $multiLineProp = New-CLIDialogProperty -Header "Description" -Text @(
            "This is a multi-line description."
            "Second line of text."
            "Third line of text."
        )

        Creates a property with multi-line text, automatically indented.

    .EXAMPLE
        $properties = @(
            New-CLIDialogProperty -Header "Name" -Text "Server01" -SeparatorLocation 15
            New-CLIDialogProperty -Header "Status" -Text "Online" -SeparatorLocation 15
            New-CLIDialogProperty -Header "IP" -Text "192.168.1.1" -SeparatorLocation 15
        )

        Creates aligned properties with consistent separator location.

    .EXAMPLE
        $urlProp = New-CLIDialogProperty -Header "URL" -Text "Visit https://example.com for more info" `
            -Pattern "https?://[^\s]+" -MatchTextForegroundColor Blue -ColorGroups @("0")

        Creates a property with URLs highlighted in blue using regex pattern.

    .EXAMPLE
        $indentedProp = New-CLIDialogProperty -Header "Path" -Text "C:\Users\Documents" `
            -Prefix "  " -HeaderForegroundColor Yellow

        Creates an indented property with yellow header.

    .NOTES
        Module: CLIDialog
        Author: Loïc Ade
        Created: 2025-10-20
        Version: 1.0.0
        Dependencies: Write-ColoredString

        This function is part of the CLI Dialog framework. Properties are read-only display
        elements used for showing information to users without allowing interaction.

        MULTI-LINE TEXT:
        - Text parameter accepts string arrays for multi-line content
        - Additional lines are automatically indented to align with the first line
        - Indentation width = SeparatorLocation + HeaderSeparator.Length

        PATTERN HIGHLIGHTING:
        - Pattern parameter enables regex-based text highlighting
        - Requires Write-ColoredString function to be available
        - ColorGroups specifies which regex capture groups to highlight
        - AllMatches switch highlights all occurrences (not just first)

        LAYOUT ALIGNMENT:
        - SeparatorLocation ensures consistent alignment across multiple properties
        - HeaderAlign allows left or right justification of labels
        - Prefix adds indentation for hierarchical displays

        METHODS:
        - Draw(): Renders the property with header, separator, and text (with optional highlighting)
        - GetTextHeight(): Returns number of lines in the text array
        - GetTextWidth(): Returns total width (prefix + separator location + separator + longest text line)
        - IsDynamicObject(): Returns $false (property is read-only, not interactive)

        CHANGELOG:

        Version 1.0.0 - 2025-10-20 - Loïc Ade
            - Initial release
            - Read-only property display
            - Multi-line text support with automatic indentation
            - Regex pattern highlighting with Write-ColoredString integration
            - Configurable color groups for selective highlighting
            - Aligned layouts with SeparatorLocation
            - Header alignment (left/right)
            - Custom prefix for indentation
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Header,
        [ValidateSet("Left", "Right")]
        [string]$HeaderAlign = "Left",
        [string]$HeaderSeparator = " : ",
        [System.ConsoleColor]$TextForegroundColor = (Get-Host).UI.RawUI.ForegroundColor,
        [System.ConsoleColor]$TextBackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [System.ConsoleColor]$MatchTextForegroundColor = [System.ConsoleColor]::Blue,
        [System.ConsoleColor]$MatchTextBackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [System.ConsoleColor]$HeaderForegroundColor = [System.ConsoleColor]::Green,
        [System.ConsoleColor]$HeaderBackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [string]$Pattern,
        [string[]]$ColorGroups = @("0"),
        [switch]$AllMatches,
        [int]$SeparatorLocation,
        [string[]]$Text = "",
        [string]$Prefix = "",
        [string]$Name
    )
    $hResult = @{
        Type = "property"
        Prefix = $Prefix
        Header = $Header
        HeaderAlign = $HeaderAlign
        HeaderSeparator = $HeaderSeparator
        SeparatorLocation = $SeparatorLocation
        Text = $Text
        Pattern = $Pattern
        ColorGroups = $ColorGroups
        AllMatches = $AllMatches
        TextForegroundColor = $TextForegroundColor
        TextBackgroundColor = $TextBackgroundColor
        MatchTextForegroundColor = $MatchTextForegroundColor
        MatchTextBackgroundColor = $MatchTextBackgroundColor
        HeaderForegroundColor = $HeaderForegroundColor
        HeaderBackgroundColor = $HeaderBackgroundColor
        Name = if ($Name) { $Name } else { "row" + $Header.Replace("$([char]27)[4m", "").Replace("$([char]27)[24m", "").Replace(" ", "") }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "Draw" -Value {
        if (($this.Text -eq $null) -or ($this.Text -eq "")) {
            Write-Host ""
        } else {
            # write header
            if ($this.Prefix) {
                Write-Host $this.Prefix -NoNewline -ForegroundColor $this.HeaderForegroundColor -BackgroundColor $this.HeaderBackgroundColor
            }
            if ($this.Header) {
                $iAlign = if ($this.HeaderAlign -eq "Left") { -1 } else { 1 }
                Write-Host (("{0,$($this.SeparatorLocation * $iAlign)}" -f $this.Header) + $this.HeaderSeparator) -NoNewline -ForegroundColor $this.HeaderForegroundColor -BackgroundColor $this.HeaderBackgroundColor
            }
            # write content
            $fWH, $hWHArgs = if ($this.Pattern) {
                Get-ChildItem Function:\Write-ColoredString
                @{
                    Pattern = $this.Pattern
                    ForegroundColor = $this.TextForegroundColor
                    BackgroundColor = $this.TextBackgroundColor
                    MatchForegroundColor = $this.MatchTextForegroundColor
                    MatchBackgroundColor = $this.MatchTextBackgroundColor
                    ColorGroups = $this.ColorGroups
                }
            } else {
                Get-Command "Write-host"
                @{
                    ForegroundColor = $this.TextForegroundColor
                    BackgroundColor = $this.TextBackgroundColor
                }
            }
            if ($this.Text) {
                if ($this.Text[0]) {
                    $sText = $this.Text[0]
                    . $fWH @hWHArgs -Object $sText
                }
                $sMultiLineSpace = " " * ($this.SeparatorLocation + $this.HeaderSeparator.Length)
                for ($i = 1; $i -lt $this.Text.Count; $i++) {
                    . $fWH @hWHArgs -Object $($sMultiLineSpace + $this.Text[$i])
                }
            } else {
                Write-Host ""
            }
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetTextHeight" -Value {
        return $this.Text.Count
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetTextWidth" -Value {
        $iResult = 0
        foreach ($sLine in $this.Text) {
            if ($sLine.Length -gt $iResult) {
                $iResult = $sLine.Length
            }
        }
        return $iResult + $this.SeparatorLocation + $this.HeaderSeparator.Length
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "IsDynamicObject" -Value {
        return $false
    }

    return $hResult
}
