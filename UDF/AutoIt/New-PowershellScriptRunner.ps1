function New-PowershellScriptRunner {
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
        Invoke-AutoItCompile -File $sAU3FilePath -X64
        if ($ExeFileName) {
            Rename-Item -Path ($sPS1FileName + ".exe") -NewName $ExeFileName
        }
        if (-not $DoNotRemoveAU3.IsPresent) {
            Remove-Item $sAU3FilePath
        }
    }
}
