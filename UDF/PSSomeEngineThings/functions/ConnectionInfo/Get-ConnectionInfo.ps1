function Get-ConnectionInfo {
    <#
    .SYNOPSIS
        Retrieves or prompts for connection information for an application

    .DESCRIPTION
        Gets connection information (server, port, credentials) for a named application.
        If not already stored in global state, prompts the user for the information using
        Read-CLIDialogConnectionInfo. Caches the information in $Global:ConnectionInfo.

    .PARAMETER Name
        Name of the application to retrieve connection information for.

    .OUTPUTS
        [Hashtable]. Connection information including Server, Port, UserName, and Credential.

    .EXAMPLE
        Get-ConnectionInfo -Name "DatabaseServer"

    .EXAMPLE
        $connInfo = Get-ConnectionInfo -Name "APIServer"
        $connInfo.Server
        $connInfo.Port

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory)]
        [string]$Name
    )
    Begin {
        function Convert-ConnectionInfoToAppInfo {
            Param(
                [Parameter(Mandatory, Position = 0)]
                [object]$ConnectionInfo
            )
            $hResult = @{}
            if ($ConnectionInfo.Username) { $hResult.Username = $ConnectionInfo.UserName }
            if ($ConnectionInfo.Server) { $hResult.Server = $ConnectionInfo.Server }
            if ($ConnectionInfo.Port) { $hResult.Port = $ConnectionInfo.Port }
            return $hResult
        }
    }
    Process {
        if ($null -eq $Global:ConnectionInfo.$Name) {
            $fRequiredConnectionInfo = Get-Function -Name "Get-$Name`_RequiredConnectionInfo"
            $hReadConnectInfoArgs = if ($fRequiredConnectionInfo) {
                . $fRequiredConnectionInfo
            } else {
                if ($null -eq $Global:Config.RequiredConnectionInfo.$Name) {
                    throw [System.ArgumentException] "$Name is an unknown app for this script"
                } else {
                    @{
                        Server = $Global:Config.RequiredConnectionInfo.$Name.Server
                        Port = $Global:Config.RequiredConnectionInfo.$Name.Port
                        Credential = $Global:Config.RequiredConnectionInfo.$Name.Credential
                    }      
                }    
            }
            if ($Global:Config.Apps.$Name.Server) {
                $hReadConnectInfoArgs.DefaultServer = $Global:Config.Apps.$Name.Server
            }
            if ($Global:Config.Apps.$Name.Port) {
                $hReadConnectInfoArgs.DefaultPort = $Global:Config.Apps.$Name.Port
            }
            if ($Global:Config.Apps.$Name.Username) {
                $hReadConnectInfoArgs.DefaultUsername = $Global:Config.Apps.$Name.Username
            }
            $hReadConnectInfoResults = Read-CLIDialogConnectionInfo @hReadConnectInfoArgs -AsHashtable -HeaderAppName $Name
            if ($hReadConnectInfoResults -ne $null) {
                if ($null -eq $Global:ConnectionInfo) {
                    $Global:ConnectionInfo = @{}
                }
                $Global:ConnectionInfo.$Name = $hReadConnectInfoResults
                if ($null -eq $Global:Config.Apps) {
                    $Global:Config.Apps = @{}
                }
                $Global:Config.Apps.$Name = Convert-ConnectionInfoToAppInfo $Global:ConnectionInfo.$Name    
                return $Global:ConnectionInfo.$Name
            } else {
                return $null
            }
        } else {
            return $Global:ConnectionInfo.$Name
        }    
    }
    End {

    }
}
