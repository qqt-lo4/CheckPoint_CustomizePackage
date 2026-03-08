function Get-FunctionParameters {
    <#
    .SYNOPSIS
        Retrieves parameters from the calling function with their current values.
    
    .DESCRIPTION
        This function extracts all parameters from its caller function, including:
        - Parameters explicitly passed by the user (from $PSBoundParameters)
        - Parameters with default values (extracted from the function's AST)
        
        It supports parameter renaming, filtering, and special handling of SecureString values.
        Works correctly within PowerShell modules by using the call stack and AST parsing.
        
        Common parameters (Verbose, Debug, etc.) are automatically excluded from the result.
    
    .PARAMETER RemoveParam
        Array of parameter names to exclude from the result.
        Use this to remove function-specific parameters that shouldn't be passed to APIs.
    
    .PARAMETER RenameParam
        Hashtable mapping original parameter names to new names.
        Example: @{OldName = 'NewName'}
    
    .PARAMETER SecureStringHandling
        Specifies how to handle SecureString parameters:
        - PlainText: Convert to plain text (default)
        - Masked: Replace with '***SECURE***'
        - Removed: Exclude from results
        - Base64: Convert to Base64-encoded string
    
    .EXAMPLE
        function Invoke-APICall {
            Param(
                [string]$Endpoint = "https://api.example.com",
                [string]$ApiKey,
                [int]$Timeout = 30,
                [string]$LogFile
            )
            
            # Remove LogFile as it's not needed for the API call
            $params = Get-FunctionParameters -RemoveParam 'LogFile'
        }
        
        Invoke-APICall -ApiKey "secret" -LogFile "C:\log.txt"
        # Returns: @{Endpoint="https://api.example.com"; ApiKey="secret"; Timeout=30}
    
    .EXAMPLE
        function Test-Rename {
            Param(
                [string]$LocalPath = "C:\temp",
                [string]$ApiKey
            )
            
            # Rename LocalPath to match API parameter name 'path'
            $params = Get-FunctionParameters -RenameParam @{LocalPath = 'path'}
        }
        
        Test-Rename -ApiKey "secret"
        # Returns: @{path="C:\temp"; ApiKey="secret"}
    
    .EXAMPLE
        function Connect-Service {
            Param(
                [string]$Server = "localhost",
                [SecureString]$Password
            )
            
            # Convert SecureString to plain text for API call
            $params = Get-FunctionParameters -SecureStringHandling PlainText
        }
        
        $secPass = ConvertTo-SecureString "MySecret" -AsPlainText -Force
        Connect-Service -Password $secPass
        # Returns: @{Server="localhost"; Password="MySecret"}
    
    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
        Based on: https://gist.github.com/Jaykul/72f30dce2cca55e8cd73e97670db0b09/

        This function uses AST (Abstract Syntax Tree) parsing to extract default parameter values,
        which allows it to work correctly even when called from within a PowerShell module where
        scope isolation would otherwise prevent access to the caller's variables.

        Common parameters (Verbose, Debug, ErrorAction, etc.) are automatically excluded.
    
    .OUTPUTS
        System.Collections.Hashtable
        Returns a hashtable containing parameter names and their values.
    #>
    
    Param(
        [Parameter(Position = 0)]
        [string[]]$RemoveParam,
        
        [Parameter(Position = 1)]
        [hashtable]$RenameParam = @{},

        [Parameter()]
        [ValidateSet("PlainText", "Masked", "Removed", "Base64")]
        [string]$SecureStringHandling = "PlainText"
    )
    
    Begin {
        function ConvertFrom-SecureStringToPlainText {
            param(
                [Parameter(Mandatory)]
                [System.Security.SecureString]$SecureString
            )
            
            # PSCredential method - works on ALL platforms
            try {
                $credential = New-Object System.Management.Automation.PSCredential("dummy", $SecureString)
                return $credential.GetNetworkCredential().Password
            }
            catch {
                Write-Warning "SecureString conversion error: $_"
                return $null
            }
        }

        function Get-ParameterDefaultValue {
            <#
            .SYNOPSIS
                Extracts the default value of a parameter from a ScriptBlock's AST.
            #>
            param(
                [Parameter(Mandatory)]
                $ScriptBlock,
                [Parameter(Mandatory)]
                [string]$ParameterName
            )
            
            try {
                $ast = $ScriptBlock.Ast
                
                # Find all parameter blocks
                $paramBlocks = $ast.FindAll({
                    param($node)
                    $node -is [System.Management.Automation.Language.ParameterAst]
                }, $true)
                
                # Find the specific parameter
                $targetParam = $paramBlocks | Where-Object { 
                    $_.Name.VariablePath.UserPath -eq $ParameterName 
                }
                
                if ($null -ne $targetParam -and $null -ne $targetParam.DefaultValue) {
                    # Extract the default value
                    $defaultValueAst = $targetParam.DefaultValue
                    
                    # Extract value based on AST type
                    switch ($defaultValueAst.GetType().Name) {
                        "StringConstantExpressionAst" {
                            return $defaultValueAst.Value
                        }
                        "ConstantExpressionAst" {
                            return $defaultValueAst.Value
                        }
                        "ArrayLiteralAst" {
                            return $defaultValueAst.SafeGetValue()
                        }
                        "HashtableAst" {
                            return $defaultValueAst.SafeGetValue()
                        }
                        default {
                            try {
                                return $defaultValueAst.SafeGetValue()
                            }
                            catch {
                                Write-Verbose "Unable to extract default value for $ParameterName : $_"
                                return $null
                            }
                        }
                    }
                }
                
                return $null
            }
            catch {
                Write-Verbose "Error extracting default value for ${ParameterName}: $_"
                return $null
            }
        }

        function Get-ParameterSetName {
            <#
            .SYNOPSIS
                Determines which parameter set is being used based on bound parameters.
            #>
            Param(
                [Parameter(Mandatory)]
                [object]$Invocation,
                [Parameter(Mandatory)]
                [hashtable]$BoundParameters
            )
            $aParameterSetsResults = @()
            foreach ($parameterset in $Invocation.ParameterSets) {
                # Get bound parameters excluding common parameters
                $oCompareLeft = ([string[]]$BoundParameters.Keys | Where-Object { 
                    ($_ -notin [System.Management.Automation.Cmdlet]::CommonParameters) -and `
                    ($_ -notin [System.Management.Automation.Cmdlet]::OptionalCommonParameters)
                })
                
                # Get parameters from the set that are mandatory or were specified
                $oCompareRight = ($parameterset.Parameters | Where-Object { 
                    $_.IsMandatory -or (($oCompareLeft -ne $null) -and (-not $_.IsMandatory) -and ($_.name -in $oCompareLeft)) 
                }).Name
                
                # Compare parameter sets
                $bothNull = ($null -eq $oCompareLeft) -and ($null -eq $oCompareRight)
                $bothExist = ($null -ne $oCompareLeft) -and ($null -ne $oCompareRight)
                if ($bothNull) {
                    $aParameterSetsResults += $parameterset.Name
                } elseif ($bothExist) {
                    if ((Compare-Object $oCompareLeft $oCompareRight) -eq $null) {
                        $aParameterSetsResults += $parameterset.Name
                    }
                }
            }
            
            # Return the matched parameter set or the default one
            if ($aParameterSetsResults.Count -eq 1) {
                $sResult = $aParameterSetsResults[0]
                return $sResult
            } else {
                return ($Invocation.ParameterSets | Where-Object { $_.IsDefault -eq $true }).Name
            }
        }
        
        # Get the calling function's invocation info
        $parentInvocation = (Get-PSCallStack)[1].InvocationInfo
        
        # Get the bound parameters from the caller
        $CallerBoundParameters = $parentInvocation.BoundParameters
        
        # Determine which parameter set is being used
        $sParameterSetName = Get-ParameterSetName -Invocation $parentInvocation.MyCommand -BoundParameters $CallerBoundParameters
    }
    
    Process {
        $hResultAPIParameters = @{}
        $aParameterSet = $parentInvocation.MyCommand.ParameterSets | Where-Object { $_.Name -eq $sParameterSetName }
        
        # Iterate through all parameters in the active parameter set
        foreach($parameter in $aParameterSet.Parameters.GetEnumerator()) {
            try {
                $key = $parameter.Name
                $value = $null
                
                # PRIORITY 1: Check if parameter was explicitly passed
                if($CallerBoundParameters.ContainsKey($key)) {
                    $value = $CallerBoundParameters[$key]
                }
                # PRIORITY 2: Extract default value from AST
                elseif ($null -ne $parentInvocation.MyCommand.ScriptBlock) {
                    $defaultValue = Get-ParameterDefaultValue -ScriptBlock $parentInvocation.MyCommand.ScriptBlock -ParameterName $key
                    if ($null -ne $defaultValue) {
                        $value = $defaultValue
                    }
                }
                
                # Only add if we have a value
                if($null -ne $value) {
                    #if($value -ne ($null -as $parameter.ParameterType)) {
                        $hResultAPIParameters[$key] = $value
                    #}
                }
            }
            finally {}
        }
        
        # Convert types and apply transformations
        $hNewResultAPIParameters = @{}
        foreach ($item in $hResultAPIParameters.Keys) {
            # Apply renaming if specified
            $newKey = if ($RenameParam.ContainsKey($item)) { $RenameParam[$item] } else { $item }
            $itemValue = $hResultAPIParameters[$item]
            
            if ($null -eq $itemValue) {
                $hNewResultAPIParameters[$item] = $null
            } else {
                switch ($itemValue.GetType().Name) {
                    "SwitchParameter" {
                        # Convert SwitchParameter to boolean
                        $hNewResultAPIParameters[$newKey] = [bool]$itemValue
                    }
                    "SecureString" {
                        # Handle SecureString based on specified method
                        switch ($SecureStringHandling) {
                            "PlainText" {
                                $plainText = ConvertFrom-SecureStringToPlainText -SecureString $itemValue
                                if ($null -ne $plainText) {
                                    $hNewResultAPIParameters[$newKey] = $plainText
                                }
                            }
                            "Masked" {
                                $hNewResultAPIParameters[$newKey] = "***SECURE***"
                            }
                            "Removed" {
                                # Don't include in output
                            }
                            "Base64" {
                                $plainText = ConvertFrom-SecureStringToPlainText -SecureString $itemValue
                                if ($null -ne $plainText) {
                                    $bytes = [System.Text.Encoding]::UTF8.GetBytes($plainText)
                                    $hNewResultAPIParameters[$newKey] = [System.Convert]::ToBase64String($bytes)
                                }
                            }
                        }
                    }
                    default {
                        $hNewResultAPIParameters[$newKey] = $itemValue
                    }
                }    
            }
        }
        
        # Remove specified parameters
        foreach ($item in $RemoveParam) {
            $hNewResultAPIParameters.Remove($item) | Out-Null
        }
    }
    
    End {
        return $hNewResultAPIParameters
    }
}

# function Get-FunctionParameters {
#     # based on https://gist.github.com/Jaykul/72f30dce2cca55e8cd73e97670db0b09/
#     Param(
#         [Parameter(Position = 0)]
#         [string[]]$RemoveParam,
        
#         [Parameter(Position = 1)]
#         [hashtable]$RenameParam = @{},  # Nouveau paramètre

#         [ValidateSet("Hashtable", "Json", "PSCustomObject", "QueryString")]
#         [string]$OutputFormat = "Hashtable",
#         [Parameter()]
#         [ValidateSet("PlainText", "Masked", "Removed", "Base64")]
#         [string]$SecureStringHandling = "PlainText"
#     )
#     Begin {
#         function ConvertFrom-SecureStringToPlainText {
#             param(
#                 [Parameter(Mandatory)]
#                 [System.Security.SecureString]$SecureString
#             )
            
#             # Méthode PSCredential - fonctionne sur TOUTES les plateformes
#             try {
#                 $credential = New-Object System.Management.Automation.PSCredential("dummy", $SecureString)
#                 return $credential.GetNetworkCredential().Password
#             }
#             catch {
#                 Write-Warning "Erreur de conversion SecureString: $_"
#                 return $null
#             }
#         }

#         function Get-ParameterSetName {
#             Param(
#                 [Parameter(Mandatory)]
#                 [object]$Invocation,
#                 [Parameter(Mandatory)]
#                 [hashtable]$BoundParameters
#             )
#             $aParameterSetsResults = @()
#             foreach ($parameterset in $Invocation.ParameterSets) {
#                 $oCompareLeft = ([string[]]$BoundParameters.Keys | Where-Object { 
#                     ($_ -notin [System.Management.Automation.Cmdlet]::CommonParameters) -and `
#                     ($_ -notin [System.Management.Automation.Cmdlet]::OptionalCommonParameters)
#                 })
#                 # Need to check parameters on right that are not mandatory, and remove them from right if not specified on left
#                 $oCompareRight = ($parameterset.Parameters | Where-Object { $_.IsMandatory -or (($oCompareLeft -ne $null) -and (-not $_.IsMandatory) -and ($_.name -in $oCompareLeft)) }).Name
#                 # Compare
#                 # if (-not ((($oCompareLeft -eq $null) -and ($oCompareRight -ne $null)) -or `
#                 #     (($oCompareLeft -ne $null) -and ($oCompareRight -eq $null)))) {
#                 #     if (($oCompareLeft -eq $null) -and ($oCompareRight -eq $null)) {
#                 #         $aParameterSetsResults += $parameterset.Name
#                 #     } else {
#                 #         if ((Compare-Object $oCompareLeft $oCompareRight) -eq $null) {
#                 #             $aParameterSetsResults += $parameterset.Name
#                 #         }    
#                 #     }
#                 # }
#                 $bothNull = ($null -eq $oCompareLeft) -and ($null -eq $oCompareRight)
#                 $bothExist = ($null -ne $oCompareLeft) -and ($null -ne $oCompareRight)
#                 if ($bothNull) {
#                     $aParameterSetsResults += $parameterset.Name
#                 } elseif ($bothExist) {
#                     if ((Compare-Object $oCompareLeft $oCompareRight) -eq $null) {
#                         $aParameterSetsResults += $parameterset.Name
#                     }
#                 }
#             }
#             if ($aParameterSetsResults.Count -eq 1) {
#                 $sResult = $aParameterSetsResults[0]
#                 return $sResult
#             } else {
#                 return ($Invocation.ParameterSets | Where-Object { $_.IsDefault -eq $true }).Name
#             }
#         }
#         $parentInvocation = (Get-PSCallStack)[1].InvocationInfo
#         $BoundParameters = (Get-PSCallStack)[1].InvocationInfo.BoundParameters
#         $sParameterSetName = Get-ParameterSetName -Invocation $parentInvocation.MyCommand -BoundParameters $BoundParameters -Verbose
#     }
#     Process {
#         $hResultAPIParameters = @{}
#         $aParameterSet = $parentInvocation.MyCommand.ParameterSets | Where-Object { $_.Name -eq $sParameterSetName }
#         foreach($parameter in $aParameterSet.Parameters.GetEnumerator()) {
#             try {
#                 $key = $parameter.Name
#                 $value = Get-Variable -Name $key -ValueOnly -ErrorAction Ignore -Scope 1
#                 if($null -ne $value) {
#                     if($value -ne ($null -as $parameter.ParameterType)) {
#                         $hResultAPIParameters[$key] = $value
#                     }
#                 }
#                 if($BoundParameters.ContainsKey($key)) {
#                     $hResultAPIParameters[$key] = $BoundParameters[$key]
#                 }
#             }
#             finally {}
#         }
#         # convert types
#         $hNewResultAPIParameters = @{}
#         foreach ($item in $hResultAPIParameters.Keys) {
#             $newKey = if ($RenameParam.ContainsKey($item)) { $RenameParam[$item] } else { $item }
#             $itemValue = $hResultAPIParameters[$item]
#             if ($null -eq $itemValue) {
#                 $hNewResultAPIParameters[$item] = $null
#             } else {
#                 switch ($itemValue.GetType().Name) {
#                     "SwitchParameter" {
#                         $hNewResultAPIParameters[$newKey] = [bool]$itemValue
#                     }
#                     "SecureString" {
#                         switch ($SecureStringHandling) {
#                             "PlainText" { # Convertir en texte clair pour l'API
#                                 $plainText = ConvertFrom-SecureStringToPlainText -SecureString $itemValue
#                                 if ($null -ne $plainText) {
#                                     $hNewResultAPIParameters[$newKey] = $plainText
#                                 }
#                             }
#                             "Masked" { # Remplacer par une valeur masquée
#                                 $hNewResultAPIParameters[$newKey] = "***SECURE***"
#                             }
#                             "Removed" { # Ne pas inclure dans les paramètres de sortie, en ne faisant rien
                                
#                             }
#                             "Base64" { # Convertir en Base64 
#                                 $plainText = ConvertFrom-SecureStringToPlainText -SecureString $itemValue
#                                 if ($null -ne $plainText) {
#                                     $bytes = [System.Text.Encoding]::UTF8.GetBytes($plainText)
#                                     $hNewResultAPIParameters[$newKey] = [System.Convert]::ToBase64String($bytes)
#                                 }
#                             }
#                         }
#                     }
#                     default {
#                         $hNewResultAPIParameters[$newKey] = $itemValue
#                     }
#                 }    
#             }
#         }
#         # remove all useless parameters
#         foreach ($item in $RemoveParam) {
#             $hNewResultAPIParameters.Remove($item) | Out-Null
#         }
#     }
#     End {
#         switch ($OutputFormat) {
#             "hashtable" {
#                 return $hNewResultAPIParameters
#             }
#             "Json" {
#                 return $hNewResultAPIParameters | ConvertTo-Json
#             }
#             "PSCustomObject" {
#                 return [pscustomobject]$hNewResultAPIParameters
#             }
#             "QueryString" {
#                 $queryParts = @()
#                 foreach ($param in $hNewResultAPIParameters.GetEnumerator()) {
#                     if ($null -ne $param.Value) {
#                         $key = [System.Web.HttpUtility]::UrlEncode($param.Key)
#                         $value = [System.Web.HttpUtility]::UrlEncode($param.Value.ToString())
#                         $queryParts += "$key=$value"
#                     }
#                 }
#                 return $queryParts -join '&'
#             }
#         }
#     }
# }

