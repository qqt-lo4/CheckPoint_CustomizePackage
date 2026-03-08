function Get-ChildItemRec {
    <#
    .SYNOPSIS
        Recursively gets child items with nested structure

    .DESCRIPTION
        Recursively traverses a path and returns items with their children
        and properties as nested objects. Supports remote execution.

    .PARAMETER path
        The root path to enumerate.

    .PARAMETER ComputerName
        Remote computer name for remote execution.

    .PARAMETER Credential
        Credentials for remote execution.

    .PARAMETER Session
        Existing PSSession for remote execution.

    .OUTPUTS
        [Object]. Item with Children and Property members.

    .EXAMPLE
        $tree = Get-ChildItemRec -path "HKLM:\SOFTWARE\MyApp"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$path,
        [string]$ComputerName,
        [pscredential]$Credential,
        [System.Management.Automation.Runspaces.PSSession]$Session
    )
    if ($ComputerName -or $Session) {
        return Invoke-ThisFunctionRemotely -ThisFunctionName $MyInvocation.InvocationName -ThisFunctionParameters $PSBoundParameters
    } else {
        $item = Get-Item $path 
        if ($item) {
            $children = Get-ChildItem $path
            $hChildren = @{}
            foreach ($child in $children) {
                $c = Get-ChildItemRec $child.PSPath
                $hChildren.Add($child.PSChildName, $c)
            }
            $item | Add-Member -NotePropertyName "Children" -NotePropertyValue (New-Object -TypeName psobject -Property $hChildren)
            $item | Add-Member -NotePropertyName "Property" -NotePropertyValue (Get-ItemProperty $item.PSPath) -Force
        }
        return $item
    }
}
