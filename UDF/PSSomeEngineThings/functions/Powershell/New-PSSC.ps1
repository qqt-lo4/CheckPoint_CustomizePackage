function New-PSSC {
    <#
    .SYNOPSIS
        Create an object containing session configuration
    .DESCRIPTION
        Create an object containing session configuration
    .EXAMPLE
        PS C:\> <example usage>
        Explanation of what the example does
    .PARAMETER $SchemaVersion
        Version number of the schema used for this document
        Example value = '1.0.0.0'
    .PARAMETER $GUID
        ID used to uniquely identify this document
        Example value = '1caeff7f-27ca-4360-97cf-37846f594235'
    .PARAMETER $Author
        Author of this document
        Example value = 'User01'
    .PARAMETER $Description
        Description of the functionality provided by these settings
        Example value = 'This is a sample file.'
    .PARAMETER $CompanyName
        Company associated with this document
        Example value = 'Fabrikam Corporation'
    .PARAMETER $Copyright
        Copyright statement for this document
        Example value = '(c) Fabrikam Corporation. All rights reserved.'
    .PARAMETER $SessionType
        Session type defaults to apply for this session configuration. Can be 'RestrictedRemoteServer' (recommended), 'Empty', or 'Default'
        Example value = 'Default'
    .PARAMETER $TranscriptDirectory
        Directory to place session transcripts for this session configuration
        Example value = 'C:\Transcripts\'
    .PARAMETER $RunAsVirtualAccount
        Whether to run this session configuration as the machine's (virtual) administrator account
        Example value = $true
    .PARAMETER $RunAsVirtualAccountGroups
        Groups associated with machine's (virtual) administrator account
        Example value = 'Backup Operators'
    .PARAMETER $ScriptsToProcess
        Scripts to run when applied to a session
        Example value = 'Get-Inputs.ps1'
    .PARAMETER $RoleDefinitions
        User roles (security groups), and the role capabilities that should be applied to them when applied to a session
        Example value = @{ 'CONTOSO\SqlAdmins' = @{ RoleCapabilities = 'SqlAdministration' }; 'CONTOSO\SqlManaged' = @{ RoleCapabilityFiles = 'C:\RoleCapability\SqlManaged.psrc' }; 'CONTOSO\ServerMonitors' = @{ VisibleCmdlets = 'Get-Process' } }
    .PARAMETER $LanguageMode
        Language mode to apply when applied to a session. Can be 'NoLanguage' (recommended), 'RestrictedLanguage', 'ConstrainedLanguage', or 'FullLanguage'
        Example value = 'FullLanguage'
    .PARAMETER $ExecutionPolicy
        Execution policy to apply when applied to a session
        Example value = 'AllSigned'
    .PARAMETER $PowerShellVersion
        Version of the PowerShell engine to use when applied to a session
        Example value = '3.0'
    .PARAMETER $ModulesToImport
        Modules to import when applied to a session
        Example value = @{
            'GUID' = '50cdb55f-5ab7-489f-9e94-4ec21ff51e59'
            'ModuleName' = 'PSScheduledJob'
            'ModuleVersion' = '1.0.0.0' }, 'PSDiagnostics'
    .PARAMETER $VisibleAliases
        Aliases to make visible when applied to a session
        Example value = 'c*', 'g*', 'i*', 's*'
    .PARAMETER $VisibleCmdlets
        Cmdlets to make visible when applied to a session
        Example value = 'Get*'
    .PARAMETER $VisibleFunctions
        Functions to make visible when applied to a session
        Example value = 'Get*'
    .PARAMETER $VisibleProviders
        Providers to make visible when applied to a session
        Example value = 'FileSystem', 'Function', 'Variable'
    .PARAMETER $AliasDefinitions
        Aliases to be defined when applied to a session
        Example value = @{
            'Description' = 'Gets help.'
            'Name' = 'hlp'
            'Options' = 'AllScope'
            'Value' = 'Get-Help' }, @{
            'Description' = 'Updates help'
            'Name' = 'Update'
            'Options' = 'ReadOnly'
            'Value' = 'Update-Help' }
    .PARAMETER $FunctionDefinitions
        Functions to define when applied to a session
        Example value = @{
            'Name' = 'Get-Function'
            'Options' = 'ReadOnly'
            'ScriptBlock' = {Get-Command -CommandType Function} }
    .PARAMETER $VariableDefinitions
        Variables to define when applied to a session
        Example value = @{
            'Name' = 'WarningPreference'
            'Value' = 'SilentlyContinue' }
    .PARAMETER $EnvironmentVariables
        Environment variables to define when applied to a session
        Example value = @{ 'TESTSHARE' = '\\Test2\Test' }
    .PARAMETER $TypesToProcess
        Type files (.ps1xml) to load when applied to a session
        Example value = 'Types1.ps1xml', 'Types2.ps1xml'
    .PARAMETER $FormatsToProcess
        Format files (.ps1xml) to load when applied to a session
        Example value = 'CustomFormats.ps1xml'
    .PARAMETER $AssembliesToLoad
        Assemblies to load when applied to a session
        Example value = 'System.Web.Services', 'FSharp.Compiler.CodeDom.dll'
    .OUTPUTS
        Output (if any)
    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
        Example values taken from https://docs.microsoft.com/en-us/powershell/module/Microsoft.PowerShell.Core/New-PSSessionConfigurationFile
    #>
    Param(
        [ValidateNotNull()]
        [Version]$SchemaVersion,

        [Guid]$Guid,

        [string]$Author,

        [string]$Description,

        [string]$CompanyName,

        [string]$Copyright,

        [System.Management.Automation.Remoting.SessionType]$SessionType,

        [string]$TranscriptDirectory,

        [switch]$RunAsVirtualAccount,

        [string[]]$RunAsVirtualAccountGroups,

        [switch]$MountUserDrive,

        [Int64]$UserDriveMaximumSize,

        [string]$GroupManagedServiceAccount,

        [string[]]$ScriptsToProcess,

        [hashtable]$RoleDefinitions,

        [System.Collections.IDictionary]$RequiredGroups,

        [System.Management.Automation.PSLanguageMode]$LanguageMode,

        [Microsoft.PowerShell.ExecutionPolicy]$ExecutionPolicy,

        [Version]$PowerShellVersion,

        [Object[]]$ModulesToImport,

        [string[]]$VisibleAliases,

        [Object[]]$VisibleCmdlets,

        [Object[]]$VisibleFunctions,

        [string[]]$VisibleExternalCommands,

        [string[]]$VisibleProviders,
        [System.Collections.IDictionary[]]$AliasDefinitions,

        [System.Collections.IDictionary[]]$FunctionDefinitions,

        [Object]$VariableDefinitions,

        [System.Collections.IDictionary]$EnvironmentVariables,

        [string[]]$TypesToProcess,

        [string[]]$FormatsToProcess,

        [string[]]$AssembliesToLoad,

        [switch]$Full
    )
    $result = @{}
    
    if ($SchemaVersion) {$result.Add("SchemaVersion", $SchemaVersion)}
    if ($GUID) {$result.add("GUID", $GUID)}
    if ($Author) {$result.add("Author", $Author)}
    if ($Description) {$result.add("Description", $Description)}
    if ($CompanyName) {$result.add("CompanyName", $CompanyName)}
    if ($Copyright) {$result.add("Copyright", $Copyright)}
    if ($SessionType) {$result.add("SessionType", $SessionType)}
    if ($TranscriptDirectory) {$result.add("TranscriptDirectory", $TranscriptDirectory)}
    if ($RunAsVirtualAccount) {$result.add("RunAsVirtualAccount", $RunAsVirtualAccount.IsPresent)}
    if ($RunAsVirtualAccountGroups) {$result.add("RunAsVirtualAccountGroups", $RunAsVirtualAccountGroups)}
    if ($ScriptsToProcess) {$result.add("ScriptsToProcess", $ScriptsToProcess)}
    if ($RoleDefinitions) {$result.add("RoleDefinitions", $RoleDefinitions)}
    if ($LanguageMode) {$result.add("LanguageMode", $LanguageMode)}
    if ($ExecutionPolicy) {$result.add("ExecutionPolicy", $ExecutionPolicy)}
    if ($PowerShellVersion) {$result.add("PowerShellVersion", $PowerShellVersion)}
    if ($ModulesToImport) {$result.add("ModulesToImport", $ModulesToImport)}
    if ($VisibleAliases) {$result.add("VisibleAliases", $VisibleAliases)}
    if ($VisibleCmdlets) {$result.add("VisibleCmdlets", $VisibleCmdlets)}
    if ($VisibleFunctions) {$result.add("VisibleFunctions", $VisibleFunctions)}
    if ($VisibleProviders) {$result.add("VisibleProviders", $VisibleProviders)}
    if ($AliasDefinitions) {$result.add("AliasDefinitions", $AliasDefinitions)}
    if ($FunctionDefinitions) {$result.add("FunctionDefinitions", $FunctionDefinitions)}
    if ($VariableDefinitions) {$result.add("VariableDefinitions", $VariableDefinitions)}
    if ($EnvironmentVariables) {$result.add("EnvironmentVariables", $EnvironmentVariables)}
    if ($TypesToProcess) {$result.add("TypesToProcess", $TypesToProcess)}
    if ($FormatsToProcess) {$result.add("FormatsToProcess", $FormatsToProcess)}
    if ($AssembliesToLoad) {$result.add("AssembliesToLoad", $AssembliesToLoad)}

    return $result
}