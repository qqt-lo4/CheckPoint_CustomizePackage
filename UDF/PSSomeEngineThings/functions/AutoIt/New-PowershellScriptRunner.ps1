function New-PowershellScriptRunner {
    <#
    .SYNOPSIS
        Creates an AutoIt-based executable wrapper for a PowerShell script

    .DESCRIPTION
        Generates an AutoIt script that executes a PowerShell script, then compiles it to an executable.
        The resulting .exe can run the PowerShell script with custom arguments, admin rights, and optional icon.

    .PARAMETER PS1FileName
        Path to the PowerShell script file (.ps1) to wrap.

    .PARAMETER ExeFileName
        Optional custom name for the output executable. If not specified, uses script name + .exe.

    .PARAMETER RunAsAdmin
        If specified, the executable will request administrator privileges.

    .PARAMETER AddArguments
        Additional arguments to pass to the PowerShell script.

    .PARAMETER AdditionalArgumentsPasswordVariable
        Name of a variable containing password arguments to pass securely.

    .PARAMETER X64
        If specified, compiles as x64 executable instead of x86.

    .PARAMETER CUI
        If specified, creates a console application (CUI) instead of GUI.

    .PARAMETER Icon
        Path to an icon file (.ico) to embed in the executable.

    .PARAMETER DoNotRemoveAU3
        If specified, keeps the intermediate .au3 file after compilation.

    .PARAMETER Hashtable
        Hashtable for path variable resolution.

    .OUTPUTS
        None. Creates an executable file.

    .EXAMPLE
        New-PowershellScriptRunner -PS1FileName "C:\Scripts\MyScript.ps1" -Hashtable @{}

    .EXAMPLE
        New-PowershellScriptRunner -PS1FileName "C:\Scripts\Deploy.ps1" -RunAsAdmin -X64 -Icon "C:\Icons\app.ico" -Hashtable @{}

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$PS1FileName,
        [Parameter(Position = 1)]
        [string]$ExeFileName,
        [switch]$RunAsAdmin,
        [AllowEmptyString]
        [string]$AddArguments,
        [string]$AdditionalArgumentsPasswordVariable,
        [switch]$X64,
        [switch]$CUI,
        [string]$Icon,
        [switch]$DoNotRemoveAU3,
        [Parameter(Mandatory)]
        [hashtable]$Hashtable
    )
    Begin {
        function Convert-SwitchToYN {
            Param(
                [Parameter(Mandatory, Position = 0)]
                [bool]$SwitchValue
            )
            $sResult = if ($SwitchValue) { "y" } else { "n" }
            return $sResult
        }
        $sPS1FileName = Resolve-PathWithVariables -Path $PS1FileName -Hashtable $Hashtable
        $sIconFileName = if ($Icon) { Resolve-PathWithVariables -Path $Icon -Hashtable $Hashtable } else { $null }
        $sEXEFileName = if ($ExeFileName) { Resolve-PathWithVariables -Path $ExeFileName -Hashtable $Hashtable } else { $null }
    }
    Process {
        $hPath = Split-PathToHashTable $sPS1FileName
        $sResultScript = if ($RunAsAdmin.IsPresent) { "#RequireAdmin`n" } else { "" }
        $sResultScript += "#Region ;**** Directives created by AutoIt3Wrapper_GUI ****`n"
        $sResultScript += "#AutoIt3Wrapper_UseX64=$(Convert-SwitchToYN $X64.IsPresent)`n"
        $sResultScript += "#AutoIt3Wrapper_Change2CUI=$(Convert-SwitchToYN $CUI.IsPresent)`n"
        $sResultScript += "#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****`n`n"
        $sResultScript += "; Script Start - Add your code below here`n"
        $sResultScript += "`$scriptToRun = `"$($hPath.ItemName)`"`n"
        $sResultScript += "If (FileExists(@ScriptDir & ""\"" & `$scriptToRun)) Then`n"
        $sResultScript += "    ConsoleWrite(`"Run script `" & `$scriptToRun & @CRLF)`n"
        $sNewLine = "    `$returnCode = RunWait(`"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File """""" & @ScriptDir & ""\"" & `$scriptToRun & """""" """
        if ($AdditionalArgumentsPasswordVariable) {
            $sNewLine += " & ""$AdditionalArgumentsPasswordVariable"" & "" """
        }
        if ($AddArguments) {
            $sNewLine += " & ""$AddArguments"" & "" """
        }
        $sResultScript += $sNewLine + " & `$CmdLineRaw)`n"
        $sResultScript += "    Exit `$returnCode`n"
        $sResultScript += "Else`n"
        $sResultScript += "    ConsoleWrite(`"File not found`" & @CRLF)`n"
        $sResultScript += "EndIf`n"
        $sAU3FilePath = ($sPS1FileName + ".au3")
        $sResultScript | Out-File -Encoding utf8 -FilePath $sAU3FilePath
        $compileParams = @{ File = $sAU3FilePath; X64 = $X64 }
        if ($Icon) { $compileParams.Icon = $sIconFileName }
        Invoke-AutoItCompile @compileParams
        if ($ExeFileName) {
            Rename-Item -Path ($sPS1FileName + ".exe") -NewName $sEXEFileName
        }
        if (-not $DoNotRemoveAU3.IsPresent) {
            Remove-Item $sAU3FilePath
        }
    }
}
