# PSSomeEngineThings

A PowerShell module for PowerShell engine utilities: script editing and analysis, module management, JEA configuration, PSSession helpers, PSDrive operations, and AutoIt compilation.

## Features

### AutoIt (3 functions)

| Function | Description |
|----------|-------------|
| `Invoke-AutoItCompile` | Compiles an AutoIt script to executable using Aut2Exe |
| `New-PowershellScriptRunner` | Creates an AutoIt-based executable wrapper for PowerShell scripts |
| `Search-AutoItCompile` | Searches for the AutoIt compiler executable (supports beta and x64) |

### ConnectionInfo (1 function)

| Function | Description |
|----------|-------------|
| `Get-ConnectionInfo` | Retrieves or prompts for connection information (server, port, credentials) |

### Edit (11 functions)

| Function | Description |
|----------|-------------|
| `Get-FunctionMetadata` | Extracts module and dependency metadata from PowerShell script files |
| `Get-PowershellScriptDependencies` | Extracts dependency paths from PowerShell scripts |
| `Get-PowershellScriptWithIncludedDependancies` | Merges a script with its dependencies into a single file |
| `Get-ScriptCommentRegion` | Extracts comments from a named script region |
| `Get-ScriptInfo` | Extracts metadata from the "script info" region |
| `Get-ScriptRegion` | Extracts content from a named #region in a script |
| `Get-ScriptRegions` | Gets all region names from a PowerShell script |
| `Remove-ScriptRegion` | Removes a named region from a PowerShell script |
| `Replace-ScriptRegion` | Replaces content in a named region |
| `Write-ScriptCommentDoc` | Writes comment documentation to a script region |

### Module (4 functions)

| Function | Description |
|----------|-------------|
| `Import-InstalledModule` | Imports an installed PowerShell module |
| `Import-PSModule` | Imports a PowerShell module with additional options |
| `Install-PSModule` | Installs a PowerShell module from PSGallery or custom repository |
| `Test-InstalledPSModule` | Tests if a PowerShell module is installed |

### Other (2 functions)

| Function | Description |
|----------|-------------|
| `ConvertTo-OneLineScriptBlock` | Converts a script block to a single-line format |
| `ConvertTo-ScriptBlock` | Converts a string to a script block object |

### Powershell (5 functions)

| Function | Description |
|----------|-------------|
| `Get-CmdletDefinedParameters` | Gets defined parameters for a cmdlet |
| `Get-CmdletHeader` | Extracts the header (synopsis) from a cmdlet's help |
| `Get-CommandProxy` | Creates a proxy function for an existing command |
| `New-PSRC` | Creates a new PowerShell Role Capability file |
| `New-PSSC` | Creates a new PowerShell Session Configuration file |
| `Test-Type` | Tests if a .NET type exists and is loaded |

### Powershell\JEA (5 functions)

| Function | Description |
|----------|-------------|
| `Get-JEARoleFromUserGroups` | Gets JEA roles based on user group membership |
| `Install-JEAModule` | Installs a JEA module with role capabilities |
| `New-PSRoleCapabilityFile` | Creates a new PowerShell Role Capability file for JEA |
| `New-PSSessionConfigurationFile` | Creates a new PowerShell Session Configuration file for JEA |
| `Select-JEARole` | Selects appropriate JEA role based on criteria |

### PSDrive (1 function)

| Function | Description |
|----------|-------------|
| `Test-PSDrive` | Tests if a PowerShell drive exists |

### PSSession (2 functions)

| Function | Description |
|----------|-------------|
| `Connect-MultiplePSSessions` | Connects to multiple remote PowerShell sessions |
| `New-TestedPSSession` | Creates a new PSSession with connection testing |

## Requirements

- **PowerShell** 5.1 or later
- **Windows** operating system
- **AutoIt** (for AutoIt-related functions)
- **Administrator privileges** (for some JEA operations)

## Installation

```powershell
# Clone or copy the module to a PowerShell module path
Copy-Item -Path ".\PSSomeEngineThings" -Destination "$env:USERPROFILE\Documents\PowerShell\Modules\PSSomeEngineThings" -Recurse

# Or import directly
Import-Module ".\PSSomeEngineThings\PSSomeEngineThings.psd1"
```

## Quick Start

### Script Analysis and Editing

```powershell
# Extract metadata from a script
$metadata = Get-FunctionMetadata -FilePath "C:\Scripts\MyFunction.ps1"
$metadata.FunctionName
$metadata.Module
$metadata.Dependencies

# Get dependencies
$deps = Get-PowershellScriptDependencies -powershellFile "C:\Scripts\MyScript.ps1"

# Merge script with dependencies
$merged = Get-PowershellScriptWithIncludedDependancies -powershellFile "C:\Scripts\MyScript.ps1"
$merged | Out-File "C:\Scripts\Standalone.ps1"

# Extract region content
$config = Get-ScriptRegion -powershellFile "C:\Scripts\MyScript.ps1" -regionName "config"

# Get all regions
$regions = Get-ScriptRegions -powershellFile "C:\Scripts\MyScript.ps1"
```

### Module Management

```powershell
# Test if module is installed
if (Test-InstalledPSModule -ModuleName "Pester") {
    Write-Host "Pester is installed"
}

# Install module
Install-PSModule -ModuleName "PSScriptAnalyzer" -Scope CurrentUser

# Import module
Import-PSModule -ModuleName "Pester" -MinimumVersion "5.0"
```

### AutoIt Compilation

```powershell
# Compile AutoIt script
Invoke-AutoItCompile -File "C:\Scripts\MyScript.au3"

# Compile with custom icon and x64
Invoke-AutoItCompile -File "C:\Scripts\MyScript.au3" -Icon "C:\Icons\app.ico" -X64

# Create PowerShell script runner
New-PowershellScriptRunner -PS1FileName "C:\Scripts\Deploy.ps1" -RunAsAdmin -X64 -Icon "C:\Icons\deploy.ico" -Hashtable @{}
```

### JEA Configuration

```powershell
# Create role capability file
New-PSRoleCapabilityFile -Path "C:\JEA\HelpDesk.psrc" `
                         -VisibleCmdlets "Get-Service", "Restart-Service" `
                         -VisibleFunctions "Get-ComputerInfo"

# Create session configuration file
New-PSSessionConfigurationFile -Path "C:\JEA\HelpDesk.pssc" `
                                -SessionType RestrictedRemoteServer `
                                -RoleDefinitions @{
                                    "DOMAIN\HelpDesk" = @{ RoleCapabilities = "HelpDesk" }
                                }

# Install JEA module
Install-JEAModule -ModulePath "C:\JEA\MyJEAModule" -RoleCapabilityPath "C:\JEA\MyRole.psrc"

# Get JEA role from user groups
$role = Get-JEARoleFromUserGroups -UserGroups @("DOMAIN\HelpDesk", "DOMAIN\Administrators")
```

### PSSession Management

```powershell
# Create tested PSSession
$session = New-TestedPSSession -ComputerName "Server01" -Credential (Get-Credential)

# Connect to multiple sessions
$servers = "Server01", "Server02", "Server03"
$sessions = Connect-MultiplePSSessions -ComputerNames $servers -Credential (Get-Credential)
```

### PowerShell Utilities

```powershell
# Test if type exists
if (Test-Type -TypeName "System.Management.Automation.Runspaces.Runspace") {
    Write-Host "Type is loaded"
}

# Convert to script block
$scriptBlock = ConvertTo-ScriptBlock -String "Get-Process | Where-Object CPU -gt 100"

# Convert to one-line script block
$oneLine = ConvertTo-OneLineScriptBlock -ScriptBlock {
    Get-Service
    | Where-Object Status -eq 'Running'
}

# Get cmdlet parameters
$params = Get-CmdletDefinedParameters -CmdletName "Get-Process"

# Create command proxy
$proxy = Get-CommandProxy -Name "Get-Process" -Module "Microsoft.PowerShell.Management"
```

## Advanced Usage

### Creating Standalone Scripts

```powershell
# Merge a modular script into standalone version
function New-StandaloneScript {
    param(
        [string]$SourceScript,
        [string]$OutputScript
    )

    # Get merged content
    $content = Get-PowershellScriptWithIncludedDependancies -powershellFile $SourceScript

    # Save to output
    $content | Out-File -FilePath $OutputScript -Encoding UTF8

    Write-Host "Standalone script created: $OutputScript"
}

# Usage
New-StandaloneScript -SourceScript "C:\Scripts\Deploy.ps1" -OutputScript "C:\Scripts\Deploy-Standalone.ps1"
```

### Automated AutoIt Wrapper Creation

```powershell
function New-PortableExe {
    param(
        [string]$PS1Script,
        [string]$OutputExe,
        [string]$Icon,
        [switch]$RequireAdmin
    )

    # Create wrapper
    $params = @{
        PS1FileName = $PS1Script
        ExeFileName = $OutputExe
        X64 = $true
        CUI = $true
        Hashtable = @{}
    }

    if ($Icon) { $params.Icon = $Icon }
    if ($RequireAdmin) { $params.RunAsAdmin = $true }

    New-PowershellScriptRunner @params

    Write-Host "Portable executable created: $OutputExe"
}

# Usage
New-PortableExe -PS1Script "C:\Scripts\Tool.ps1" `
                -OutputExe "C:\Tools\Tool.exe" `
                -Icon "C:\Icons\tool.ico" `
                -RequireAdmin
```

### JEA Deployment Workflow

```powershell
# Complete JEA deployment
function Deploy-JEAEndpoint {
    param(
        [string]$EndpointName,
        [string]$ModulePath,
        [hashtable]$RoleDefinitions
    )

    # Create module directory structure
    $moduleDir = Join-Path $ModulePath $EndpointName
    $rcDir = Join-Path $moduleDir "RoleCapabilities"
    New-Item -ItemType Directory -Path $rcDir -Force | Out-Null

    # Create role capability files
    foreach ($roleName in $RoleDefinitions.Keys) {
        $rcPath = Join-Path $rcDir "$roleName.psrc"
        $roleConfig = $RoleDefinitions[$roleName]

        New-PSRoleCapabilityFile -Path $rcPath `
                                 -VisibleCmdlets $roleConfig.VisibleCmdlets `
                                 -VisibleFunctions $roleConfig.VisibleFunctions
    }

    # Create session configuration
    $scPath = Join-Path $env:TEMP "$EndpointName.pssc"
    $roleDef = @{}
    foreach ($role in $RoleDefinitions.Keys) {
        $roleDef[$role] = @{ RoleCapabilities = $role }
    }

    New-PSSessionConfigurationFile -Path $scPath `
                                   -SessionType RestrictedRemoteServer `
                                   -RoleDefinitions $roleDef

    # Register endpoint
    Register-PSSessionConfiguration -Name $EndpointName `
                                     -Path $scPath `
                                     -Force

    Write-Host "JEA endpoint deployed: $EndpointName"
}

# Usage
$roles = @{
    "HelpDesk" = @{
        VisibleCmdlets = @("Get-Service", "Restart-Service", "Get-Process")
        VisibleFunctions = @("Get-ComputerInfo")
    }
    "Operators" = @{
        VisibleCmdlets = @("Get-*", "Restart-Service", "Stop-Process")
        VisibleFunctions = @("Get-ComputerInfo", "Get-DiskSpace")
    }
}

Deploy-JEAEndpoint -EndpointName "MyJEAEndpoint" `
                    -ModulePath "C:\Program Files\WindowsPowerShell\Modules" `
                    -RoleDefinitions $roles
```

### Script Region Management

```powershell
# Add or update configuration region
function Update-ScriptConfiguration {
    param(
        [string]$ScriptPath,
        [hashtable]$Config
    )

    # Build config content
    $configLines = @()
    $configLines += "#region config"
    foreach ($key in $Config.Keys) {
        $configLines += "`$$key = `"$($Config[$key])`""
    }
    $configLines += "#endregion config"

    # Check if region exists
    $regions = Get-ScriptRegions -powershellFile $ScriptPath

    if ($regions -contains "config") {
        # Replace existing region
        Replace-ScriptRegion -powershellFile $ScriptPath `
                             -regionName "config" `
                             -newRegionContent $configLines `
                             -OutFile $ScriptPath
    } else {
        # Add new region
        $content = Get-Content $ScriptPath
        $configLines + $content | Out-File $ScriptPath
    }
}

# Usage
Update-ScriptConfiguration -ScriptPath "C:\Scripts\Deploy.ps1" `
                            -Config @{
                                ServerName = "prod-server-01"
                                Port = "8080"
                                Environment = "Production"
                            }
```

## Module Structure

```
PSSomeEngineThings/
├── PSSomeEngineThings.psd1    # Module manifest
├── PSSomeEngineThings.psm1    # Module loader
├── README.md                   # This file
├── LICENSE                     # PolyForm Noncommercial License
├── AutoIt/                     # AutoIt compilation utilities (3 functions)
│   ├── Invoke-AutoItCompile.ps1
│   ├── New-PowershellScriptRunner.ps1
│   └── Search-AutoItCompile.ps1
├── ConnectionInfo/             # Connection management (1 function)
│   └── Get-ConnectionInfo.ps1
├── Edit/                       # Script editing and analysis (11 functions)
│   ├── Get-FunctionMetadata.ps1
│   ├── Get-PowershellScriptDependencies.ps1
│   ├── Get-PowershellScriptWithIncludedDependancies.ps1
│   ├── Get-ScriptCommentRegion.ps1
│   ├── Get-ScriptInfo.ps1
│   ├── Get-ScriptRegion.ps1
│   ├── Get-ScriptRegions.ps1
│   ├── Remove-ScriptRegion.ps1
│   ├── Replace-ScriptRegion.ps1
│   └── Write-ScriptCommentDoc.ps1
├── Module/                     # Module management (4 functions)
│   ├── Import-InstalledModule.ps1
│   ├── Import-PSModule.ps1
│   ├── Install-PSModule.ps1
│   └── Test-InstalledPSModule.ps1
├── Other/                      # Utility functions (2 functions)
│   ├── ConvertTo-OneLineScriptBlock.ps1
│   └── ConvertTo-ScriptBlock.ps1
├── Powershell/                 # PowerShell utilities (5 functions)
│   ├── Get-CmdletDefinedParameters.ps1
│   ├── Get-CmdletHeader.ps1
│   ├── Get-CommandProxy.ps1
│   ├── New-PSRC.ps1
│   ├── New-PSSC.ps1
│   └── Test-Type.ps1
├── Powershell/JEA/             # JEA configuration (5 functions)
│   ├── Get-JEARoleFromUserGroups.ps1
│   ├── Install-JEAModule.ps1
│   ├── New-PSRoleCapabilityFile.ps1
│   ├── New-PSSessionConfigurationFile.ps1
│   └── Select-JEARole.ps1
├── PSDrive/                    # PSDrive operations (1 function)
│   └── Test-PSDrive.ps1
└── PSSession/                  # PSSession helpers (2 functions)
    ├── Connect-MultiplePSSessions.ps1
    └── New-TestedPSSession.ps1
```

## Common Use Cases

### Script Development and Deployment

- **Dependency Analysis**: Analyze PowerShell scripts to find all dependencies
- **Standalone Scripts**: Merge modular scripts into standalone deployable files
- **Executable Wrappers**: Create .exe wrappers for PowerShell scripts using AutoIt
- **Metadata Extraction**: Extract function metadata for documentation generation

### Module Management

- **Installation Automation**: Automate module installation from PSGallery
- **Version Control**: Ensure specific module versions are loaded
- **Dependency Checking**: Test if required modules are installed before execution

### Security and Administration

- **JEA Implementation**: Implement Just Enough Administration for delegated access
- **Role-Based Access**: Create role capabilities for different user groups
- **Constrained Endpoints**: Deploy PowerShell endpoints with limited cmdlet access
- **Remote Management**: Manage multiple remote sessions efficiently

### Code Analysis

- **Region Management**: Organize code with #region markers and extract/modify content
- **Comment Documentation**: Automatically generate or update comment-based help
- **Script Information**: Extract script metadata and configuration

## JEA (Just Enough Administration)

### Overview

JEA allows you to create PowerShell endpoints that provide delegated administration with minimal privileges. Users connecting to JEA endpoints can only execute allowed commands.

### Key Concepts

- **Session Configuration File (.pssc)**: Defines the endpoint configuration
- **Role Capability File (.psrc)**: Defines what commands users in specific roles can run
- **RoleDefinitions**: Maps AD groups to role capabilities

### Example: HelpDesk Endpoint

```powershell
# 1. Create role capability
New-PSRoleCapabilityFile -Path "C:\JEA\HelpDesk.psrc" `
    -VisibleCmdlets @(
        "Get-Service",
        @{ Name = "Restart-Service"; Parameters = @{ Name = "Name"; ValidateSet = "Spooler", "W32Time" } }
    ) `
    -VisibleFunctions "Get-ComputerInfo"

# 2. Create session configuration
New-PSSessionConfigurationFile -Path "C:\JEA\HelpDesk.pssc" `
    -SessionType RestrictedRemoteServer `
    -RoleDefinitions @{
        "DOMAIN\HelpDesk" = @{ RoleCapabilities = "HelpDesk" }
    }

# 3. Register endpoint
Register-PSSessionConfiguration -Name "HelpDesk" -Path "C:\JEA\HelpDesk.pssc"

# 4. Test connection
Enter-PSSession -ComputerName localhost -ConfigurationName HelpDesk
```

## AutoIt Integration

### Overview

AutoIt functions allow you to compile PowerShell scripts into standalone executables that don't require PowerShell to be visible to end users.

### Workflow

1. Write your PowerShell script
2. Use `New-PowershellScriptRunner` to create an AutoIt wrapper
3. The function automatically compiles it to .exe
4. Distribute the .exe (includes the .ps1 internally)

### Benefits

- **User-friendly**: Users can run scripts without knowing PowerShell
- **Elevation**: Automatically request admin rights if needed
- **Branding**: Custom icons for your tools
- **Standalone**: No PowerShell window visible to users

## Security Notes

- **JEA Endpoints**: Always use least privilege principle when defining role capabilities
- **AutoIt Wrappers**: Executable wrappers should be code-signed for distribution
- **Script Regions**: Be cautious when programmatically modifying scripts
- **Administrator Rights**: Some JEA operations require administrator privileges
- **Remote Sessions**: Always use credentials securely with PSSession functions

## Author

**Loïc Ade**

## License

This project is licensed under the [PolyForm Noncommercial License 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/). See the [LICENSE](LICENSE) file for details.

In short:
- **Non-commercial use only** — You may use, modify, and distribute this software for any non-commercial purpose.
- **Attribution required** — You must include a copy of the license terms with any distribution.
- **No warranty** — The software is provided as-is.
