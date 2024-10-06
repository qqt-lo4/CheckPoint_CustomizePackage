function Get-UserAndAppScriptConfig {
    Param(
        [string]$AppConfigFileName = "config.json",
        [string]$UserConfigFileName = "user_$($env:USERDNSDOMAIN)_$($env:USERNAME).json",
        [string]$DomainConfigFileName = "domain_$($env:USERDNSDOMAIN).json",
        [string]$DevConfigFolderName = "input",
        [switch]$AppConfigScriptRoot,
        [switch]$AppConfigAppData,
        [switch]$AppConfigProgramData,
        [switch]$DomainConfigScriptRoot,
        [switch]$DomainConfigAppData,
        [switch]$DomainConfigProgramData,
        [switch]$UserConfigScriptRoot,
        [switch]$UserConfigAppData,
        [switch]$UserConfigProgramData
    )
    Begin {
        function Get-ConfigParamObjects {
            Param(
                [Parameter(Mandatory, Position = 0)]
                [object]$BoundParameters,
                [Parameter(Mandatory, Position = 1)]
                [string]$InputString
            )
            return $BoundParameters | Select-HashtableProperty -Property "$InputString*" | Rename-HashtableProperty -LookFor "^$InputString(.*)" -ReplaceBy "`$1"
        }
        $hUserConfig_params = Get-ConfigParamObjects $PSBoundParameters "UserConfig"
        $hUserConfig = Get-ScriptConfig -ConfigFileName $UserConfigFileName -ToHashtable `
                                        -DevConfigFolderName $DevConfigFolderName @hUserConfig_params 
        $hDomainConfig_params = Get-ConfigParamObjects $PSBoundParameters "DomainConfig"
        $hDomainConfig = Get-ScriptConfig -ConfigFileName $DomainConfigFileName -ToHashtable `
                                        -DevConfigFolderName $DevConfigFolderName @hDomainConfig_params
        $hAppConfig_params = Get-ConfigParamObjects $PSBoundParameters "AppConfig"
        $hAppConfig = Get-ScriptConfig -ConfigFileName $AppConfigFileName -ToHashtable `
                                       -DevConfigFolderName $DevConfigFolderName @hAppConfig_params
        function Merge-Hashtable {
            Param(
                [Parameter(Position = 0)]
                [AllowNull()]
                [hashtable]$HashtableA,
                [Parameter(Position = 1)]
                [AllowNull()]
                [hashtable]$HashtableB
            )
            if (($null -eq $HashtableA) -and ($null -eq $HashtableB)) {
                return $null
            } elseif (($null -eq $HashtableA) -and ($null -ne $HashtableB)) {
                return Copy-Hashtable $HashtableB
            } elseif (($null -ne $HashtableA) -and ($null -eq $HashtableB)) {
                return Copy-Hashtable $HashtableA
            } else {
                $hResult = @{}
                foreach ($p in $HashtableA.Keys) {
                    # both hashtable have the same property $p
                    if ($p -in $HashtableB.Keys) {
                        # both values are hashtable so merge items
                        if (($HashtableA[$p] -is [hashtable]) -and ($HashtableB[$p] -is [hashtable])) {
                            $hResult[$p] = Merge-Hashtable $HashtableA[$p] $HashtableB[$p]
                        } else {
                            $hResult[$p] = $HashtableB[$p]
                        }
                    } else {
                        $hResult[$p] = $HashtableA[$p]
                    }
                }
                foreach ($p in $HashtableB.Keys) {
                    if ($p -notin $HashtableA.Keys) {
                        $hResult[$p] = $HashtableB[$p]
                    }
                }
                return $hResult
            }
        }
    }
    Process {

    }
    End {
        $hResult = Merge-Hashtable (Merge-Hashtable $hUserConfig $hAppConfig) $hDomainConfig
        return $hResult
    }
}
