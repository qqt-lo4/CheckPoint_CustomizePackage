function Get-FE3FileUrls {
    <#
    .SYNOPSIS
        Retrieves download URLs for packages from the FE3 delivery endpoint

    .DESCRIPTION
        Sends GetExtendedUpdateInfo2 SOAP requests to the FE3 secured endpoint
        to obtain file download URLs for each UpdateID/RevisionID pair.
        Filters out BlockMap URLs (length 99).

    .PARAMETER UpdateIDs
        ArrayList of update GUIDs to query

    .PARAMETER RevisionIDs
        ArrayList of revision numbers corresponding to each UpdateID

    .PARAMETER MSAToken
        Optional MSA Device Token. If not provided, uses the module-cached token.

    .OUTPUTS
        ArrayList of download URL strings

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    param(
        [System.Collections.ArrayList]$UpdateIDs,
        [System.Collections.ArrayList]$RevisionIDs,
        [string]$MSAToken
    )
    
    $uris = New-Object System.Collections.ArrayList
    
    # Initialize MSAToken if not provided
    if (-not $MSAToken) {
        if (-not $script:MSAToken) {
            Write-Verbose "Initializing MSA Device Token from registry..."
            $script:MSAToken = Get-DeviceMSAToken
        }
        $MSAToken = $script:MSAToken
    }
    
    $fe3FileUrlTemplate = @'
<s:Envelope xmlns:a="http://www.w3.org/2005/08/addressing" xmlns:s="http://www.w3.org/2003/05/soap-envelope">
    <s:Header>
        <a:Action s:mustUnderstand="1">http://www.microsoft.com/SoftwareDistribution/Server/ClientWebService/GetExtendedUpdateInfo2</a:Action>
        <a:MessageID>urn:uuid:2cc99c2e-3b3e-4fb1-9e31-0cd30e6f43a0</a:MessageID>
        <a:To s:mustUnderstand="1">https://fe3.delivery.mp.microsoft.com/ClientWebService/client.asmx/secured</a:To>
        <o:Security s:mustUnderstand="1" xmlns:o="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
            <Timestamp xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
                <Created>2017-08-01T00:29:01.868Z</Created>
                <Expires>2017-08-01T00:34:01.868Z</Expires>
            </Timestamp>
            <wuws:WindowsUpdateTicketsToken wsu:id="ClientMSA" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" xmlns:wuws="http://schemas.microsoft.com/msus/2014/10/WindowsUpdateAuthorization">
                <TicketType Name="MSA" Version="1.0" Policy="MBI_SSL">{2}</TicketType>
            </wuws:WindowsUpdateTicketsToken>
        </o:Security>
    </s:Header>
    <s:Body>
        <GetExtendedUpdateInfo2 xmlns="http://www.microsoft.com/SoftwareDistribution/Server/ClientWebService">
            <updateIDs>
                <UpdateIdentity>
                    <UpdateID>{0}</UpdateID>
                    <RevisionNumber>{1}</RevisionNumber>
                </UpdateIdentity>
            </updateIDs>
            <infoTypes>
                <XmlUpdateFragmentType>FileUrl</XmlUpdateFragmentType>
                <XmlUpdateFragmentType>FileDecryption</XmlUpdateFragmentType>
            </infoTypes>
            <deviceAttributes>BranchReadinessLevel=CB;CurrentBranch=rs_prerelease;OEMModel=Virtual Machine;FlightRing=WIS;AttrDataVer=21;SystemManufacturer=Microsoft Corporation;InstallLanguage=en-US;OSUILocale=en-US;InstallationType=Client;FlightingBranchName=external;FirmwareVersion=Hyper-V UEFI Release v2.5;SystemProductName=Virtual Machine;OSSkuId=48;FlightContent=Branch;App=WU;OEMName_Uncleaned=Microsoft Corporation;AppVer=10.0.16184.1001;OSArchitecture=AMD64;SystemSKU=None;UpdateManagementGroup=2;IsFlightingEnabled=1;IsDeviceRetailDemo=0;TelemetryLevel=3;OSVersion=10.0.16184.1001;DeviceFamily=Windows.Desktop;</deviceAttributes>
        </GetExtendedUpdateInfo2>
    </s:Body>
</s:Envelope>
'@
    
    for ($i = 0; $i -lt $UpdateIDs.Count; $i++) {
        $updateID = $UpdateIDs[$i]
        $revisionID = $RevisionIDs[$i]
        
        $soapBody = $fe3FileUrlTemplate -f $updateID, $revisionID, $MSAToken
        
        try {
            $response = Invoke-MSHttpRequest -Uri "https://fe3.delivery.mp.microsoft.com/ClientWebService/client.asmx/secured" `
                                             -Method Post `
                                             -Body $soapBody `
                                             -ContentType "application/soap+xml; charset=utf-8"
            
            Write-Verbose "Processing UpdateID $i/$($UpdateIDs.Count): $updateID"
            
            [xml]$doc = New-Object System.Xml.XmlDocument
            $doc.LoadXml($response.Content)
            
            # Save for debugging
            $debugPath = Join-Path $env:TEMP "FE3_FileUrl_Response_$i.xml"
            $response.Content | Out-File -FilePath $debugPath -Encoding UTF8
            
            $urlNodes = $doc.GetElementsByTagName("FileLocation")
            Write-Verbose "  Found $($urlNodes.Count) FileLocation nodes"
            
            foreach ($fileNode in $urlNodes) {
                foreach ($child in $fileNode.ChildNodes) {
                    if ($child.Name -eq "Url") {
                        $urlValue = $child.InnerText
                        Write-Verbose "  URL found: $($urlValue.Substring(0, [Math]::Min(100, $urlValue.Length)))..."
                        Write-Verbose "  URL length: $($urlValue.Length)"
                        
                        # Filtre: longueur != 99 (exclut les BlockMap)
                        if ($urlValue.Length -ne 99) {
                            [void]$uris.Add($urlValue)
                            Write-Verbose "  → URL added to list"
                        }
                        else {
                            Write-Verbose "  → URL skipped (BlockMap, length=99)"
                        }
                    }
                }
            }
        }
        catch {
            Write-Verbose "Get-FE3FileUrls error for UpdateID $updateID : $_"
        }
    }
    
    Write-Verbose "Total URLs collected: $($uris.Count)"
    
    return $uris
}
