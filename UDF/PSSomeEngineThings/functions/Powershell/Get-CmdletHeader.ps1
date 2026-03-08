function Get-CmdletHeader {
    <#
    .SYNOPSIS
        Generates a function header from a cmdlet definition

    .DESCRIPTION
        Creates a complete PowerShell function header including CmdletBinding attributes,
        parameters with all their attributes (Parameter, ValidateSet, ValidateRange, etc.),
        and proper formatting. Useful for creating proxy functions or wrappers.

    .PARAMETER CmdletName
        Name of the cmdlet to generate header from.

    .OUTPUTS
        [String]. Complete function header as PowerShell code.

    .EXAMPLE
        Get-CmdletHeader -CmdletName "Get-Process"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$CmdletName
    )

    function Convert-TypeToPowershellType {
        Param(
            [Parameter(Mandatory, Position = 0)]
            [object]$Type
        )
        switch ($Type.ToString()) {
            "System.String[]" {return "[string[]]"}
            "System.String" {return "[string]"}
            "System.Management.Automation.SwitchParameter" { return "[switch]" }
            default {
                if ($Type.ToString() -match "^[^.]+\.[^.]+$") {
                    return "[" + $Type.ToString().Split(".")[-1] + "]"
                } else {
                    return "[" + $Type.ToString() + "]"
                }                
            }
        }
    }
    
    function Convert-CmdletBindingAttributeToString {
        Param(
            [Parameter(Mandatory)]
            [bool]$SupportsCommonParameters,
            [Parameter(Mandatory)]
            [bool]$SupportsShouldProcess,
            [Parameter(Mandatory)]
            [AllowEmptyString()]
            [string]$DefaultParameterSetName
        )
        $aResult = @()
        if ($SupportShouldProcess) {
            $aResult += "SupportsShouldProcess=`$true"
        }
        if ($DefaultParameterSetName) {
            $aResult += "DefaultParameterSetName=""$DefaultParameterSetName"""
        }
        if ($aResult.Count -gt 0) {
            return "    [CmdletBinding(" + ($aResult -join '","') + ")]`n"
        } elseif ($SupportCommonParameters) {
            return "    [CmdletBinding()]`n"
        } else {
            return ""
        }
    }
    
    function Convert-ParameterSetMetaDataToString {
        Param(
            [AllowEmptyString()]
            [string]$ParameterSetName,
            [Parameter(Mandatory)]
            [object]$ParameterAttribute
        )
        $aResult = @()
        if ($ParameterAttribute.Position -gt 0) {
            $aResult += ("Position = " + $ParameterAttribute.Position)
        }
        if ($ParameterAttribute.IsMandatory) {
            $aResult += "Mandatory"
        }
        if ($ParameterAttribute.ValueFromPipeline) {
            $aResult += "ValueFromPipeline"
        }
        if ($ParameterAttribute.ValueFromPipelineByPropertyName) {
            $aResult += "ValueFromPipelineByPropertyName"
        }
        if ($ParameterAttribute.ValueFromRemainingArguments) {
            $aResult += "ValueFromRemainingArguments"
        }
        if ($ParameterAttribute.HelpMessage) {
            $aResult += ("HelpMessage = `"" + $ParameterAttribute.HelpMessage + "`"")
        }
        if ($ParameterSetName -ne "") {
            $aResult += "ParameterSetName = """ + $ParameterSetName + """"
        }
        if ($aResult) {
            return "[Parameter(" + ($aResult -join ", ") + ")]"
        }
    }
    
    function Convert-ParameterAttributesToString {
        Param(
            [Parameter(Mandatory, Position = 0)]
            [object]$ParameterAttributes
        )
        $sResult = ""
        foreach ($oAttribute in $ParameterAttributes) {
            if ($oAttribute -is [System.Management.Automation.ValidateRangeAttribute]) {
                $sMin = if (Test-IsBoundValue $oAttribute.MinRange -Min) {
                    "[" + $oAttribute.MinRange.GetType().Name + "]::MinValue"
                } else { 
                    $oAttribute.MinRange 
                }
                $sMax = if (Test-IsBoundValue $oAttribute.MaxRange -Max) {
                    "[" + $oAttribute.MaxRange.GetType().Name + "]::MaxValue"
                } else { 
                    $oAttribute.MaxRange 
                }
                $sResult += "[ValidateRange($sMin,$sMax)]"
            } elseif ($oAttribute -is [System.Management.Automation.ValidateNotNullAttribute]) {
                $sResult += "[ValidateNotNull()]"
            } elseif ($oAttribute -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute]) {
                $sResult += "[ValidateNotNullOrEmpty()]"
            } elseif ($oAttribute -is [System.Management.Automation.ValidateLengthAttribute]) {
                $sMin = $oAttribute.MinLength
                $sMax = if (Test-IsBoundValue $oAttribute.MaxLength -Max) {
                    "[int]::MaxValue"
                } else { 
                    $oAttribute.MaxLength 
                }
                $sResult += "[ValidateLength($sMin,$sMax)]"
            } elseif ($oAttribute -is [System.Management.Automation.ValidatePatternAttribute]) {
                $sResult += ("[ValidatePattern(""" + $oAttribute.RegexPattern + """)]")
            } elseif ($oAttribute -is [System.Management.Automation.ValidateScriptAttribute]) {
                $sResult += ("[ValidateScript(""" + $oAttribute.ScriptBlock + """)]")
            } elseif ($oAttribute -is [System.Management.Automation.ValidateSetAttribute]) {
                $sResult += ("[ValidateSet(" + ('"{0}"' -f ($oAttribute.ValidValues -join '","')) + ")]")
            } elseif ($oAttribute -is [System.Management.Automation.ValidateDriveAttribute]) {
                $sDrivesInSet = if ($PSVersionTable.PSVersion -ge "6.2") {
                    '"{0}"' -f ($oAttribute.ValidRootDrives -join '","')
                } else {
                    "PS >= 6.2 needed"
                }
                $sResult += "[ValidateDrive($sDrivesInSet)]"
            } elseif ($oAttribute -is [System.Management.Automation.AllowNullAttribute]) {
                $sResult += "[AllowNull()]"
            } elseif ($oAttribute -is [System.Management.Automation.AllowEmptyStringAttribute]) {
                $sResult += "[AllowEmptyString()]"
            } elseif ($oAttribute -is [System.Management.Automation.AllowEmptyCollectionAttribute]) {
                $sResult += "[AllowEmptyCollection()]"
            } elseif ($oAttribute -is [System.Management.Automation.SupportsWildcardsAttribute]) {
                $sResult += "[SupportsWildcards()]"
            } else {
                #$Attribute | Select-Object -Property * | Write-Host
                $sResult += "" #"[Unsupported attribute type for this function]"
            }            
        }
        return $sResult
    }
    
    $oCmdlet = Get-Command $CmdletName
    $sFunctionResult = "function $CmdLetName {`n"

    # does cmdlet support common parameters ?
    $oParameterSet = $oCmdlet.ParameterSets[0]
    $bSupportCommonParameters = $oParameterSet.ToString() -match "\[\<CommonParameters\>\]"
    #Write-Host ("Support Common Parameters = " + $bSupportCommonParameters)
    # does cmdlet support shouldprocess ?
    $bSupportShouldProcess = ($oParameterSet.ToString() -match "\[-WhatIf\]") `
                                -and ($oParameterSet.Parameters.ToString() -match "\[-Confirm\]")
    #Write-Host ("Support Should Process = " + $bSupportShouldProcess)
    # default parameter set
    $sDefaultParameterSet = $oCmdlet.ParameterSets | Where-Object { $_.IsDefault }
    #Write-Host ("Default parameter set = " + $sDefaultParameterSet.Name)

    $sFunctionResult += Convert-CmdletBindingAttributeToString -SupportsCommonParameters $bSupportCommonParameters -SupportsShouldProcess $bSupportShouldProcess -DefaultParameterSetName $sDefaultParameterSet.Name

    $aAllDefinedParameters = Get-CmdletDefinedParameters $oCmdlet
    $aAllParametersStrings = @()
    foreach ($sParameter in $aAllDefinedParameters) {
        $sParameterResult = ""
        $oParameter = $oCmdlet.Parameters[$sParameter]
        # add all [Parameter(...)] lines
        $bParameterForAllParamSets = ($oParameter.ParameterSets.Keys.Contains("__AllParameterSets")) 
        foreach ($sParameterSet in $oParameter.ParameterSets.Keys) {
            $sTemp = if ($bParameterForAllParamSets) {
                Convert-ParameterSetMetaDataToString -ParameterSetName "" -ParameterAttribute $oParameter.ParameterSets[$sParameterSet]
            } else {
                Convert-ParameterSetMetaDataToString -ParameterSetName $sParameterSet -ParameterAttribute $oParameter.ParameterSets[$sParameterSet]
            }
            if ($sTemp) {
                $sParameterResult += $sTemp + "`n"
            }
        }
        # add validation attributes (Allow, Validate, ...)
        $sTemp = Convert-ParameterAttributesToString $oCmdlet.Parameters[$sParameter].Attributes
        if ($sTemp) {
            $sParameterResult += $sTemp + "`n"
        }
        # add alias attribute
        if ($oParameter.Aliases) {
            $sParameterResult += "[Alias(" + ('"{0}"' -f ($oParameter.Aliases -join '","')) + ")]`n"
        }
        # last parameter line
        $sVariableType = Convert-TypeToPowershellType $oParameter.ParameterType
        $sParameterResult += "$sVariableType`$$sParameter"
        $aAllParametersStrings += $sParameterResult
    }
    if ($aAllParametersStrings) {
        $sFunctionResult += "    Param(`n"
        $sAllParameters = ($aAllParametersStrings -join ",`n`n")
        Set-Indent -TextToIndent ([ref]$sAllParameters) -CharactersToAdd "        "
        $sFunctionResult += $sAllParameters
        $sFunctionResult += "`n    )`n"
    }
    $sFunctionResult += "}`n"
    return $sFunctionResult
}
