function ConvertTo-URL {
    Param(
        [Parameter(Mandatory, Position = 1)]
        [string]$URL,
        [Parameter(Position = 1)]
        [hashtable]$Arguments
    )

    $sArguments = ""

    foreach ($key in $Arguments.Keys) {
        $sValue = [System.Web.HttpUtility]::UrlEncode($Arguments[$key]) 
        if ($sArguments -ne "") {
            $sArguments += "&"
        }
        $sArguments += "$key=$sValue"
    }

    if ($sArguments -ne "") {
        return $URL + "?" + $sArguments
    } else {
        return $URL
    }
}
