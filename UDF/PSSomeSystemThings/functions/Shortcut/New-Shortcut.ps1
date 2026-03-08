function New-Shortcut {
    <#
    .SYNOPSIS
        Creates a new Windows shortcut (.lnk) file

    .DESCRIPTION
        Uses WScript.Shell COM object to create a shortcut with the specified target,
        arguments, icon, and window style. Supports credential elevation.

    .PARAMETER TargetExe
        The target executable path.

    .PARAMETER ArgumentsToExe
        Command-line arguments for the target.

    .PARAMETER DestinationPath
        Full path for the new .lnk file.

    .PARAMETER Icon
        Icon location string (e.g., "app.exe,0").

    .PARAMETER Credential
        Credentials to use when creating the shortcut.

    .PARAMETER WindowStyle
        Window style: 1 (Normal), 3 (Maximized), 7 (Minimized). Default: -1 (not set).

    .OUTPUTS
        None. Creates the shortcut file.

    .EXAMPLE
        New-Shortcut -TargetExe "C:\App\app.exe" -DestinationPath "C:\Users\Public\Desktop\App.lnk"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    Param(
        [Parameter(Mandatory)]
        [string]$TargetExe,
        [string]$ArgumentsToExe,
        [Parameter(Mandatory)]
        [string]$DestinationPath,
        [string]$Icon,
        [pscredential]$Credential,
        [int]$WindowStyle = -1
    )
    $sb = {
        $TargetExe = $args[0]
        $ArgumentsToExe = $args[1]
        $DestinationPath = $args[2]
        $Icon = $args[3]
        $WindowStyle = $args[4]
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($DestinationPath)
        $Shortcut.TargetPath = $TargetExe
        $Shortcut.Arguments = $ArgumentsToExe
        $Shortcut.IconLocation = $Icon
        if ($WindowStyle -in @(1, 3, 7)) {
            $Shortcut.WindowStyle = $WindowStyle
        }
        $Shortcut.Save()
    }
    if ($Credential) {
        Invoke-Command -ScriptBlock $sb -ComputerName $env:COMPUTERNAME -Credential $Credential -ArgumentList @($TargetExe, $ArgumentsToExe, $DestinationPath, $Icon, $WindowStyle)
    } else {
        Invoke-Command -ScriptBlock $sb -ArgumentList @($TargetExe, $ArgumentsToExe, $DestinationPath, $Icon, $WindowStyle)
    }
}