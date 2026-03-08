function Invoke-GraphQLQuery {
    <#
    .SYNOPSIS
        Sends a GraphQL query to an endpoint.

    .DESCRIPTION
        Executes a GraphQL query against the specified endpoint with optional support
        for variables, custom headers (authentication, etc.), and WebSession persistence.

    .PARAMETER Uri
        The GraphQL endpoint URL.

    .PARAMETER Query
        The GraphQL query string to execute.

    .PARAMETER Variables
        Hashtable of variables to pass to the GraphQL query. Optional.

    .PARAMETER OperationName
        The GraphQL operation name if the query contains multiple operations. Optional.

    .PARAMETER Headers
        Hashtable of additional HTTP headers (e.g., @{ Authorization = "Bearer <token>" }).

    .PARAMETER WebSession
        A Microsoft.PowerShell.Commands.WebRequestSession object for cookie/session persistence.
        Use with New-Object Microsoft.PowerShell.Commands.WebRequestSession or from a previous
        Invoke-RestMethod -SessionVariable call.

    .PARAMETER SessionVariable
        Name of a variable in which to store the WebSession object for subsequent requests.
        This creates a new session and stores it in the specified variable in the caller's scope.

    .PARAMETER Raw
        If specified, returns the full response object (with 'data' and 'errors') instead of just 'data'.

    .PARAMETER IgnoreSSLError
        If specified, disables SSL certificate validation for the request.

    .OUTPUTS
        [PSCustomObject] The GraphQL query result ('data' property) or full response with -Raw.

    .EXAMPLE
        # Simple query
        Invoke-GraphQLQuery2 -Uri "https://api.example.com/graphql" -Query '{ users { id name } }'

    .EXAMPLE
        # Query with variables and Bearer authentication
        $query = '
            query GetUser($id: ID!) {
                user(id: $id) {
                    id
                    name
                    email
                }
            }
        '
        Invoke-GraphQLQuery2 -Uri "https://api.example.com/graphql" `
            -Query $query `
            -Variables @{ id = "123" } `
            -Headers @{ Authorization = "Bearer eyJhb..." }

    .EXAMPLE
        # Query with API Key
        Invoke-GraphQLQuery2 -Uri "https://api.example.com/graphql" `
            -Query '{ products { name price } }' `
            -Headers @{ "X-API-Key" = "my-secret-key" }

    .EXAMPLE
        # Session persistence across multiple requests
        $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
        Invoke-GraphQLQuery2 -Uri "https://api.example.com/graphql" `
            -Query '{ me { id } }' -WebSession $session
        # $session now holds cookies from the response and can be reused

    .EXAMPLE
        # Create a session variable automatically
        Invoke-GraphQLQuery2 -Uri "https://api.example.com/graphql" `
            -Query '{ me { id } }' -SessionVariable 'gqlSession'
        # Use $gqlSession in subsequent calls
        Invoke-GraphQLQuery2 -Uri "https://api.example.com/graphql" `
            -Query '{ orders { id } }' -WebSession $gqlSession

    .EXAMPLE
        # Ignore SSL errors (self-signed certificates)
        Invoke-GraphQLQuery2 -Uri "https://internal-server/graphql" `
            -Query '{ status }' -IgnoreSSLError

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Uri,

        [Parameter(Mandatory)]
        [string]$Query,

        [hashtable]$Variables,

        [string]$OperationName,

        [hashtable]$Headers = @{},

        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,

        [string]$SessionVariable,

        [switch]$Raw,

        [switch]$IgnoreSSLError
    )

    # Disable SSL validation if requested
    if ($IgnoreSSLError.IsPresent) {
        Invoke-IgnoreSSL
    }

    $body = @{ query = $Query }
    if ($Variables)     { $body.variables     = $Variables }
    if ($OperationName) { $body.operationName = $OperationName }

    $jsonBody = $body | ConvertTo-Json -Depth 20 -Compress

    $splat = @{
        Uri             = $Uri
        Method          = 'POST'
        ContentType     = 'application/json'
        Body            = $jsonBody
        UseBasicParsing = $true
    }
    if ($Headers.Count -gt 0) { $splat.Headers = $Headers }
    if ($WebSession)          { $splat.WebSession = $WebSession }
    if ($SessionVariable)     { $splat.SessionVariable = $SessionVariable }

    try {
        $response = Invoke-RestMethod @splat -ErrorAction Stop
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorBody  = $_.ErrorDetails.Message
        Write-Error "GraphQL request failed (HTTP $statusCode): $errorBody"
        return
    }

    # If SessionVariable was used, propagate it to the caller's scope
    if ($SessionVariable) {
        Set-Variable -Name $SessionVariable -Value (Get-Variable -Name $SessionVariable -ValueOnly) -Scope 2
    }

    # Handle GraphQL errors (HTTP 200 but errors in the response body)
    if ($response.errors) {
        foreach ($err in $response.errors) {
            $location = if ($err.locations) {
                ($err.locations | ForEach-Object { "line $($_.line), col $($_.column)" }) -join '; '
            } else { 'N/A' }
            $path = if ($err.path) { $err.path -join '.' } else { 'N/A' }
            Write-Warning "GraphQL Error: $($err.message) [path: $path] [location: $location]"
        }
        # If there are only errors with no data, return the errors
        if (-not $response.data) {
            return $response.errors
        }
    }

    if ($Raw) { return $response }
    return $response.data
}
