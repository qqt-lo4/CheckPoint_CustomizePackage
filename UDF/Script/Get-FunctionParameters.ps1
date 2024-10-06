function Get-FunctionParameters {
    # based on https://gist.github.com/Jaykul/72f30dce2cca55e8cd73e97670db0b09/
    Param(
        [Parameter(Position = 0)]
        [string[]]$RemoveParam,
        [switch]$AsJson
    )
    Begin {
        function Get-ParameterSetName {
            Param(
                [Parameter(Mandatory)]
                [object]$Invocation,
                [Parameter(Mandatory)]
                [hashtable]$BoundParameters
            )
            $aParameterSetsResults = @()
            foreach ($parameterset in $Invocation.ParameterSets) {
                $oCompareLeft = ([string[]]$BoundParameters.Keys)
                $oCompareRight = ([string[]]$parameterset.Parameters.Name)
                $aIntersection = Compare-Object $oCompareLeft $oCompareRight -IncludeEqual -ExcludeDifferent
                if (($aIntersection -ne $null) -and `
                        (($aIntersection.GetType().Name -eq "Object[]") -or ($aIntersection.GetType().Name -eq "Object") -or `
                        (($aIntersection.GetType().Name -eq "PSCustomObject") -and ($aIntersection.SideIndicator -eq "==")))) {
                    $aParameterSetsResults += $parameterset.Name
                } else {
                    $iIntersectionCount = $aIntersection.Count
                    $iPSBoundParamCount = $BoundParameters.Keys.Count
                    if ($iIntersectionCount -eq $iPSBoundParamCount) {
                        $aParameterSetsResults += $parameterset.Name
                    }    
                }
            }
            if ($aParameterSetsResults.Count -eq 1) {
                $sResult = $aParameterSetsResults[0]
                return $sResult
            } else {
                return ($Invocation.ParameterSets | Where-Object { $_.IsDefault -eq $true }).Name
            }
        }
        $parentInvocation = (Get-PSCallStack)[1].InvocationInfo
        $BoundParameters = (Get-PSCallStack)[1].InvocationInfo.BoundParameters
        $sParameterSetName = Get-ParameterSetName -Invocation $parentInvocation.MyCommand -BoundParameters $BoundParameters -Verbose
    }
    Process {
        $hResultAPIParameters = @{}
        $aParameterSet = $parentInvocation.MyCommand.ParameterSets | Where-Object { $_.Name -eq $sParameterSetName }
        foreach($parameter in $aParameterSet.Parameters.GetEnumerator()) {
            try {
                $key = $parameter.Name
                if($null -ne ($value = Get-Variable -Name $key -ValueOnly -ErrorAction Ignore -Scope 1)) {
                    if($value -ne ($null -as $parameter.ParameterType)) {
                        $hResultAPIParameters[$key] = $value
                    }
                }
                if($BoundParameters.ContainsKey($key)) {
                    $hResultAPIParameters[$key] = $BoundParameters[$key]
                }
            }
            finally {}
        }
        # convert types
        $hNewResultAPIParameters = @{}
        foreach ($item in $hResultAPIParameters.Keys) {
            if ($null -eq $hResultAPIParameters[$item]) {
                $hNewResultAPIParameters[$item] = $null
            } else {
                switch ($hResultAPIParameters[$item].GetType().Name) {
                    "SwitchParameter" {
                        $hNewResultAPIParameters[$item] = $hResultAPIParameters[$item].IsPresent
                    }
                    default {
                        $hNewResultAPIParameters[$item] = $hResultAPIParameters[$item]
                    }
                }    
            }
        }
        # remove all useless parameters
        foreach ($item in $RemoveParam) {
            $hNewResultAPIParameters.Remove($item) | Out-Null
        }
    }
    End {
        if ($AsJson) {
            return $hNewResultAPIParameters | ConvertTo-Json
        } else {
            return $hNewResultAPIParameters
        }
    }
}
