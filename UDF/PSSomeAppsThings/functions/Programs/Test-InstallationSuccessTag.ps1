function Test-InstallationSuccessTag {
    <#
    .SYNOPSIS
        Tests if an installation success tag exists

    .DESCRIPTION
        Checks the registry (and optionally a tag file) to verify if an application
        was successfully installed. Supports version comparison to check if the installed
        version meets a minimum requirement.

    .PARAMETER regroot
        Registry root path. Valid values: "hklm:\", "hkcu:\" (default: "hklm:\")

    .PARAMETER regfolder
        Registry folder path under the root

    .PARAMETER ApplicationName
        Name of the application to check

    .PARAMETER Status
        Expected status value (default: "OK")

    .PARAMETER PackageVersion
        Minimum package version to validate against

    .PARAMETER ProductVersion
        Minimum product version to validate against

    .PARAMETER TagFile
        Optional file path to check for existence

    .PARAMETER ValidationScope
        How to combine registry and file checks: "RegOrFile" (default) or "RegAndFile"

    .OUTPUTS
        System.Boolean. True if the installation tag matches the criteria.

    .EXAMPLE
        Test-InstallationSuccessTag -regfolder "SOFTWARE\MyCompany\Deployments" -ApplicationName "MyApp"

    .EXAMPLE
        Test-InstallationSuccessTag -regfolder "SOFTWARE\MyCompany" -ApplicationName "MyApp" -PackageVersion "2.0.0"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param (
        [ValidateNotNullOrEmpty()]
        [ValidateSet("hklm:\", "hkcu:\")]
        [string]$regroot = "hklm:\",
        [Parameter(Mandatory)]
        [string]$regfolder,
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)]
        [string]$ApplicationName,
        [ValidateNotNullOrEmpty()]
        [string]$Status = "OK",
        [Parameter(ParameterSetName = "PackageVersion")]
        [ValidateNotNullOrEmpty()]
        [string]$PackageVersion,
        [Parameter(ParameterSetName = "ProductVersion")]
        [ValidateNotNullOrEmpty()]
        [string]$ProductVersion,
        [string]$TagFile,
        [ValidateSet("RegAndFile", "RegOrFile")]
        [string]$ValidationScope = "RegOrFile"
    )
    $registry_tag_path = $regroot + $regfolder + "\" + $ApplicationName
    $key = Get-Item -LiteralPath $registry_tag_path -ErrorAction SilentlyContinue
    $bKeyTest = if ($null -eq $key) {
        $false
    } else {
        $Status_Value = $key.GetValue("Status", $null)
        switch ($PSCmdlet.ParameterSetName) {
            "PackageVersion" {
                $Package_Version_Value = $key.GetValue("PackageVersion", $null)
                if ($null -eq $Package_Version_Value) {
                    ($null -ne $Status_Value) -and ($Status_Value -eq $Status)
                } else {
                    ($null -ne $Status_Value) -and ($Status_Value -eq $Status) `
                      -and ([version]$PackageVersion -le [version]$Package_Version_Value)        
                }
            }
            "ProductVersion" {
                $Product_Version_Value = $key.GetValue("ProductVersion", $null)
                if ($null -eq $Product_Version_Value) {
                    ($null -ne $Status_Value) -and ($Status_Value -eq $Status)
                } else {
                    try {
                        ($null -ne $Status_Value) -and ($Status_Value -eq $Status) `
                        -and ([version]$ProductVersion -le [version]$Product_Version_Value)
                    } catch {
                        ($ProductVersion -eq $Product_Version_Value)
                    }
                }
            }
        }
    }
    $bTagFileTest = ($TagFile -and (Test-path -Path $TagFile -PathType Leaf))
    if ($TagFile) {
        if ($ValidationScope -eq "RegOrFile") {
            return $bKeyTest -or $bTagFileTest
        } else {
            return $bKeyTest -and $bTagFileTest
        }    
    } else {
        return $bKeyTest
    }
}
