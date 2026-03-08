function New-ReconnectTool {
    <#
    .SYNOPSIS
        Generates the Reconnect.exe tool using maketool.bat and config.dat from the Management server.

    .DESCRIPTION
        1. Retrieves the Management server version using Invoke-FwVer
        2. Locates the corresponding maketool.bat on the local workstation
        3. Downloads config.dat from the Management server
        4. Executes maketool.bat to generate Reconnect.exe (requires admin privileges)

    .PARAMETER ManagementInfo
        The Management connection object (returned by Connect-ManagementAPI).

    .PARAMETER OutputPath
        The output directory for Reconnect.exe. Default is system temp folder.

    .PARAMETER UninstallPassword
        Optional client uninstall password. If not provided, you must enter it when running Reconnect.exe.

    .PARAMETER Silent
        When specified, runs maketool.bat in silent mode.

    .PARAMETER Timeout
        Timeout in seconds for script execution. Default is 60.

    .OUTPUTS
        String. The full path to the generated Reconnect.exe.

    .EXAMPLE
        New-ReconnectTool -ManagementInfo $mgmt

    .EXAMPLE
        New-ReconnectTool -ManagementInfo $mgmt -OutputPath "C:\Temp" -UninstallPassword "MyPassword123"

    .EXAMPLE
        New-ReconnectTool -ManagementInfo $mgmt -Silent

    .NOTES
        Author  : Assistant
        Version : 1.0.4
    #>
    [CmdletBinding()]
    Param(
        [AllowNull()]
        [object]$ManagementInfo,

        [string]$OutputPath,

        [string]$UninstallPassword,

        [switch]$Silent,

        [ValidateRange(1, 3600)]
        [int]$Timeout = 60
    )

    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo

        # Default to temp folder if no OutputPath provided
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $OutputPath = $env:TEMP
        }

        # Check if running as admin
        $bIsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    Process {
        # Step 1: Get Management version
        Write-Host "Retrieving Management server version..." -ForegroundColor Cyan
        $oVersion = Invoke-FwVer -ManagementInfo $oMgmtInfo -Firewall $oMgmtInfo.Object.name -Timeout $Timeout
        $sMgmtVersion = $oVersion.version
        Write-Host "Management version: $sMgmtVersion" -ForegroundColor Green

        # Step 2: Find matching maketool.bat
        Write-Host "Searching for maketool.bat..." -ForegroundColor Cyan
        $hMaketoolPaths = Get-MaketoolPath

        if (-not $hMaketoolPaths.ContainsKey($sMgmtVersion)) {
            $sAvailableVersions = ($hMaketoolPaths.Keys | Sort-Object) -join ", "
            throw "No SmartConsole version $sMgmtVersion found. Available versions: $sAvailableVersions"
        }

        $sMaketoolPath = $hMaketoolPaths[$sMgmtVersion]
        $sMaketoolDir = Split-Path $sMaketoolPath -Parent
        Write-Host "Using maketool.bat: $sMaketoolPath" -ForegroundColor Green

        # Step 3: Download config.dat from Management
        Write-Host "Downloading config.dat from Management server..." -ForegroundColor Cyan
        $sConfigDatContent = Get-ManagementFileContent -ManagementInfo $oMgmtInfo -Path '$FWDIR/conf/SMC_Files/uepm/DA/config.dat' -Timeout $Timeout

        # Save config.dat to temp location
        $sTempConfigDat = Join-Path $env:TEMP "config.dat"
        $sConfigDatContent | Set-Content -Path $sTempConfigDat -NoNewline
        Write-Host "config.dat saved to: $sTempConfigDat" -ForegroundColor Green

        # Step 4: Execute maketool.bat
        Write-Host "Generating Reconnect.exe..." -ForegroundColor Cyan

        $aArguments = @()
        if ($Silent) {
            $aArguments += "/silent"
        }
        $aArguments += $sTempConfigDat
        if ($UninstallPassword) {
            $aArguments += $UninstallPassword
        }

        $sArguments = $aArguments -join " "

        $hStartProcessParams = @{
            FilePath         = $sMaketoolPath
            ArgumentList     = $sArguments
            WorkingDirectory = $sMaketoolDir
            Wait             = $true
            PassThru         = $true
        }

        # Add RunAs only if not already admin
        if (-not $bIsAdmin) {
            Write-Host "Not running as admin, UAC prompt will be displayed..." -ForegroundColor Yellow
            $hStartProcessParams.Verb = "RunAs"
        }

        try {
            $oProcess = Start-Process @hStartProcessParams
            
            if ($oProcess.ExitCode -ne 0) {
                throw "maketool.bat failed with exit code: $($oProcess.ExitCode)"
            }
        }
        catch [System.InvalidOperationException] {
            throw "Administrator privileges required. Please accept the UAC prompt."
        }

        # Step 5: Locate generated Reconnect.exe and move/copy to output
        $sReconnectExePath = Join-Path $sMaketoolDir "Reconnect.exe"

        if (-not (Test-Path $sReconnectExePath)) {
            throw "Reconnect.exe was not generated. Check maketool.bat output for errors."
        }

        # Move or copy to output directory
        $sOutputFile = Join-Path $OutputPath "Reconnect.exe"
        if ($OutputPath -ne $sMaketoolDir) {
            if ($bIsAdmin) {
                # Running as admin: move the file
                Move-Item -Path $sReconnectExePath -Destination $sOutputFile -Force
            } else {
                # Not running as admin: copy the file (may not have delete permissions)
                Copy-Item -Path $sReconnectExePath -Destination $sOutputFile -Force
                Write-Host "Note: Reconnect.exe copied (not moved). Original still exists in: $sMaketoolDir" -ForegroundColor Yellow
            }
        }

        # Cleanup temp config.dat
        Remove-Item -Path $sTempConfigDat -Force -ErrorAction SilentlyContinue

        Write-Host "Reconnect.exe generated successfully: $sOutputFile" -ForegroundColor Green

        return $sOutputFile
    }
}
