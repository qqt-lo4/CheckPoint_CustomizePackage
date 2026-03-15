function Get-ScriptDir {
    <#
    .SYNOPSIS
        Gets application directories (input, output, working, or tools)

    .DESCRIPTION
        Returns the path to a standard application subfolder relative to the root script.
        Supports dev folder structure detection for organized project layouts.

    .PARAMETER InputDir
        Return the input directory path.

    .PARAMETER OutputDir
        Return the output directory path.

    .PARAMETER WorkingDir
        Return the working directory path.

    .PARAMETER ToolsDir
        Return the tools directory path (requires ToolName).

    .PARAMETER ToolName
        Name of the tool subfolder under tools.

    .OUTPUTS
        [String]. Directory path.

    .EXAMPLE
        $inputDir = Get-ScriptDir -InputDir

    .EXAMPLE
        $toolsDir = Get-ScriptDir -ToolsDir -ToolName "7zip"

    .NOTES
        Author  : Loïc Ade
        Version : 1.3.0

        1.0.0 - First version
        1.1.0 (2026-03-05)
            - Corrected bugs of Get-RootScriptPath
            - Removes -FullPath parameter (always returns full path)
        1.2.0 (2026-03-08)
            - InputDir, OutputDir and WorkingDir can be overridden by root script parameters
            - ParameterSetNames renamed to match parameter names
            - Folder name derived from ParameterSetName
        1.3.0 (2026-03-10)
            - Uses Get-RootScriptInfo instead of Get-RootScriptPath, Get-RootScriptName and Get-RootScriptArguments
    #>

    Param(
        [Parameter(ParameterSetName = "InputDir", Mandatory)]
        [switch]$InputDir,
        [Parameter(ParameterSetName = "OutputDir", Mandatory)]
        [switch]$OutputDir,
        [Parameter(ParameterSetName = "WorkingDir", Mandatory)]
        [switch]$WorkingDir,
        [Parameter(ParameterSetName = "ToolsDir", Mandatory)]
        [switch]$ToolsDir,
        [Parameter(ParameterSetName = "ToolsDir", Mandatory)]
        [string]$ToolName
    )
    Begin {
        $rootInfo = Get-RootScriptInfo
    }
    Process {
        if ($InputDir -or $OutputDir -or $WorkingDir) {
            $sRootArgValue = $rootInfo.Arguments[$PSCmdlet.ParameterSetName]
            if (-not [string]::IsNullOrEmpty($sRootArgValue) -and (Test-Path $sRootArgValue -PathType Container)) {
                return $sRootArgValue
            }
        }

        $sFolderName = $PSCmdlet.ParameterSetName -replace 'Dir$', ''
        $sFolderName = $sFolderName.Substring(0, 1).ToLower() + $sFolderName.Substring(1)
        $sResult = $rootInfo.Directory + "\" + $sFolderName
        if ($PSCmdlet.ParameterSetName -eq "ToolsDir") {
            $sResult += "\" + $ToolName
        }
        if (Test-Path ($rootInfo.Directory + "\.devfolder")) {
            $sResult = switch ($PSCmdlet.ParameterSetName) {
                "ToolsDir" { $sResult }
                default {$sResult + "\" + $rootInfo.Name}
            }
        }
        return $sResult
    }
    End {}
}