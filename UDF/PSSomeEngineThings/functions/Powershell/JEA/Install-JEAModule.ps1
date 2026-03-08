function Install-JEAModule {
    <#
    .SYNOPSIS
        Installs a JEA module with session configuration

    .DESCRIPTION
        Creates and registers a complete JEA module including role capability file (.psrc),
        session configuration file (.pssc), and module manifest. Can execute locally or remotely.

    .PARAMETER ModuleName
        Name of the JEA module to create.

    .PARAMETER PSRCParameters
        Hashtable of parameters for role capability file.

    .PARAMETER jsonPSRCParameters
        JSON string of parameters for role capability file.

    .PARAMETER PSRCName
        Name for the role capability file.

    .PARAMETER PSSCParameters
        Hashtable of parameters for session configuration file.

    .PARAMETER jsonPSSCParameters
        JSON string of parameters for session configuration file.

    .PARAMETER PSSCName
        Name for the session configuration.

    .PARAMETER ComputerName
        Remote computers to install the module on.

    .PARAMETER Credential
        Credentials for remote installation.

    .PARAMETER Session
        Existing PS sessions to use for installation.

    .OUTPUTS
        None. Creates module files and registers PS session configuration.

    .EXAMPLE
        Install-JEAModule -ModuleName "MyJEA" -PSRCName "Operator" -PSSCName "MyJEAEndpoint" -PSRCParameters $roleParams -PSSCParameters $configParams

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName,

        [hashtable]$PSRCParameters,
        [string]$jsonPSRCParameters,
        [Parameter(Mandatory)]
        [string]$PSRCName,

        [hashtable]$PSSCParameters,
        [string]$jsonPSSCParameters,

        [Parameter(Mandatory)]
        [string]$PSSCName,

        [string[]]$ComputerName,
        
        [pscredential]$Credential,

        [System.Management.Automation.Runspaces.PSSession[]]$Session
    )

    Begin{
        if (-not (($PSSCParameters -and $PSRCParameters) `
            -or ($jsonPSSCParameters -and $jsonPSRCParameters))) {
            throw [System.ArgumentException] "Arguments missing. Needs `$PSRCParameters and `$PSSCParameters or `$json* equivalent variables."
        }
        $hPSSCParameters = if ($PSSCParameters) { $PSSCParameters } else { ConvertFrom-Json $jsonPSSCParameters | ConvertTo-Hashtable }
        $hPSRCParameters = if ($PSRCParameters) { $PSRCParameters } else { ConvertFrom-Json $jsonPSRCParameters | ConvertTo-Hashtable }
    }
    Process{
        if ($ComputerName -or $Session) {
            Invoke-ThisFunctionRemotely -ThisFunctionName $MyInvocation.InvocationName -ThisFunctionParameters $PSBoundParameters -ImportFunctions @("ConvertTo-Hashtable", "New-PSRoleCapabilityFile")
        } else {
            # Create a folder for the module
            $modulePath = Join-Path $env:ProgramFiles "WindowsPowerShell\Modules\$ModuleName"

            if (Test-Path -Path $modulePath -PathType Container) {
                Remove-Item $modulePath -Recurse
            }
            New-Item -ItemType Directory -Path $modulePath | Out-Null

            # Create an empty script module and module manifest.
            # At least one file in the module folder must have the same name as the folder itself.
            New-Item -ItemType File -Path (Join-Path $modulePath ($ModuleName + "Functions.psm1")) | Out-Null 
            New-ModuleManifest -Path (Join-Path $modulePath "$ModuleName.psd1") -RootModule ($ModuleName + "Functions.psm1")

            # Create the SessionConfiguration file
            New-PSSessionConfigurationFile @hPSSCParameters -Path ($modulePath + "\$ModuleName.pssc")

            # Create the RoleCapabilities folder and copy in the PSRC file
            $rcFolder = Join-Path $modulePath "RoleCapabilities"
            New-Item -ItemType Directory $rcFolder | Out-Null
            New-PSRoleCapabilityFile @hPSRCParameters -Path ($rcFolder + "\$PSRCName.psrc") 
            
            $oCurrentPSSessionConfig = Get-PSSessionConfiguration | Where-Object { $_.Name -eq $PSSCName } 
            if ($oCurrentPSSessionConfig) {
                Write-Host "Unregister current PS session configuration"
                $oCurrentPSSessionConfig | Unregister-PSSessionConfiguration
            }
            Write-Host "Register PS session configuration"
            Register-PSSessionConfiguration -Name $PSSCName -Path ($modulePath + "\$ModuleName.pssc") | Out-Null
            Write-Host "Restart WinRM service"
            Restart-Service WinRM -Force
        }
    }
    End{}
}