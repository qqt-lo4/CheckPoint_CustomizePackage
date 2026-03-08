# function Invoke-ScriptBlockAs {
#     Param(
#         [scriptblock]$ScriptBlock,
#         [pscredential]$Credential,
#         [object[]]$ArgumentList,
#         [switch]$DontWait
#     )
#     if ($Credential) {
#         $jobParams = @{
#             ScriptBlock = $ScriptBlock
#             Credential = $Credential
#         }
#         if ($ArgumentList) {
#             $jobParams.ArgumentList = $ArgumentList
#         }
        
#         $job = Start-Job @jobParams
        
#         if ($DontWait) {
#             return $job
#         } else {
#             $result = $job | Receive-Job -Wait -AutoRemoveJob
#             return $result
#         }
#     } else {
#         if ($ArgumentList) {
#             . $ScriptBlock @ArgumentList
#         } else {
#             . $ScriptBlock
#         }
#     }
# }

function Invoke-ScriptBlockAs {
    <#
    .SYNOPSIS
        Executes a script block with optional credentials
    
    .DESCRIPTION
        Uses Invoke-Command with localhost for credential-based execution (requires WinRM)

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [scriptblock]$ScriptBlock,
        [pscredential]$Credential,
        [object[]]$ArgumentList,
        [switch]$DontWait
    )
    
    if ($Credential) {
        # Ensure WinRM is enabled
        $winrmService = Get-Service -Name WinRM -ErrorAction SilentlyContinue
        if (-not $winrmService -or $winrmService.Status -ne 'Running') {
            throw "WinRM service is not running. Please run 'Enable-PSRemoting -Force' as administrator first."
        }
        
        $invokeParams = @{
            ComputerName = "localhost"
            ScriptBlock = $ScriptBlock
            Credential = $Credential
        }
        
        if ($ArgumentList) {
            $invokeParams.ArgumentList = $ArgumentList
        }
        
        $result = Invoke-Command @invokeParams
        return $result
        
    } else {
        if ($ArgumentList) {
            . $ScriptBlock @ArgumentList
        } else {
            . $ScriptBlock
        }
    }
}