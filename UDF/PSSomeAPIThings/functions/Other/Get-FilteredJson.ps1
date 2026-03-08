function Get-FilteredJson {
    Param(
        [Parameter(Mandatory)]
        [string]$JsonPath,
        [Parameter(Mandatory)]
        [string]$XPath
    )
    $oXML = (Invoke-WebRequest -UseBasicParsing -Uri $JsonPath).Content | ConvertFrom-Json | ConvertTo-Xml -NoTypeInformation -Depth 100
    $aSelectedNodes = $oXML.SelectNodes($XPath)
    
    return $aSelectedNodes | ForEach-Object {
        if ($_ -is [System.Xml.XmlText]) {
            $_.InnerText
        } else {
            $_
        }
    }
}