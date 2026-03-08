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

    .PARAMETER FullPath
        Return the full absolute path instead of relative.

    .OUTPUTS
        [String]. Directory path.

    .EXAMPLE
        $inputDir = Get-ScriptDir -InputDir

    .EXAMPLE
        $toolsDir = Get-ScriptDir -ToolsDir -ToolName "7zip"

    .NOTES
        Author  : Loïc Ade
        Version : 1.2.0

        1.0.0 - First version
        1.1.0 (2026-03-05)
            - Corrected bugs of Get-RootScriptPath
            - Removes -FullPath parameter (always returns full path)
        1.2.0 (2026-03-08)
            - InputDir, OutputDir and WorkingDir can be overridden by root script parameters
            - ParameterSetNames renamed to match parameter names
            - Folder name derived from ParameterSetName
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
        function Resolve-RelativePath {
            Param(
                [string]$From,
                [string]$To
            )
            $oLocationBefore = Get-Location
            Set-Location $From 
            Resolve-Path -Path $To -Relative
            Set-Location $oLocationBefore
        }
    }
    Process {
        $sRootPath = Get-RootScriptPath

        if ($InputDir -or $OutputDir -or $WorkingDir) {
            $rootArgs = Get-RootScriptArguments
            if (-not [string]::IsNullOrEmpty($rootArgs[$PSCmdlet.ParameterSetName]) -and (Test-Path $rootArgs[$PSCmdlet.ParameterSetName] -PathType Container)) {
                return $rootArgs[$PSCmdlet.ParameterSetName]
            }
        }

        $sFolderName = $PSCmdlet.ParameterSetName -replace 'Dir$', ''
        $sFolderName = $sFolderName.Substring(0, 1).ToLower() + $sFolderName.Substring(1)
        $sResult = $sRootPath + "\" + $sFolderName
        if ($PSCmdlet.ParameterSetName -eq "ToolsDir") {
            $sResult += "\" + $ToolName
        }
        if (Test-Path ($sRootPath + "\.devfolder")) {
            $sResult = switch ($PSCmdlet.ParameterSetName) {
                "ToolsDir" { $sResult }
                default {$sResult + "\" + (Get-RootScriptName)}
            }
        }
        return $sResult
    }
    End {}
}