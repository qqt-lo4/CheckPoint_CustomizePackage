function Get-ScriptDir {
    Param(
        [Parameter(ParameterSetName = "input", Mandatory)]
        [switch]$InputDir,
        [Parameter(ParameterSetName = "output", Mandatory)]
        [switch]$OutputDir,
        [Parameter(ParameterSetName = "working_dir", Mandatory)]
        [switch]$WorkingDir,
        [Parameter(ParameterSetName = "tools", Mandatory)]
        [switch]$ToolsDir,
        [Parameter(ParameterSetName = "tools", Mandatory)]
        [string]$ToolName,
        [switch]$FullPath
    )
    Begin {
        function Get-RootScriptPath {
            Param(
                [switch]$FullPath
            )
            $scriptCallStack = Get-PSCallStack | Where-Object { $_.Command -ne '<ScriptBlock>' } 
            $rootScriptFullPath = $scriptCallStack[-1].InvocationInfo.InvocationName
            $rootScriptName = $scriptCallStack[-1].InvocationInfo.MyCommand.Name
            $sResult = if (($rootScriptFullPath.Length - $rootScriptName.Length) -lt 0) {
                ""
            } else {
                $rootScriptFullPath.Remove($rootScriptFullPath.Length - $rootScriptName.Length)
            }
            if ($FullPath.IsPresent) {
                if ($sResult -eq "") {
                    (Resolve-Path -Path ".").Path
                } else {
                    (Resolve-Path -Path $sResult).Path
                }
            } else {
                return $sResult
            }
        }

        function Get-RootScriptName {
            Param(
                [switch]$appendExtension
            )
            $scriptCallStack = Get-PSCallStack | Where-Object { $_.Command -ne '<ScriptBlock>' } 
            if ($appendExtension.IsPresent) {
                return $scriptCallStack[-1].Command
            } else {
                return $scriptCallStack[-1].Command.Split(".")[0]
            }
        }    
        
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
        $sRootPath = Get-RootScriptPath -FullPath
        $sResult = $sRootPath + "\" + $PSCmdlet.ParameterSetName 
        if ($PSCmdlet.ParameterSetName -eq "tools") {
            $sResult += "\" + $ToolName
        }
        if (Test-Path ($sRootPath + "\.devfolder")) {
            $sResult = switch ($PSCmdlet.ParameterSetName) {
                "tools" { $sResult } 
                default {$sResult + "\" + (Get-RootScriptName)}
            }
        }
        if ($FullPath.IsPresent) {
            return $sResult
        } else {
            return (Resolve-RelativePath -From $sRootPath -To $sResult)
        }
    }
    End {}
}