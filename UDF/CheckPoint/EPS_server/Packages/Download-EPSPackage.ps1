function Download-EPSPackage {
    Param(
        [object]$EPSAPI, 
        [string]$softwarePackageId,
        [int]$blades,
        [string]$id,
        [switch]$waitEnd,
        [string]$OutputFolder = ($env:TEMP)
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
        $sOperationName = "downloadDynamicPackageJob"
        $sQuery = "mutation downloadDynamicPackageJob(`$dynamicPackage: DynamicPackageInput!) {
            downloadDynamicPackageJob(dynamicPackage: `$dynamicPackage)
        }
"
        $hVariables = @{
            "dynamicPackage" = @{
                "softwarePackageId" = $softwarePackageId
                "blades" = $blades
                "id" = $id
            }
        }
    }
    Process {
        $oAPIResult = $oEPSAPI.CallAPI($sOperationName, $sQuery, $hVariables)
        $sJobId = $oAPIResult.data.downloadDynamicPackageJob
        if ($waitEnd) {
            $oJobStatus = Wait-EPSJobEnd -EPSAPI $oEPSAPI -Id $sJobId
            if (Test-Path -Path $OutputFolder -PathType Container) {
                $sURL = "https://" + $oEPSAPI.Server + ":" + $oEPSAPI.Port + $oJobStatus.data.downloadPath
                $sFileName = $oJobStatus.data.downloadPath.Split("/")[-1]
                $sFileName = $sFileName -replace ":", ""
                $sOutFile = $OutputFolder + "\" + $sFileName
                $dp = $ProgressPreference
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest $sURL -OutFile $sOutFile 
                $ProgressPreference = $dp
                Write-Progress -Activity "Download finished" -PercentComplete 100 -Completed
                return Get-Item $sOutFile
            }
        } else {
            return $sJobId
        }
    }
}