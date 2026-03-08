function Get-PhysicalMedia {
    <#
    .SYNOPSIS
        Retrieves physical media information via WMI

    .DESCRIPTION
        Queries Win32_PhysicalMedia and adds parsed Type and Index properties
        extracted from the Tag property (e.g., \\.\PHYSICALDRIVE0).

    .PARAMETER ComputerName
        Remote computer name to query.

    .PARAMETER Credential
        Credentials for remote execution.

    .PARAMETER Session
        Existing PSSession for remote execution.

    .OUTPUTS
        [CimInstance[]]. Win32_PhysicalMedia objects with added Type and Index properties.

    .EXAMPLE
        Get-PhysicalMedia

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    Param(
        [string]$ComputerName,
        [pscredential]$Credential,
        [System.Management.Automation.Runspaces.PSSession]$Session
    )
    Begin {
        if ($Session -and $ComputerName) {
            throw "Incompatible arguments : you can't use Session and ComputerName at the same time"
        }
        $oScriptBlock = {
            $results = Get-CimInstance -ClassName "Win32_PhysicalMedia"
            foreach ($item in $results) {
                if ($item.Tag -match "^\\\\\.\\([A-Za-z]+)([0-9]+)$") {
                    $item | Add-Member -NotePropertyName "Type" -NotePropertyValue $Matches.1
                    $item | Add-Member -NotePropertyName "Index" -NotePropertyValue $Matches.2
                }
            }
            return $results
        }
    }
    Process {
        Invoke-Command @PSBoundParameters -ScriptBlock $oScriptBlock
    }
}

