function Invoke-SystemTokenExtraction {
    <#
    .SYNOPSIS
    Internal function to extract MSA Device Token from SYSTEM registry
    
    .DESCRIPTION
    This function is designed to run as SYSTEM (via scheduled task) and extracts
    the MSA Device Token from the SYSTEM registry by decrypting it using DPAPI
    with LocalMachine scope.
    
    .PARAMETER OutputFile
    Path where the extracted token should be written
    
    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        This function must run as SYSTEM to decrypt the DeviceTicket.
        It's used by Get-DeviceMSAToken for both admin and UAC elevation scenarios.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$OutputFile
    )
    
    Add-Type -AssemblyName System.Security

    if (-not (Test-Path 'HKU:')) {
        New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS -ErrorAction SilentlyContinue | Out-Null
    }

    $tokenPath = 'HKU:\S-1-5-18\SOFTWARE\Microsoft\IdentityCRL\Immersive\production\Token'

    if (Test-Path $tokenPath) {
        $subkeys = Get-ChildItem -Path $tokenPath -ErrorAction SilentlyContinue
        
        foreach ($subkey in $subkeys) {
            try {
                $props = Get-ItemProperty -Path $subkey.PSPath -ErrorAction Stop
                
                if ($props.DeviceTicket) {
                    $bytes = $props.DeviceTicket
                    
                    try {
                        $decrypted = [Text.Encoding]::Unicode.GetString([Security.Cryptography.ProtectedData]::Unprotect($bytes[4..$bytes.length], $null, [Security.Cryptography.DataProtectionScope]::LocalMachine))
                        
                        if ($decrypted -match 'ztd\.dds\.microsoft\.com') {
                            $base64Token = [Convert]::ToBase64String($bytes[4..$bytes.length])
                            "<Device>$base64Token</Device>" | Out-File -FilePath $OutputFile -Encoding UTF8 -NoNewline
                            break
                        }
                    } catch {
                        continue
                    }
                }
            } catch {
                continue
            }
        }
    }
}
