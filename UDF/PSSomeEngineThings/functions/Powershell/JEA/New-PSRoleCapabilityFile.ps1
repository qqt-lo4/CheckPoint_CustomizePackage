function New-PSRoleCapabilityFile {
    <#
    .SYNOPSIS
        Creates a PowerShell role capability file

    .DESCRIPTION
        Generates a .psrc file defining JEA role capabilities. Specifies which cmdlets, functions,
        and external commands are available to users in a JEA role.

    .PARAMETER Path
        Path where the .psrc file will be created.

    .PARAMETER Guid
        Unique identifier for this role capability.

    .PARAMETER Author
        Author name (default: current user).

    .PARAMETER Description
        Description of the role capability.

    .PARAMETER CompanyName
        Company name.

    .PARAMETER Copyright
        Copyright statement.

    .PARAMETER ModulesToImport
        Modules to import for this role.

    .PARAMETER VisibleAliases
        Aliases to make visible.

    .PARAMETER VisibleCmdlets
        Cmdlets to make visible.

    .PARAMETER VisibleFunctions
        Functions to make visible.

    .PARAMETER VisibleExternalCommands
        External commands to make visible.

    .PARAMETER ScriptsToProcess
        Scripts to run when role is applied.

    .OUTPUTS
        None. Creates a .psrc file at the specified path.

    .EXAMPLE
        New-PSRoleCapabilityFile -Path "C:\JEA\Roles\Operator.psrc" -VisibleCmdlets "Get-Service","Restart-Service"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Guid]$Guid = (New-Guid),

        [string]$Author = $env:USERNAME,

        [string]$Description,

        [string]$CompanyName = "Unknown",

        [string]$Copyright = "(c) $env:USERNAME. All rights reserved.",

        [Object[]]$ModulesToImport,

        [string[]]$VisibleAliases,

        [Object[]]$VisibleCmdlets,

        [Object[]]$VisibleFunctions,

        [string[]]$VisibleExternalCommands,

        [string[]]$VisibleProviders,

        [string[]]$ScriptsToProcess,

        [System.Collections.IDictionary[]]$AliasDefinitions,

        [System.Collections.IDictionary[]]$FunctionDefinitions,

        [Object]$VariableDefinitions,

        [System.Collections.IDictionary]$EnvironmentVariables,

        [string[]]$TypesToProcess,

        [string[]]$FormatsToProcess,

        [string[]]$AssembliesToLoad
    )

    Begin {
        function Convert-PSRCListToString {
            Param(
                [Parameter(Mandatory, Position = 0)]
                [object]$PSRCInput
            )
            if ($PSRCInput -is [array]) {
                $itemsArray = @()
                foreach ($item in $PSRCInput) {
                    $itemsArray += (Convert-PSRCListToString $item)
                }
                return ($itemsArray -join ", ")
            } elseif ($PSRCInput -is [string]) {
                return "`'" + $PSRCInput + "`'"
            } elseif ($PSRCInput -is [hashtable]) {
                $aHToSResult = @()
                foreach ($prop in $PSRCInput.Keys) {
                    $aHToSResult += ("$prop = " + (Convert-PSRCListToString $PSRCInput[$prop]))
                }
                return ("@{" + ($aHToSResult -join " ; ") + "}")
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
                $ArrayResult.Value += "$VarName = " + (Convert-PSRCListToString $Var) + "`n`n"
            }
        }
    }

    Process {
        $aResult = "@{`n`n"
        
        Add-LineToResult -Var $Guid.ToString() -VarName "GUID" -Comment "ID used to uniquely identify this document" -DefaultValueIfEmpty "''" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $Author -VarName "Author" -Comment "Author of this document" -DefaultValueIfEmpty "''" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $Description -VarName "Description" -Comment "Description of the functionality provided by these settings" -DefaultValueIfEmpty "''" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $CompanyName -VarName "CompanyName" -Comment "Company associated with this document" -DefaultValueIfEmpty "'Unknown'" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $Copyright -VarName "Copyright" -Comment "Copyright statement for this document" -DefaultValueIfEmpty "'(c) $env:USERNAME. All rights reserved.'" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $ModulesToImport -VarName "ModulesToImport" -Comment "Modules to import when applied to a session" -DefaultValueIfEmpty "'MyCustomModule', @{ ModuleName = 'MyCustomModule'; ModuleVersion = '1.0.0.0'; GUID = '4d30d5f0-cb16-4898-812d-f20a6c596bdf' }" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $VisibleAliases -VarName "VisibleAliases" -Comment "Aliases to make visible when applied to a session" -DefaultValueIfEmpty "'Item1', 'Item2'" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $VisibleCmdlets -VarName "VisibleCmdlets" -Comment "Cmdlets to make visible when applied to a session" -DefaultValueIfEmpty "'Invoke-Cmdlet1', @{ Name = 'Invoke-Cmdlet2'; Parameters = @{ Name = 'Parameter1'; ValidateSet = 'Item1', 'Item2' }, @{ Name = 'Parameter2'; ValidatePattern = 'L*' } }" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $VisibleFunctions -VarName "VisibleFunctions" -Comment "Functions to make visible when applied to a session" -DefaultValueIfEmpty "'Invoke-Function1', @{ Name = 'Invoke-Function2'; Parameters = @{ Name = 'Parameter1'; ValidateSet = 'Item1', 'Item2' }, @{ Name = 'Parameter2'; ValidatePattern = 'L*' } }" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $VisibleExternalCommands -VarName "VisibleExternalCommands" -Comment "External commands (scripts and applications) to make visible when applied to a session" -DefaultValueIfEmpty "'Item1', 'Item2'" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $ScriptsToProcess -VarName "ScriptsToProcess" -Comment "Scripts to run when applied to a session" -DefaultValueIfEmpty "'C:\ConfigData\InitScript1.ps1', 'C:\ConfigData\InitScript2.ps1'" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $AliasDefinitions -VarName "AliasDefinitions" -Comment "Aliases to be defined when applied to a session" -DefaultValueIfEmpty "@{ Name = 'Alias1'; Value = 'Invoke-Alias1'}, @{ Name = 'Alias2'; Value = 'Invoke-Alias2'}" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $FunctionDefinitions -VarName "FunctionDefinitions" -Comment "Functions to define when applied to a session" -DefaultValueIfEmpty "@{ Name = 'MyFunction'; ScriptBlock = { param(`$MyInput) $`MyInput } }" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $VariableDefinitions -VarName "VariableDefinitions" -Comment "Variables to define when applied to a session" -DefaultValueIfEmpty "@{ Name = 'Variable1'; Value = { 'Dynamic' + 'InitialValue' } }, @{ Name = 'Variable2'; Value = 'StaticInitialValue' }" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $EnvironmentVariables -VarName "EnvironmentVariables" -Comment "Environment variables to define when applied to a session" -DefaultValueIfEmpty "@{ Variable1 = 'Value1'; Variable2 = 'Value2' }" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $TypesToProcess -VarName "TypesToProcess" -Comment "Type files (.ps1xml) to load when applied to a session" -DefaultValueIfEmpty "'C:\ConfigData\MyTypes.ps1xml', 'C:\ConfigData\OtherTypes.ps1xml'" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $FormatsToProcess -VarName "FormatsToProcess" -Comment "Format files (.ps1xml) to load when applied to a session" -DefaultValueIfEmpty "'C:\ConfigData\MyFormats.ps1xml', 'C:\ConfigData\OtherFormats.ps1xml'" -ArrayResult ([ref]$aResult)
        Add-LineToResult -Var $AssembliesToLoad -VarName "AssembliesToLoad" -Comment "Assemblies to load when applied to a session" -DefaultValueIfEmpty "'System.Web', 'System.OtherAssembly, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a'" -ArrayResult ([ref]$aResult)

        $aResult += "}"

        $aResult | Out-File -FilePath $Path
    }

    End {}
}

