function New-TestedPSSession {
    <#
    .SYNOPSIS
        Creates a tested PowerShell remote session

    .DESCRIPTION
        Creates a PowerShell remote session with DNS resolution check and optional script block
        testing. Tries multiple credentials if provided and returns success/failure details.

    .PARAMETER ComputerName
        Name of the computer to connect to.

    .PARAMETER Credential
        Array of credentials to try for authentication.

    .PARAMETER TestScriptBlock
        Optional script block to test the session after creation.

    .OUTPUTS
        [Hashtable]. Result with Success flag, Session object (if successful), and failure reasons.

    .EXAMPLE
        New-TestedPSSession -ComputerName "Server01" -Credential $cred

    .EXAMPLE
        New-TestedPSSession -ComputerName "Server01" -Credential $cred1,$cred2 -TestScriptBlock { Get-Service }

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$ComputerName,
        [Parameter(Position = 1)]
        [pscredential[]]$Credential,
        [scriptblock]$TestScriptBlock
    )
    $oDNSResolution = Resolve-DnsName -Name $ComputerName
    if ($oDNSResolution) {
        $aFailureResults = @()
        foreach ($oCred in $Credential) {
            try {
                $oSession = New-PSSession -ComputerName $ComputerName -Credential $oCred
                if ($TestScriptBlock) {
                    $bScriptBlockResult = Invoke-Command -Session $oSession -ScriptBlock $TestScriptBlock
                    if ($bScriptBlockResult) {
                        return @{
                            Success = $true
                            ComputerName = $ComputerName
                            Session = $oSession
                            Credential = $oCred
                        }
                    } else {
                        $aFailureResults += "Script failed for $($Credential.UserName) on $ComputerName"
                        $oSession = $null
                    }
                } else {
                    return @{
                        Success = $true
                        ComputerName = $ComputerName
                        Session = $oSession
                        Credential = $oCred
                    }
                }
            } catch {
                $aFailureResults += "`$Credential with $($Credential.UserName) failed for $ComputerName"
                $oSession = $null
            }
        }    
    } else {
        return @{
            Success = $false
            ComputerName = $ComputerName
            Reason = "No DNS resolution for $ComputerName"
        }
    }

    return @{
        Success = $false
        ComputerName = $ComputerName
        Reason = $aFailureResults
    }
}