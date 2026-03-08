# PSSomeCoreThings

PowerShell module providing core utilities: logging framework, localization, script introspection, configuration management, and remote execution helpers.

## Author
**Loïc Ade**

## Version
1.0.0

## Description
PSSomeCoreThings is a foundational PowerShell module that provides essential building blocks for PowerShell scripts and applications. It includes a structured logging framework with rotation, a localization system with JSON translations and pluralization, configuration management with multi-source merging, and utilities for remote execution and script reflection.

## Installation

```powershell
Import-Module PSSomeCoreThings
```

## Requirements
- PowerShell 5.1 or higher

## Functions

### Localization Functions (4)

| Function | Description |
|----------|-------------|
| `Get-CurrentLocale` | Gets the current locale from override, environment variable, or system culture |
| `Set-CurrentLocale` | Sets the locale preference and saves it to a config file |
| `Get-Translations` | Loads translation data from JSON files with caching support |
| `Get-LocalizedString` | Retrieves localized strings with parameter substitution and pluralization |

### Logging Functions (5)

| Function | Description |
|----------|-------------|
| `Set-LogInfo` | Initializes logging configuration (folder, rotation, level, date format) |
| `Write-LogInfo` | Writes info-level messages to log file and console with formatting |
| `Out-Prompt` | Writes messages to host and optionally to a log file |
| `Out-Error` | Writes error messages and exception details to host and log file |
| `[LogLevel]` | Enum defining log levels: Error, Warning, Info/Host, Verbose, Debug |

### Script Introspection Functions (7)

| Function | Description |
|----------|-------------|
| `Get-RootScriptName` | Gets the root/calling script name from the call stack |
| `Get-RootScriptPath` | Gets the root script's directory path |
| `Get-ScriptDir` | Gets application directories (input, output, working, tools) |
| `Get-ScriptLogFile` | Gets log file path with fallback folder support |
| `Get-ScriptLogFileName` | Generates timestamped log filename |
| `Get-Function` | Retrieves a function/alias/command object by name |
| `Get-FunctionCode` | Extracts complete function source code for embedding in runspaces |

### Configuration Functions (4)

| Function | Description |
|----------|-------------|
| `Get-ScriptConfig` | Loads configuration from JSON with fallback search locations |
| `Get-RootScriptConfigFile` | Locates a config file in the script hierarchy |
| `Get-UserAndAppScriptConfig` | Loads and merges user, domain, and app configurations |
| `Get-FunctionParameters` | Extracts caller's function parameters with advanced handling |

### Remote Execution Functions (3)

| Function | Description |
|----------|-------------|
| `Invoke-CommandAs` | Executes scripts as System, GMSA, or specific user via scheduled tasks |
| `Invoke-ScriptBlockAs` | Executes a script block with optional credentials via WinRM |
| `Invoke-ThisFunctionRemotely` | Enables remote execution of the calling function with code injection |

### Utility Functions (3)

| Function | Description |
|----------|-------------|
| `Get-ChildItemRec` | Recursively gets child items with support for remote execution |
| `Wait-WinRTTask` | Converts and waits for Windows Runtime async tasks to complete |
| `Set-Property` | Sets or adds a property to a hashtable or PSObject |

## Usage Examples

### Localization

```powershell
# Set locale
Set-CurrentLocale -Locale "fr-FR"

# Get a translated string
$msg = Get-LocalizedString "UI.WindowTitle"

# With parameter substitution
$msg = Get-LocalizedString "Console.Success" -Parameters @("Chrome")
# Returns: "Chrome installed successfully"

# With pluralization (uses | separator in JSON)
$msg = Get-LocalizedString "UI.InstallButton" -Parameters @(3)
# Returns: "Install 3 software" (plural form)

# Shorthand alias
$msg = tr "UI.WindowTitle"
```

### Logging

```powershell
# Initialize logging
$logInfo = Set-LogInfo -LogFolder "C:\Logs\MyApp" `
                       -LogFileName "myapp.log" `
                       -LogRotateCount 5 `
                       -LogLevel ([LogLevel]::Info)

# Write log messages
Write-LogInfo "Application started"
Write-LogInfo "Warning message" -ForegroundColor Yellow

# Write with timestamp to file
Out-Prompt -message "Processing item 1" -logfile $logFile -appendDate

# Log errors with exception details
try {
    # ...
}
catch {
    Out-Error -message "Operation failed" -e $_ -logfile $logFile
}
```

### Configuration Management

```powershell
# Load config from JSON file
$config = Get-ScriptConfig -ConfigFileName "settings.json"

# Load as hashtable
$config = Get-ScriptConfig -ConfigFileName "settings.json" -ToHashtable

# Search in AppData
$config = Get-ScriptConfig -ConfigFileName "settings.json" -AppData

# Merge user and app configs
$mergedConfig = Get-UserAndAppScriptConfig `
    -UserConfigFileName "user-settings.json" `
    -AppConfigFileName "app-settings.json" `
    -ScriptRoot
```

### Script Introspection

```powershell
# Get script info
$scriptName = Get-RootScriptName
$scriptPath = Get-RootScriptPath

# Get application directories
$inputDir = Get-ScriptDir -InputDir
$outputDir = Get-ScriptDir -OutputDir
$toolsDir = Get-ScriptDir -ToolsDir -ToolName "7zip"

# Get function source code (useful for runspaces)
$code = Get-FunctionCode -FunctionName "My-Function"
```

### Remote Execution

```powershell
# Execute as System via scheduled task
Invoke-CommandAs -ScriptBlock { Get-Service } -AsSystem -ComputerName "Server01"

# Execute as GMSA
Invoke-CommandAs -ScriptBlock { Get-Process } -AsGMSA "domain\gmsa_account$"

# Execute with specific credentials
$cred = Get-Credential
Invoke-ScriptBlockAs -ScriptBlock { whoami } -Credential $cred

# Enable remote execution of current function
function Install-Software {
    param($ComputerName, $SoftwareName)

    if ($ComputerName) {
        return Invoke-ThisFunctionRemotely -ThisFunctionName $MyInvocation.MyCommand.Name `
                                           -ThisFunctionParameters $PSBoundParameters
    }

    # Local execution logic
    # ...
}
```

### Utilities

```powershell
# Recursive directory listing (supports remote)
$items = Get-ChildItemRec -path "C:\Program Files\MyApp"

# Remote recursive listing
$items = Get-ChildItemRec -path "C:\Program Files" -ComputerName "Server01"

# Wait for WinRT async operation
$result = Wait-WinRTTask -WinRtTask $asyncTask -ResultType ([string])

# Set property on any object
$obj = @{}
Set-Property -InputObject $obj -Name "Status" -Value "Active"
```

## Common Workflows

### Application with Logging and Configuration

```powershell
Import-Module PSSomeCoreThings

# Load configuration
$config = Get-ScriptConfig -ConfigFileName "app-config.json" -ScriptRoot

# Initialize logging
$logInfo = Set-LogInfo -Config $config

# Application logic with logging
Write-LogInfo "Application started with config: $($config.AppName)"

try {
    # Process items
    foreach ($item in $config.Items) {
        Write-LogInfo "Processing: $item"
        # ...
    }
    Write-LogInfo "All items processed successfully"
}
catch {
    Out-Error -message "Critical error" -e $_ -logfile $logInfo.LogFile
}
```

### Localized Script with Remote Execution

```powershell
Import-Module PSSomeCoreThings

# Detect system locale
$locale = Get-CurrentLocale

# Use translated messages
$title = Get-LocalizedString "App.Title"
$msg = Get-LocalizedString "App.WelcomeMessage" -Parameters @($env:USERNAME)

Write-Host $title
Write-Host $msg

# Execute remotely if needed
function Deploy-Application {
    param(
        [string[]]$ComputerName,
        [string]$PackagePath
    )

    if ($ComputerName) {
        return Invoke-ThisFunctionRemotely -ThisFunctionName $MyInvocation.MyCommand.Name `
                                           -ThisFunctionParameters $PSBoundParameters `
                                           -ImportFunctions @("Write-LogInfo", "Out-Prompt")
    }

    Out-Prompt "Deploying $PackagePath on $env:COMPUTERNAME"
    # Local deployment logic...
}
```

## Use Cases

1. **Script Logging**: Structured logging with rotation, levels, and timestamped output
2. **Multilingual Applications**: Full localization support with JSON translations and pluralization
3. **Configuration Management**: Multi-source JSON config loading with merging and fallback
4. **Remote Administration**: Execute functions remotely as System, GMSA, or specific users
5. **Script Scaffolding**: Auto-detect script paths, generate log filenames, load configs
6. **Runspace Support**: Extract function code for embedding in separate runspaces
7. **WinRT Integration**: Bridge between PowerShell and Windows Runtime async operations

## Aliases

| Alias | Function |
|-------|----------|
| `tr` | `Get-LocalizedString` |
| `Write-LogHost` | `Write-LogInfo` |
| `Write-LogInformation` | `Write-LogInfo` |

## License

This module is licensed under the **PolyForm Noncommercial License 1.0.0**.

See the [LICENSE](LICENSE) file for full license text.

**Required Notice**: Copyright Loïc Ade (https://github.com/qqt-lo4)

## Support

For issues, questions, or contributions, please contact the author.

## Version History

- **1.0.0** (Initial Release)
  - Localization system with JSON translations, caching, and pluralization
  - Logging framework with rotation, levels, and console formatting
  - Script introspection utilities (paths, names, directories)
  - Configuration management with multi-source merging
  - Remote execution helpers (System, GMSA, credential-based)
  - Utility functions (recursive listing, WinRT, property management)
