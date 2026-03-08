function Add-PathToEnvironment {
    <#
    .SYNOPSIS
        Adds a directory path to the system or user PATH environment variable

    .DESCRIPTION
        Safely adds a directory to the PATH environment variable if it's not already present.
        Handles both Machine (system-wide) and User scope.

    .PARAMETER Path
        The directory path to add to PATH

    .PARAMETER Scope
        Environment variable scope: "Machine" (system-wide) or "User"

    .OUTPUTS
        Returns $true if path was added or already exists, $false on error

    .EXAMPLE
        Add-PathToEnvironment -Path "C:\Program Files\MyApp\bin" -Scope "Machine"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [ValidateSet("Machine", "User")]
        [string]$Scope
    )

    try {
        # Normalize the path (remove trailing backslash if present)
        $Path = $Path.TrimEnd('\')

        # Get current PATH value
        $currentPath = [Environment]::GetEnvironmentVariable("Path", $Scope)

        if ([string]::IsNullOrEmpty($currentPath)) {
            Write-Verbose "PATH variable is empty, creating new one with: $Path"
            [Environment]::SetEnvironmentVariable("Path", $Path, $Scope)
            return $true
        }

        # Check if path already exists (case-insensitive)
        $pathEntries = $currentPath -split ';' | Where-Object { $_ -ne '' }
        $pathExists = $pathEntries | Where-Object { $_.TrimEnd('\') -ieq $Path }

        if ($pathExists) {
            Write-Verbose "Path already exists in $Scope PATH: $Path"
            return $true
        }

        # Add the new path
        Write-Verbose "Adding to $Scope PATH: $Path"
        $newPath = $currentPath.TrimEnd(';') + ';' + $Path
        [Environment]::SetEnvironmentVariable("Path", $newPath, $Scope)

        Write-Host "  Added to PATH: $Path" -ForegroundColor Green

        # Notify the system of the environment variable change
        # This broadcasts a message to all windows to refresh their environment
        if ($Scope -eq "Machine") {
            $HWND_BROADCAST = [IntPtr]0xffff
            $WM_SETTINGCHANGE = 0x1a
            $result = 0

            if (-not ([System.Management.Automation.PSTypeName]'Win32.NativeMethods').Type) {
                Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @"
                    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
                    public static extern IntPtr SendMessageTimeout(
                        IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
                        uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
"@
            }

            $result = [UIntPtr]::Zero
            [Win32.NativeMethods]::SendMessageTimeout(
                $HWND_BROADCAST,
                $WM_SETTINGCHANGE,
                [UIntPtr]::Zero,
                "Environment",
                2,      # SMTO_ABORTIFHUNG
                5000,
                [ref]$result
            ) | Out-Null
        }

        return $true

    } catch {
        Write-Warning "Failed to add path to $Scope PATH: $_"
        return $false
    }
}
