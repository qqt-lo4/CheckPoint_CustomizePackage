function New-PSRC {
    <#
    .SYNOPSIS
        Create a PSRC content
    .DESCRIPTION
        Create a PSRC content, to be used with New-PSRoleCapabilityFile cmdlet
    .EXAMPLE
        
    .PARAMETER $GUID
        Unique ID used to identify this document
        Example value = 'dae8a39d-707f-497e-bc09-551e2dac3365'
    .PARAMETER $Author
        Author of the PSRC item
    .PARAMETER $Description
        Features description of these parameters
    .PARAMETER $CompanyName
        Company associated with this document
    .PARAMETER $Copyright
        Copyright instruction for this document
        Example value = '(c) 2022 Loic. All rights reserved.'
    .PARAMETER $ModulesToImport
        Modules to import when they apply to a session
        Example value = 'MyCustomModule', @{ ModuleName = 'MyCustomModule'; ModuleVersion = '1.0.0.0'; GUID = '4d30d5f0-cb16-4898-812d-f20a6c596bdf' }
    .PARAMETER $VisibleAliases
        Aliases to be made visible when they apply to a session
        Example value = 'Item1', 'Item2'
    .PARAMETER $VisibleCmdlets
        Cmdlets to make visible when applied to a session
        Example value = 'Invoke-Cmdlet1', @{ Name = 'Invoke-Cmdlet2'; Parameters = @{ Name = 'Parameter1'; ValidateSet = 'Item1', 'Item2' }, @{ Name = 'Parameter2'; ValidatePattern = 'L*' } }
    .PARAMETER $VisibleFunctions
        Functions to be made visible when they apply to a session
        Example value = 'Invoke-Function1', @{ Name = 'Invoke-Function2'; Parameters = @{ Name = 'Parameter1'; ValidateSet = 'Item1', 'Item2' }, @{ Name = 'Parameter2'; ValidatePattern = 'L*' } }
    .PARAMETER $VisibleExternalCommands
        External commands (scripts and applications) to be made visible when they apply to a session
        Example value = 'Item1', 'Item2'
    .PARAMETER $VisibleProviders
        Suppliers to be made visible when they apply to a session
        Example value = 'Item1', 'Item2'
    .PARAMETER $ScriptsToProcess
        Scripts to run when applied to a session
        Example value = 'C:\ConfigData\InitScript1.ps1', 'C:\ConfigData\InitScript2.ps1'
    .PARAMETER $AliasDefinitions
        Alias ​​to define when they apply to a session
        Example value = @{ Name = 'Alias1'; Value = 'Invoke-Alias1'}, @{ Name = 'Alias2'; Value = 'Invoke-Alias2'}
    .PARAMETER $FunctionDefinitions
        Functions to define when they apply to a session
        Example value = @{ Name = 'MyFunction'; ScriptBlock = { param($MyInput) $MyInput } }
    .PARAMETER $VariableDefinitions
        Variables to define when they apply to a session
        Example value = @{ Name = 'Variable1'; Value = { 'Dynamic' + 'InitialValue' } }, @{ Name = 'Variable2'; Value = 'StaticInitialValue' }
    .PARAMETER $EnvironmentVariables
        Environment variables to define when they apply to a session
        Example value = @{ Variable1 = 'Value1'; Variable2 = 'Value2' }
    .PARAMETER $TypesToProcess
        Files of type (.ps1xml) to load when they apply to a session
        Example value = 'C:\ConfigData\MyTypes.ps1xml', 'C:\ConfigData\OtherTypes.ps1xml'
    .PARAMETER $FormatsToProcess
        Format files (.ps1xml) to load when they apply to a session
        Example value = 'C:\ConfigData\MyFormats.ps1xml', 'C:\ConfigData\OtherFormats.ps1xml'
    .PARAMETER $AssembliesToLoad 
        Assemblies to load when applied to a session
        Example value = 'System.Web', 'System.OtherAssembly, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a'
    .OUTPUTS
        A hashtable with all parameters
    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [string]$GUID = (New-Guid),
        [string]$Author = ($env:USERNAME),
        [string]$Description,
        [string]$Copyright,
        [string]$CompanyName = $env:USERDOMAIN,
        [object[]]$ModulesToImport,
        [string[]]$VisibleAliases,
        [object[]]$VisibleCmdlets,
        [object[]]$VisibleFunctions,
        [string[]]$VisibleExternalCommands,
        [string[]]$VisibleProviders,
        [string[]]$ScriptsToProcess,
        [object[]]$AliasDefinitions,
        [object[]]$FunctionDefinitions,
        [object[]]$VariableDefinitions,
        [object[]]$EnvironmentVariables,
        [string[]]$TypesToProcess,
        [string[]]$FormatsToProcess,
        [string[]]$AssembliesToLoad
    )
    $hPSRCresult = @{}
    if ($GUID) { $hPSRCresult.Add("GUID", $GUID) }
    if ($Author) { $hPSRCresult.Add("Author", $Author) }
    if ($Description) { $hPSRCresult.Add("Description", $Description) }
    if ($CompanyName) { $hPSRCresult.Add("CompanyName", $CompanyName) }
    if ($Copyright) { $hPSRCresult.Add("Copyright", $Copyright) }
    if ($ModulesToImport) { $hPSRCresult.Add("ModulesToImport", $ModulesToImport) }
    if ($VisibleAliases) { $hPSRCresult.Add("VisibleAliases", $VisibleAliases) }
    if ($VisibleCmdlets) { $hPSRCresult.Add("VisibleCmdlets", $VisibleCmdlets) }
    if ($VisibleFunctions) { $hPSRCresult.Add("VisibleFunctions", $VisibleFunctions) }
    if ($VisibleExternalCommands) { $hPSRCresult.Add("VisibleExternalCommands", $VisibleExternalCommands) }
    if ($VisibleProviders) { $hPSRCresult.Add("VisibleProviders", $VisibleProviders) }
    if ($ScriptsToProcess) { $hPSRCresult.Add("ScriptsToProcess", $ScriptsToProcess) }
    if ($AliasDefinitions) { $hPSRCresult.Add("AliasDefinitions", $AliasDefinitions) }
    if ($FunctionDefinitions) { $hPSRCresult.Add("FunctionDefinitions", $FunctionDefinitions) }
    if ($VariableDefinitions) { $hPSRCresult.Add("VariableDefinitions", $VariableDefinitions) }
    if ($EnvironmentVariables) { $hPSRCresult.Add("EnvironmentVariables", $EnvironmentVariables) }
    if ($TypesToProcess) { $hPSRCresult.Add("TypesToProcess", $TypesToProcess) }
    if ($FormatsToProcess) { $hPSRCresult.Add("FormatsToProcess", $FormatsToProcess) }
    if ($AssembliesToLoad) { $hPSRCresult.Add("AssembliesToLoad", $AssembliesToLoad) }
    return $hPSRCresult
}