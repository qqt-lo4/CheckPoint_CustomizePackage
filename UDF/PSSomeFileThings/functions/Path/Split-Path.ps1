function Split-Path {
    <#
    .SYNOPSIS
        Extended Split-Path with hashtable output option

    .DESCRIPTION
        Proxy function for Split-Path cmdlet with additional hashtable parameter set.
        Returns path components (Root, Parent, ItemName, Extension, etc.) as a hashtable.

    .PARAMETER Path
        Path to split.

    .PARAMETER Parent
        Return parent directory.

    .PARAMETER Leaf
        Return file/folder name.

    .PARAMETER Qualifier
        Return drive qualifier.

    .PARAMETER NoQualifier
        Return path without qualifier.

    .PARAMETER IsAbsolute
        Test if path is absolute.

    .PARAMETER Resolve
        Resolve path to actual location.

    .PARAMETER Hashtable
        Return path components as hashtable.

    .OUTPUTS
        [String] or [Hashtable]. Path component or hashtable of all components.

    .EXAMPLE
        Split-Path -Path "C:\folder\file.txt" -Hashtable

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding(DefaultParameterSetName="ParentSet")]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "NoQualifierSet", Position = 0)]
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "LeafSet", Position = 0)]
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "QualifierSet", Position = 0)]
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "ParentSet", Position = 0)]
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "IsAbsoluteSet", Position = 0)]
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "Hashtable", Position = 0)]
        [string[]]$Path,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = "ParentSet")]
        [switch]$Parent,

        [switch]$Resolve,

        [Parameter(ValueFromPipelineByPropertyName)]
        [PSCredential]$Credential,

        [Alias("usetx")]
        [switch]$UseTransaction,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = "NoQualifierSet")]
        [switch]$NoQualifier,

        [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = "LeafSet")]
        [switch]$Leaf,

        [Parameter(Position = 1, ValueFromPipelineByPropertyName, ParameterSetName = "QualifierSet")]
        [switch]$Qualifier,

        [Parameter(ParameterSetName = "IsAbsoluteSet")]
        [switch]$IsAbsolute,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = "LiteralPathSet")]
        [Alias("PSPath")]
        [string[]]$LiteralPath,

        [Parameter(ParameterSetName = "Hashtable")]
        [switch]$Hashtable
    )
    switch ($PSCmdlet.ParameterSetName) {
        "hashtable" {
            $sWindowsPathRegEx = "^(?<fullpath>(?<parent>(?<root>([^:]+):)\\.+)(\\((?<itemname>[^\\]+))))\\?$"
            if ($Path[0] -match $sWindowsPathRegEx) {
                $sRoot = $Matches.root
                $sParent = $Matches.parent
                $sItemName = $Matches.itemname
                $sFullPath = $Matches.fullpath
                if ($sItemName -match "^(?<itemnamewithoutext>.+)(\.(?<ext>[^.]+))$") {
                    $sItemNameWithoutExt = $Matches.itemnamewithoutext
                    $sExtension = $Matches.ext
                }
                $hResult = [ordered]@{
                    "Root" = $sRoot
                    "Parent" = $sParent
                    "ItemName" = $sItemName
                    "ItemNameWithoutExt" = $sItemNameWithoutExt
                    "Extension" = $sExtension
                    "FullPath" = $sFullPath
                }
                return $hResult
            }
        }
        default {
            return (Microsoft.PowerShell.Management\Split-Path @PSBoundParameters)
        }
    }
}
