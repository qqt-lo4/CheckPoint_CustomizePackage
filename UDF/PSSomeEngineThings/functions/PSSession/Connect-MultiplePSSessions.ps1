function Connect-MultiplePSSessions {
    <#
    .SYNOPSIS
        Creates PowerShell sessions to multiple computers

    .DESCRIPTION
        Establishes PowerShell remote sessions to multiple computers with credential prompting
        and optional connectivity testing. Automatically prompts for credentials and retries
        on failure.

    .PARAMETER ComputerName
        Array of computer names to connect to.

    .PARAMETER TestScriptBlock
        Optional script block to test each session after creation.

    .OUTPUTS
        [Hashtable]. Hashtable with computer names as keys and PSSession objects as values.

    .EXAMPLE
        Connect-MultiplePSSessions -ComputerName "Server01","Server02"

    .EXAMPLE
        Connect-MultiplePSSessions -ComputerName "Server01" -TestScriptBlock { Test-Path C:\ }

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [parameter(Mandatory, Position = 0)]
        [string[]]$ComputerName,
        [scriptblock]$TestScriptBlock
    )
    $aCredential = @()
    $hSessions = @{}
    $hNewTestedPSSessionArgs = if ($TestScriptBlock) {
        @{TestScriptBlock = $TestScriptBlock}
    } else {
        @{}
    }
    foreach ($oComputerName in $ComputerName) {
        if ($aCredential.Count -eq 0) {
            $oPSCredDialogResult = Read-CLIDialogConnectionInfo -Credential -ConnectionInfo $Global:PSCred -AskInForm -HeaderAppName $oComputerName
            if ($oPSCredDialogResult.PSTypeNames[0] -eq "DialogResult.Value") {
                $aCredential += $oPSCredDialogResult.Value.GetCredential()    
            }
        }
        if ($aCredential.Count -gt 0) {
            Write-Progress "Opening a session to $oComputerName"
            $oSession = New-TestedPSSession -ComputerName $oComputerName -Credential $aCredential @hNewTestedPSSessionArgs
            if ($oSession.Success) {
                $hSessions.$oComputerName = $oSession.Session
            } else {
                $oPSCredDialogResult = Read-CLIDialogConnectionInfo -Credential -ConnectionInfo $Global:PSCred -AskInForm -HeaderAppName $oComputerName
                if ($oPSCredDialogResult.PSTypeNames[0] -eq "DialogResult.Value") {
                    $aCredential += $oPSCredDialogResult.Value.GetCredential()    
                }
                $oSession = New-TestedPSSession -ComputerName $oComputerName -Credential $aCredential @hNewTestedPSSessionArgs
                if ($oSession.Success) {
                    $hSessions.$oComputerName = $oSession.Session
                }
            }
        }
    }
    return $hSessions
}