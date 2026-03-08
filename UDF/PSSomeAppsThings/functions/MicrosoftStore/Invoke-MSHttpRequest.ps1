function Invoke-MSHttpRequest {
    <#
    .SYNOPSIS
        Sends HTTP requests with automatic User-Agent and MS-CV headers

    .DESCRIPTION
        Equivalent to MSHttpClient.SendAsync. Automatically adds StoreLib User-Agent
        and Microsoft Correlation Vector (MS-CV) headers to all requests.

    .PARAMETER Uri
        The target URL

    .PARAMETER Method
        HTTP method (Get, Post, etc.)

    .PARAMETER Body
        Optional request body

    .PARAMETER ContentType
        Optional content type header

    .PARAMETER AdditionalHeaders
        Optional hashtable of additional headers to include

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Uri,
        
        [Parameter(Mandatory=$true)]
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method,
        
        [Parameter(Mandatory=$false)]
        [string]$Body,
        
        [Parameter(Mandatory=$false)]
        [string]$ContentType,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$AdditionalHeaders = @{}
    )
    
    # Initialize CorrelationVector if not already done
    if (-not $script:GlobalCV) {
        $script:GlobalCV = New-CorrelationVectorObject
    }
    
    # Base headers (like MSHttpClient)
    $headers = @{
        'User-Agent' = 'StoreLib'
        'MS-CV' = $script:GlobalCV.GetValue()
    }
    
    # Increment the CorrelationVector
    [void]$script:GlobalCV.Increment()
    
    # Add additional headers
    foreach ($key in $AdditionalHeaders.Keys) {
        $headers[$key] = $AdditionalHeaders[$key]
    }
    
    # Prepare Invoke-WebRequest parameters
    $params = @{
        Uri = $Uri
        Method = $Method
        Headers = $headers
        UseBasicParsing = $true
    }
    
    if ($Body) {
        $params['Body'] = $Body
    }
    
    if ($ContentType) {
        $params['ContentType'] = $ContentType
    }
    
    Write-Verbose "Request: $Method $Uri"
    Write-Verbose "MS-CV: $($headers['MS-CV'])"
    
    return Invoke-WebRequest @params
}
