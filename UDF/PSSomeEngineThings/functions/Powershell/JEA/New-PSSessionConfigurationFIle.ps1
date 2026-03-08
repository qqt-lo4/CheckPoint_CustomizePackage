function New-PSSessionConfigurationFile {
    <#
    .SYNOPSIS
        Creates a PowerShell session configuration file

    .DESCRIPTION
        Generates a .pssc file with JEA session configuration settings. Supports all standard
        session configuration options including role definitions, language mode, execution policy,
        and visible commands.

    .PARAMETER Path
        Path where the .pssc file will be created.

    .PARAMETER SchemaVersion
        Version of the schema (default: auto-generated).

    .PARAMETER Guid
        Unique identifier for this configuration.

    .PARAMETER Author
        Author name (default: current user).

    .PARAMETER Description
        Description of the session configuration.

    .PARAMETER CompanyName
        Company name.

    .PARAMETER Copyright
        Copyright statement.

    .PARAMETER SessionType
        Session type (RestrictedRemoteServer, Empty, or Default).

    .PARAMETER TranscriptDirectory
        Directory for session transcripts.

    .PARAMETER RunAsVirtualAccount
        Run as virtual administrator account.

    .PARAMETER RunAsVirtualAccountGroups
        Groups for virtual account.

    .PARAMETER RoleDefinitions
        User roles and their capabilities.

    .PARAMETER LanguageMode
        PowerShell language mode.

    .PARAMETER ModulesToImport
        Modules to import.

    .PARAMETER VisibleCmdlets
        Cmdlets to make visible.

    .PARAMETER VisibleFunctions
        Functions to make visible.

    .OUTPUTS
        None. Creates a .pssc file at the specified path.

    .EXAMPLE
        New-PSSessionConfigurationFile -Path "C:\JEA\config.pssc" -SessionType RestrictedRemoteServer

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        
        [ValidateNotNull()]
        [Version]$SchemaVersion,
        
        [Guid]$Guid = (New-Guid),
        
        [string]$Author = $env:USERNAME,

        [string]$Description,

        [string]$CompanyName = "Unknown",

        [string]$Copyright = "(c) $env:USERNAME. All rights reserved.",

        [System.Management.Automation.Remoting.SessionType]$SessionType,

        [string]$TranscriptDirectory,

        [switch]$RunAsVirtualAccount,

        [string[]]$RunAsVirtualAccountGroups,

        [switch]$MountUserDrive,

        [Int64]$UserDriveMaximumSize,

        [string]$GroupManagedServiceAccount,

        [string[]]$ScriptsToProcess,

        [hashtable]$RoleDefinitions,

        [hashtable]$RequiredGroups,

        [System.Management.Automation.PSLanguageMode]$LanguageMode,

        [Microsoft.PowerShell.ExecutionPolicy]$ExecutionPolicy,

        [Version]$PowerShellVersion,

        [Object[]]$ModulesToImport,

        [string[]]$VisibleAliases,

        [Object[]]$VisibleCmdlets,

        [Object[]]$VisibleFunctions,

        [string[]]$VisibleExternalCommands,

        [string[]]$VisibleProviders,

        [hashtable[]]$AliasDefinitions,

        [hashtable[]]$FunctionDefinitions,

        [Object]$VariableDefinitions,

        [hashtable]$EnvironmentVariables,

        [string[]]$TypesToProcess,

        [string[]]$FormatsToProcess,

        [string[]]$AssembliesToLoad,

        [switch]$Full

    )
    Begin {
        function Convert-PSSCListToString {
            Param(
                [Parameter(Mandatory, Position = 0)]
                [object]$PSSCInput
            )
            if ($PSSCInput -is [array]) {
                $itemsArray = @()
                foreach ($item in $PSSCInput) {
                    $itemsArray += (Convert-PSSCListToString $item)
                }
                return ($itemsArray -join ", ")
            } elseif ($PSSCInput -is [string]) {
                return "`'" + $PSSCInput + "`'"
            } elseif ($PSSCInput -is [hashtable]) {
                $aHToSResult = @()
                foreach ($prop in $PSSCInput.Keys) {
                    $aHToSResult += ("$prop = " + (Convert-PSSCListToString $PSSCInput[$prop]))
                }
                return ("{" + ($aHToSResult -join " ; ") + "}")
            } elseif ($PSSCInput -is [bool]) {
                if ($PSSCInput) { return "`$true" } else { return "`$false" }
            } else {
                return $PSSCInput.ToString()
            }
        }   

        function Add-LineToResult {
            Param(
                [AllowNull()]
                [object]$Var,
                [object]$VarName,
                [string]$Comment,
                [string]$DefaultValueIfEmpty,
                [ref]$ArrayResult
            )
            $ArrayResult.Value += "# $Comment`n"
            if ($null -eq $Var) {
                $ArrayResult.Value += "# $VarName = " + $DefaultValueIfEmpty + "`n`n"
            } else {
                $ArrayResult.Value += "$VarName = " + (Convert-PSSCListToString $Var) + "`n`n"
            }
        }
    }

    Process {
        $aResult = "@{`n`n"
        
        Add-LineToResult -Var $SchemaVersion -VarName "SchemaVersion" -Comment "Version number of the schema used for this document" -ValueIfEmpty "'2.0.0.0'" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $GUID -VarName "GUID" -Comment "ID used to uniquely identify this document" -ValueIfEmpty "'814032d4-d8c9-429f-babf-d1668db7cebb'" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $Author -VarName "Author" -Comment "Author of this document" -ValueIfEmpty "'Administrator'" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $Description -VarName "Description" -Comment "Description of the functionality provided by these settings" -ValueIfEmpty "''" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $CompanyName -VarName "CompanyName" -Comment "Company associated with this document" -ValueIfEmpty "'Unknown'" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $Copyright -VarName "Copyright" -Comment "Copyright statement for this document" -ValueIfEmpty "'(c) 2022 Administrator. All rights reserved.'" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $SessionType -VarName "SessionType" -Comment "Session type defaults to apply for this session configuration. Can be 'RestrictedRemoteServer' (recommended), 'Empty', or 'Default'" -ValueIfEmpty "'Default'" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $TranscriptDirectory -VarName "TranscriptDirectory" -Comment "Directory to place session transcripts for this session configuration" -ValueIfEmpty "'C:\Transcripts\'" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $RunAsVirtualAccount.IsPresent -VarName "RunAsVirtualAccount" -Comment "Whether to run this session configuration as the machine's (virtual) administrator account" -ValueIfEmpty "`$true" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $RunAsVirtualAccountGroups -VarName "RunAsVirtualAccountGroups" -Comment "Groups associated with machine's (virtual) administrator account" -ValueIfEmpty "'Remote Desktop Users', 'Remote Management Users'" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $MountUserDrive.IsPresent -VarName "MountUserDrive" -Comment "Creates a 'User' PSDrive in the session for use with Copy-Item when File System provider is not visible." -ValueIfEmpty "`$true" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $UserDriveMaximumSize -VarName "UserDriveMaximumSize" -Comment "Optional maximum size in bytes of user drive created with MountUserDrive parameter. Default maximum size for User drive is 50MB." -ValueIfEmpty "50000000" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $GroupManagedServiceAccount -VarName "GroupManagedServiceAccount" -Comment "Group managed service account name under which the configuration will run" -ValueIfEmpty "'CONTOSO\GroupManagedServiceAccount'" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $ScriptsToProcess -VarName "ScriptsToProcess" -Comment "Scripts to run when applied to a session" -ValueIfEmpty "'C:\ConfigData\InitScript1.ps1', 'C:\ConfigData\InitScript2.ps1'" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $RoleDefinitions -VarName "RoleDefinitions" -Comment "User roles (security groups), and the role capabilities that should be applied to them when applied to a session" -ValueIfEmpty "@{ 'CONTOSO\SqlAdmins' = @{ RoleCapabilities = 'SqlAdministration' }; 'CONTOSO\SqlManaged' = @{ RoleCapabilityFiles = 'C:\RoleCapability\SqlManaged.psrc' }; 'CONTOSO\ServerMonitors' = @{ VisibleCmdlets = 'Get-Process' } } " -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $RequiredGroups -VarName "RequiredGroups" -Comment "Group accounts for which membership is required to use the session." -ValueIfEmpty "@{ And = @{ Or = 'CONTOSO\SmartCard-Logon1', 'CONTOSO\SmartCard-Logon2' }, 'Administrators' }" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $LanguageMode -VarName "LanguageMode" -Comment "Language mode to apply when applied to a session. Can be 'NoLanguage' (recommended), 'RestrictedLanguage', 'ConstrainedLanguage', or 'FullLanguage'" -ValueIfEmpty "'FullLanguage'" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $ExecutionPolicy -VarName "ExecutionPolicy" -Comment "Execution policy to apply when applied to a session" -ValueIfEmpty "'Restricted'" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $PowerShellVersion -VarName "PowerShellVersion" -Comment "Version of the Windows PowerShell engine to use  when applied to a session" -ValueIfEmpty "'5.1.20348.320'" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $ModulesToImport -VarName "ModulesToImport" -Comment "Modules to import when applied to a session" -ValueIfEmpty "'MyCustomModule', @{ ModuleName = 'MyCustomModule'; ModuleVersion = '1.0.0.0'; GUID = '4d30d5f0-cb16-4898-812d-f20a6c596bdf' }" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $VisibleAliases -VarName "VisibleAliases" -Comment "Aliases to make visible when applied to a session" -ValueIfEmpty "'Item1', 'Item2'" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $VisibleCmdlets -VarName "VisibleCmdlets" -Comment "Cmdlets to make visible when applied to a session" -ValueIfEmpty "'Invoke-Cmdlet1', @{ Name = 'Invoke-Cmdlet2'; Parameters = @{ Name = 'Parameter1'; ValidateSet = 'Item1', 'Item2' }, @{ Name = 'Parameter2'; ValidatePattern = 'L*' } }" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $VisibleFunctions -VarName "VisibleFunctions" -Comment "Functions to make visible when applied to a session" -ValueIfEmpty "'Invoke-Function1', @{ Name = 'Invoke-Function2'; Parameters = @{ Name = 'Parameter1'; ValidateSet = 'Item1', 'Item2' }, @{ Name = 'Parameter2'; ValidatePattern = 'L*' } }" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $VisibleExternalCommands -VarName "VisibleExternalCommands" -Comment "External commands (scripts and applications) to make visible when applied to a session" -ValueIfEmpty "'Item1', 'Item2'" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $VisibleProviders -VarName "VisibleProviders" -Comment "Providers to make visible when applied to a session" -ValueIfEmpty "'Item1', 'Item2'" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $AliasDefinitions -VarName "AliasDefinitions" -Comment "Aliases to be defined when applied to a session" -ValueIfEmpty "@{ Name = 'Alias1'; Value = 'Invoke-Alias1'}, @{ Name = 'Alias2'; Value = 'Invoke-Alias2'}" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $FunctionDefinitions -VarName "FunctionDefinitions" -Comment "Functions to define when applied to a session" -ValueIfEmpty "@{ Name = 'MyFunction'; ScriptBlock = { param($MyInput) $MyInput } }" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $VariableDefinitions -VarName "VariableDefinitions" -Comment "Variables to define when applied to a session" -ValueIfEmpty "@{ Name = 'Variable1'; Value = { 'Dynamic' + 'InitialValue' } }, @{ Name = 'Variable2'; Value = 'StaticInitialValue' }" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $EnvironmentVariables -VarName "EnvironmentVariables" -Comment "Environment variables to define when applied to a session" -ValueIfEmpty "@{ Variable1 = 'Value1'; Variable2 = 'Value2' }" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $TypesToProcess -VarName "TypesToProcess" -Comment "Type files (.ps1xml) to load when applied to a session" -ValueIfEmpty "'C:\ConfigData\MyTypes.ps1xml', 'C:\ConfigData\OtherTypes.ps1xml'" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $FormatsToProcess -VarName "FormatsToProcess" -Comment "Format files (.ps1xml) to load when applied to a session" -ValueIfEmpty "'C:\ConfigData\MyFormats.ps1xml', 'C:\ConfigData\OtherFormats.ps1xml'" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $AssembliesToLoad -VarName "AssembliesToLoad" -Comment "Assemblies to load when applied to a session" -ValueIfEmpty "'System.Web', 'System.OtherAssembly, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a'" -ArrayResult ([ref]$aResult)

        $aResult += "}"

        $aResult | Out-File -FilePath $Path
    }

    End {}
}