function Get-ShortcutInfo {
    <#
    .SYNOPSIS
        Retrieves properties of a Windows shortcut (.lnk) file

    .DESCRIPTION
        Uses WScript.Shell COM object to read shortcut properties including target,
        arguments, working directory, icon, hotkey, and window style.

    .PARAMETER Path
        Full path to the .lnk shortcut file.

    .OUTPUTS
        [PSCustomObject]. Object with Target, Arguments, WorkingDirectory, Description, IconLocation, Hotkey, and WindowStyle.

    .EXAMPLE
        Get-ShortcutInfo -Path "C:\Users\Public\Desktop\MyApp.lnk"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    param([string]$Path)
    
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($Path)
    
    [PSCustomObject]@{
        Target = $shortcut.TargetPath
        Arguments = $shortcut.Arguments
        WorkingDirectory = $shortcut.WorkingDirectory
        Description = $shortcut.Description
        IconLocation = $shortcut.IconLocation
        Hotkey = $shortcut.Hotkey
        WindowStyle = $shortcut.WindowStyle
    }
}
