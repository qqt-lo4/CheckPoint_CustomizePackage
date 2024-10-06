function Invoke-ScriptBlockAs {
    Param(
        [scriptblock]$ScriptBlock,
        [pscredential]$Credential,
        [switch]$DontWait
    )
    if ($Credential) {
        $job = Start-Job -ScriptBlock $ScriptBlock -Credential $Credential 
        if ($DontWait) {
            return $job
        } else {
            $result = $job | Receive-Job -Wait 
            $result | Select-Object -Property * -ExcludeProperty @("RunspaceId", "PSSourceJobInstanceId")    
        }
    } else {
        . $ScriptBlock
    }
}