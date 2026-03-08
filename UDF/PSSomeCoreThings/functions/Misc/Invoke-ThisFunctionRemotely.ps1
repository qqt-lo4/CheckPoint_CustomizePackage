function Invoke-ThisFunctionRemotely {
    <#
    .SYNOPSIS
        This function allows remote execution of the caller function
    .DESCRIPTION
        This function allows remote execution of the caller function
        It will write the caller function code, add all functions of $ImportFunctions array and 
        add "Add-Type" in the written function that will be executed remotely
        It uses a PSSession variable or a ComputerName and Credential variable to connect remotely
        This way you can add remote execution features to a function with 3 parameter variables and 
        around 3 lines of code
    .NOTES
        Author  : Loïc Ade
        Version : 1.1.0

        Version History:
        1.0 - First version
        1.1 - Changed function parameters so $ThisFunctionName and
              $ThisFunctionParameters are no longer mandatory
    .PARAMETER $ThisFunctionName
        No longer used, kept for compatibility. Get-PSCallStack is used to get the 
        caller function name (the function that needs to be executed remotely)
    .PARAMETER $ThisFunctionParameters
        No longer used, kept for compatibility. Get-PSCallStack is used to get the caller $PSBoundParameter variable
        This variable is used to rewrite the function for remote execution
        The function uses $ThisFunctionParameters as the first argument to call the remote function. 
        It will be passed as an argument to the main function 
    .PARAMETER $ImportFunctions
        The caller function may call functions that are imported separately
        Get-FunctionCode will be used to append imported functions in $ImportFunctions to 
        the remotely executed code
    .EXAMPLE
        The following example has $Session, $CopmputerName and $Credential variables
        They are sent to Invoke-ThisFunctionRemotely so if these variables are 
        present, Get-PSDrive will be executed on the remote computer

        function Get-PSDrive {
            [CmdletBinding(DefaultParameterSetName="Name")]
            Param(
                [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = "Name")]
                [ValidateNotNullOrEmpty()]
                [string[]]$Name,

                [Parameter(ValueFromPipelineByPropertyName)]
                [string]$Scope,

                [Parameter(ValueFromPipelineByPropertyName)]
                [string[]]$PSProvider,

                [Alias("usetx")]
                [switch]$UseTransaction,

                [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = "LiteralName")]
                [string[]]$LiteralName,

                [string]$ComputerName,
                [pscredential]$Credential,
                [System.Management.Automation.Runspaces.PSSession]$Session
            )

            if ($ComputerName -or $Session) {
                Invoke-ThisFunctionRemotely
            } else {
                Microsoft.PowerShell.Management\Get-PSDrive @PSBoundParameters
            }
        }
    #>
    
    [CmdletBinding()]
    Param(
        [string]$ThisFunctionName,
        [object]$ThisFunctionParameters,
        [string[]]$ImportFunctions,
        [string[]]$AddTypeAssemblyName,
        [switch]$AddRemoteParamToResult
    )
    Begin {
        $sThisFunctionName = if ($ThisFunctionName) {
            $ThisFunctionName
        } else {
            (Get-PSCallStack)[1].InvocationInfo.InvocationName
        }
        $oThisFunctionParameters = if ($ThisFunctionParameters) {
            $ThisFunctionParameters
        } else {
            (Get-PSCallStack)[1].InvocationInfo.BoundParameters
        }
        if ($oThisFunctionParameters.ContainsKey("ComputerName") -and $oThisFunctionParameters.ContainsKey("Session")) {
            throw [System.ArgumentException] "You can't use -ComputerName and -Session arguments at the same time"
        }
        if ($oThisFunctionParameters.ContainsKey("Credential") -and $oThisFunctionParameters.ContainsKey("Session")) {
            throw [System.ArgumentException] "You can't use -Credential and -Session arguments at the same time"
        }
    }
    Process {
        $func = Get-FunctionCode $sThisFunctionName
        if ($func) {
            # Build script block to execute remotely
            $stringSB = @"
    `$thisFunctionParams = `$args[0]
    
"@
            foreach ($assembly in $AddTypeAssemblyName) {
                $stringSB += "Add-Type -AssemblyName $assembly" + "`n"
            }
            if ($AddTypeAssemblyName) {
                $stringSB += "`n"
            }
    
            foreach ($f in $ImportFunctions) {
                $includedFunc = Get-FunctionCode $f 
                $stringSB += $includedFunc + "`n"
            }
            $stringSB += $func + "`n"
            $stringSB += @"
    return $sThisFunctionName @thisFunctionParams
"@      
            $sb = [System.Management.Automation.ScriptBlock]::Create($stringSB)
            $result = @()
            if ($oThisFunctionParameters.ContainsKey("ComputerName")) {
                $remoteParams = @{}
                if ($oThisFunctionParameters.ContainsKey("Credential")) {
                    $remoteParams.Add("Credential", $oThisFunctionParameters["Credential"]) | Out-Null
                    $oThisFunctionParameters.Remove("Credential") | Out-Null
                }
                foreach ($computer in $oThisFunctionParameters["ComputerName"]) {
                    $remoteParams.Add("ComputerName", $computer) | Out-Null
                    $oThisFunctionParameters.Remove("ComputerName") | Out-Null
                    $result += Invoke-Command @remoteParams -ScriptBlock $sb -ArgumentList @($oThisFunctionParameters)
                }
            }
            if ($oThisFunctionParameters.ContainsKey("Session")) {
                foreach ($pssession in $oThisFunctionParameters["Session"]) {
                    $remoteParams = @{}
                    if ($pssession.State -ne "Opened") {
                        throw [System.InvalidOperationException] ("Session to " + $pssession.ComputerName + " is in state " + $pssession.State)
                    }
                    $remoteParams.Add("Session", $pssession) | Out-Null
                    $oThisFunctionParameters.Remove("Session") | Out-Null
                    $result += Invoke-Command @remoteParams -ScriptBlock $sb -ArgumentList @($oThisFunctionParameters)
                }
            }
            if ($result -and $AddRemoteParamToResult.IsPresent) {
                foreach ($item in $result) {
                    foreach ($key in $remoteParams.Keys) {
                        $item | Add-Member -NotePropertyName $key -NotePropertyValue $remoteParams[$key]
                    }
                }
            }
            return $result
        } else {
            throw [InvalidOperationException] "Function $sThisFunctionName not found"
        }    
    }
}
