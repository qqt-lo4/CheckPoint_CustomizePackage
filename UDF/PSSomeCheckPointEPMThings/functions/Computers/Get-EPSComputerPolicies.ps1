function Get-EPSComputerPolicies {
    [Cmdletbinding(DefaultParameterSetName = "Name")]
    Param(
        [object]$EPSAPI,
        [Parameter(ParameterSetName = "Id", Mandatory)]
        [string]$Id,
        [Parameter(ParameterSetName = "Name", Mandatory, Position = 0)]
        [string]$Name,
        [Parameter(ParameterSetName = "Computer", Mandatory)]
        [object]$Computer
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
        $oComputer = if ($Computer) {
            $Computer
        } elseif ($Name) {
            Get-EPSComputer -EPSAPI $oEPSAPI -Name $Name
        } else {
            Get-EPSComputer -EPSAPI $oEPSAPI -Id $Id
        }
    }
    Process {
        $hDeployedPolicies = $oComputer | ConvertTo-Hashtable | Select-HashtableProperty -Property "deployedNamePolicy*"
        $aResult = @()
        foreach ($key in $hDeployedPolicies.Keys) {
            if ($hDeployedPolicies.$key -ne "999") {
                $feature = $key.SubString(18)
                $hfeature = @{
                    FeatureName = $feature
                    PolicyName = $hDeployedPolicies.$key
                    DeployedVersionPolicy = $oComputer.$("deployedVersionPolicy$feature")
                    EnforcedPolicy = $oComputer.$("enforcedPolicy$feature")
                    EnforcedVersionPolicy = $oComputer.$("enforcedVersionPolicy$feature")
                }
                $aResult += $hfeature
            }
        }
    }
    End {
        return $aResult
    }
}
