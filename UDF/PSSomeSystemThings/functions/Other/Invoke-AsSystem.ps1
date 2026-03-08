function Invoke-AsSystem {
    <#
    .SYNOPSIS
    Executes a PowerShell script block as SYSTEM using a scheduled task
    
    .DESCRIPTION
    Creates a temporary scheduled task that runs as SYSTEM, executes the provided
    script block, and returns any output. This is useful for operations that require
    SYSTEM privileges like accessing SYSTEM registry or decrypting LocalMachine DPAPI data.
    
    .PARAMETER ScriptBlock
    The PowerShell script block to execute as SYSTEM
    
    .PARAMETER OutputFile
    Optional path to a file where the script should write its output.
    If not specified, a temporary file will be used.
    
    .PARAMETER Timeout
    Maximum time in seconds to wait for the task to complete. Default is 10 seconds.
    
    .PARAMETER RequiredFunctions
    Array of function names to include in the SYSTEM script. These functions will be
    extracted using Get-FunctionCode and made available to the script block.
    
    .EXAMPLE
    $result = Invoke-AsSystem -ScriptBlock {
        $env:USERNAME
    }
    # Returns: "SYSTEM"
    
    .EXAMPLE
    Invoke-AsSystem -ScriptBlock {
        Get-ItemProperty -Path "HKLM:\SOFTWARE\Test"
    } -Timeout 15
    
    .EXAMPLE
    Invoke-AsSystem -ScriptBlock {
        Invoke-SystemTokenExtraction -OutputFile $OutputFile
    } -RequiredFunctions @("Invoke-SystemTokenExtraction") -OutputFile "C:\temp\token.txt"
    
    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
        Requires Administrator privileges to create scheduled tasks.
        The scheduled task is automatically cleaned up after execution.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,
        
        [Parameter()]
        [string]$OutputFile,
        
        [Parameter()]
        [int]$Timeout = 10,
        
        [Parameter()]
        [string[]]$RequiredFunctions = @()
    )
    
    # Check if admin
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        throw "Invoke-AsSystem requires Administrator privileges"
    }
    
    # Create output file if not specified
    $needsCleanup = $false
    if (-not $OutputFile) {
        $OutputFile = [System.IO.Path]::GetTempFileName()
        $needsCleanup = $true
    }
    
    try {
        # Build script with required functions
        $scriptContent = ""
        
        # Add required functions
        foreach ($funcName in $RequiredFunctions) {
            $scriptContent += Get-FunctionCode -FunctionName $funcName
            $scriptContent += "`n`n"
        }
        
        # Add the script block
        # Make $OutputFile available to the script block
        $scriptContent += "`$OutputFile = '$OutputFile'`n"
        $scriptContent += $ScriptBlock.ToString()
        
        # Save script to temp file
        $scriptFile = [System.IO.Path]::GetTempFileName() + ".ps1"
        $scriptContent | Out-File -FilePath $scriptFile -Encoding UTF8
        
        # Create scheduled task
        $taskName = "InvokeAsSystem_$([Guid]::NewGuid().ToString('N').Substring(0,8))"
        $action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptFile`""
        $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        
        Register-ScheduledTask -TaskName $taskName -Action $action -Principal $principal -Settings $settings -Force -ErrorAction Stop | Out-Null
        Start-ScheduledTask -TaskName $taskName -ErrorAction Stop
        
        Write-Verbose "Scheduled task '$taskName' started, waiting for completion..."
        
        # Wait for completion
        $elapsed = 0
        while ($elapsed -lt $Timeout) {
            $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
            if ($task -and $task.State -eq 'Ready') {
                break
            }
            Start-Sleep -Milliseconds 500
            $elapsed += 0.5
        }
        
        # Cleanup task
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
        Remove-Item -Path $scriptFile -Force -ErrorAction SilentlyContinue
        
        # Read output if file exists
        if (Test-Path $OutputFile) {
            $output = Get-Content -Path $OutputFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            
            if ($needsCleanup) {
                Remove-Item -Path $OutputFile -Force -ErrorAction SilentlyContinue
            }
            
            return $output
        }
        
        if ($elapsed -ge $Timeout) {
            Write-Warning "Invoke-AsSystem timed out after $Timeout seconds"
        }
        
        return $null
        
    } catch {
        # Cleanup on error
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
        Remove-Item -Path $scriptFile -Force -ErrorAction SilentlyContinue
        if ($needsCleanup -and (Test-Path $OutputFile)) {
            Remove-Item -Path $OutputFile -Force -ErrorAction SilentlyContinue
        }
        throw
    }
}
