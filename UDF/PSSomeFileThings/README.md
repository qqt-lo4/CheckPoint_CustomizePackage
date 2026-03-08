# PSSomeFileThings

PowerShell module providing comprehensive file system utilities including 7-Zip archive creation, CAB file operations, path manipulation, file rotation, and remote file operations.

## Author
**Loïc Ade**

## Version
1.0.0

## Description
PSSomeFileThings is a PowerShell module that provides advanced file system operations beyond the standard PowerShell cmdlets. It includes tools for:
- Creating 7-Zip archives and self-extracting executables
- Working with Windows CAB (Cabinet) files
- Advanced path manipulation and resolution
- Log file rotation with retention management
- Remote file operations with credential support

## Installation

```powershell
# Import the module
Import-Module PSSomeFileThings
```

## Requirements
- PowerShell 5.1 or higher
- 7-Zip (for archive operations)
- Windows expand.exe (for CAB operations, included with Windows)

## Functions

### 7-Zip Archive Functions (3)

| Function | Description |
|----------|-------------|
| `New-7ZipArchive` | Creates a 7-Zip archive with configurable compression |
| `New-7ZipSFX` | Creates a self-extracting executable from a 7z archive |
| `New-SFXConfigFile` | Generates configuration file for SFX archives |

### Cabinet File Functions (2)

| Function | Description |
|----------|-------------|
| `Get-CABContentList` | Lists files contained in a CAB archive |
| `Expand-CABFile` | Extracts files from a CAB archive |

### File Operations (6)

| Function | Description |
|----------|-------------|
| `Get-FilesToRotate` | Gets files matching a rotation naming pattern |
| `Get-RotatedFilesToDelete` | Identifies rotated files exceeding retention count |
| `Invoke-FileRotate` | Performs file rotation with automatic retention management |
| `Read-FileNonBlocking` | Reads files without locking them |
| `Copy-RemoteFile` | Copies files to remote locations with credential support |
| `Get-RemotePSDrive` | Gets PSDrive information from remote computers |

### Path Manipulation Functions (4)

| Function | Description |
|----------|-------------|
| `Resolve-RelativePath` | Calculates relative path between two locations |
| `Split-Path` | Extended Split-Path with hashtable output option |
| `Split-PathToHashTable` | Splits path into components as hashtable |
| `Resolve-PathWithVariables` | Expands environment and custom variables in paths |

## Usage Examples

### Creating 7-Zip Archives

```powershell
# Create a basic 7z archive
New-7ZipArchive -Content "C:\Data" -OutputArchivePath "C:\backup.7z"

# Create archive with maximum compression
New-7ZipArchive -Content "C:\Files" -OutputArchivePath "C:\archive.7z" -CompressionLevel 9

# Create self-extracting installer
New-SFXConfigFile -Title "My App Installer" `
                  -ExecuteFile "setup.exe" `
                  -ExecuteParameters "/silent" `
                  -OutFilePath "config.txt"

New-7ZipSFX -SevenZipHeaderFile "7zSD.sfx" `
            -SFXConfigFile "config.txt" `
            -ArchiveFile "app.7z" `
            -OutFile "installer.exe"
```

### Working with CAB Files

```powershell
# List CAB contents
Get-CABContentList -CABFile "C:\archive.cab"

# Extract all files
Expand-CABFile -CABFile "C:\archive.cab" -Destination "C:\Output"

# Extract specific file
Expand-CABFile -CABFile "C:\archive.cab" `
               -Destination "C:\Output" `
               -Filename "driver.inf"
```

### File Rotation and Management

```powershell
# Rotate a log file (keeping 5 versions)
Invoke-FileRotate -filepath "C:\logs\app.log" -count 5

# Rotate only when file exceeds 10MB
Invoke-FileRotate -filepath "C:\logs\app.log" `
                  -count 10 `
                  -size 10485760

# Get files to be deleted
Get-RotatedFilesToDelete -filepath "C:\logs\app.log" -count 5

# Read a file being written by another process
$content = Read-FileNonBlocking -Path "C:\logs\active.log"
```

### Remote File Operations

```powershell
# Copy file to remote share with credentials
$cred = Get-Credential
Copy-RemoteFile -source "C:\file.txt" `
                -destination "\\server\share\file.txt" `
                -Credential $cred `
                -Force

# Get remote drive information
Get-RemotePSDrive -computerName "Server01" `
                  -drive "C" `
                  -Credential $cred
```

### Path Manipulation

```powershell
# Split path into components
$pathInfo = Split-PathToHashTable -Path "C:\folder\file.txt"
# Returns: @{Root="C:"; Parent="C:\folder"; ItemName="file.txt";
#           ItemNameWithoutExt="file"; Extension="txt"; FullPath="C:\folder\file.txt"}

# Resolve path with environment variables
Resolve-PathWithVariables -Path "%TEMP%\log_%d:yyyyMMdd%.txt"
# Returns: C:\Users\Name\AppData\Local\Temp\log_20260212.txt

# Resolve path with custom variables
Resolve-PathWithVariables -Path "%CUSTOMDIR%\data\%FILENAME%" `
    -Hashtable @{CUSTOMDIR="C:\MyApp"; FILENAME="config.xml"}

# Get relative path
Resolve-RelativePath -From "C:\Project" -To "C:\Project\src\file.ps1"
# Returns: .\src\file.ps1
```

## Common Workflows

### Log File Rotation Setup

```powershell
# Scheduled task to rotate logs daily, keeping 30 days
$script = {
    Import-Module PSSomeFileThings
    Invoke-FileRotate -filepath "C:\logs\application.log" -count 30
}

# Register scheduled task
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-NoProfile -Command `"$script`""
$trigger = New-ScheduledTaskTrigger -Daily -At "23:00"
Register-ScheduledTask -TaskName "RotateAppLogs" `
    -Action $action `
    -Trigger $trigger
```

### Creating Deployment Package

```powershell
# Create deployment package with installer
# 1. Create archive
New-7ZipArchive -Content "C:\Build\Release" `
                -OutputArchivePath "C:\Deploy\app.7z" `
                -CompressionLevel 9

# 2. Create SFX config
New-SFXConfigFile -Title "Application v1.0 Setup" `
                  -ExecuteFile "install.bat" `
                  -ExecuteParameters "/quiet" `
                  -OutFilePath "C:\Deploy\config.txt"

# 3. Create self-extracting installer
New-7ZipSFX -SevenZipHeaderFile "C:\Tools\7z\7zSD.sfx" `
            -SFXConfigFile "C:\Deploy\config.txt" `
            -ArchiveFile "C:\Deploy\app.7z" `
            -OutFile "C:\Deploy\Setup.exe"
```

### Backup to Remote Location

```powershell
# Automated backup with rotation and remote copy
$cred = Get-Credential -Message "Enter credentials for backup share"

# Rotate local backup
Invoke-FileRotate -filepath "C:\Backups\database.bak" -count 7

# Copy to remote location
Copy-RemoteFile -source "C:\Backups\database.bak" `
                -destination "\\backupserver\backups\database.bak" `
                -Credential $cred `
                -Force
```

## Use Cases

1. **Log Management**: Automatic rotation and retention of application log files
2. **Software Distribution**: Creating self-extracting installers for deployment
3. **Backup Operations**: Rotating backup files and copying to remote storage
4. **Driver Packages**: Extracting and managing Windows CAB driver packages
5. **Path Normalization**: Standardizing paths with environment variable expansion
6. **Archive Creation**: Batch creation of compressed archives for distribution
7. **Remote Operations**: Copying files to network locations with authentication
8. **Live File Reading**: Reading log files that are actively being written

## Notes

- **7-Zip Operations**: Requires 7-Zip to be installed. By default, functions look for 7za.exe in the tools directory.
- **CAB Files**: Uses Windows built-in expand.exe utility, no additional installation required.
- **File Rotation**: Files are renamed with incrementing suffixes (file.log → file_1.log → file_2.log).
- **Remote Operations**: Requires appropriate network and firewall permissions for remote file access and PowerShell remoting.
- **Path Variables**: Supports environment variables (%VAR%), datetime patterns (%d:format%), and custom variables.

## License

This module is licensed under the **PolyForm Noncommercial License 1.0.0**.

See the [LICENSE](LICENSE) file for full license text.

**Required Notice**: Copyright Loïc Ade (https://github.com/qqt-lo4)

## Support

For issues, questions, or contributions, please contact the author.

## Version History

- **1.0.0** (Initial Release)
  - 7-Zip archive creation and SFX support
  - CAB file operations
  - File rotation with retention
  - Remote file operations
  - Advanced path manipulation
  - Non-blocking file reading
