function New-CLIDialogSpace {
    Param(
        [Parameter(Position = 0)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Length = 1,
        [System.ConsoleColor]$Color = (Get-Host).UI.RawUI.BackgroundColor
    )
    $hResult = @{
        Type = "space"
        Length = $Length
        Color = $Color
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "Draw" -Value {
        Write-Host (" " * $this.Length) -NoNewline -BackgroundColor $this.Color
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetTextHeight" -Value {
        return 1
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetTextWidth" -Value {
        return $this.Length
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "IsDynamicObject" -Value {
        return $false
    }

    return $hResult
}
