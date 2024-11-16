function Invoke-GraphQLQuery {
    <#
    .SYNOPSIS
        Sends a query or mutation to a GraphQL endpoint.
    .DESCRIPTION
        Sends a query (read operation) or mutation (create, update, delete operation) to a GraphQL endpoint.
    .PARAMETER Query
        The GraphQL query or mutation to send to the endpoint.
    .PARAMETER OperationName
        A meaningful and explicit name for your GraphQL operation.
    .PARAMETER Variables
        Variables expressed as a hash table or JSON string for your GraphQL operation.
    .PARAMETER Headers
        Specifies the headers of the web request expressed as a hash table.
    .PARAMETER Uri
        Specifies the Uniform Resource Identifier (URI) of the GraphQL endpoint to which the GraphQL query or mutation is sent.
    .PARAMETER WebSession
        Specifies a web request session. Enter the variable name, including the dollar sign (`$`).
    .PARAMETER Raw
        Tells the function to return JSON as opposed to objects.
    .PARAMETER ContentType
        Specifies the ContentType for the Webrequest (Default: "application/json"). Can be used to resolve encoding problems.
    .PARAMETER Detailed
        Returns parsed and raw responses from the GraphQL endpoint as well as HTTP status code, description, and response headers.
    .NOTES
        Query and mutation default return type is a collection of objects. To return results as JSON, use the -Raw parameter. To return both parsed and raw results, use the -Detailed parameter.
    .EXAMPLE
        $uri = "https://mytargetserver/v1/graphql"

        $query = '
            query RollDice($dice: Int!, $sides: Int) {
                rollDice(numDice: $dice, numSides: $sides)
            }'

        $variables = '
            {
                "dice": 3,
                "sides": 6
            }'

        Invoke-GraphQLQuery -Query $query -Variables $variables -Uri $uri

        Sends a GraphQL query to the endpoint 'https://mytargetserver/v1/graphql' with variables defined in $variables as JSON.
    .EXAMPLE
        $uri = "https://mytargetserver/v1/graphql"

        $query = '
        query RollDice($dice: Int!, $sides: Int) {
            rollDice(numDice: $dice, numSides: $sides)
        }'

        $variables = @{dice=3; sides=6}

        Invoke-GraphQLQuery -Query $query -Variables $variables -Uri $uri

        Sends a GraphQL query to the endpoint 'https://mytargetserver/v1/graphql' with variables defined in $variables.
    .EXAMPLE
        $uri = "https://mytargetserver/v1/graphql"

        $introspectionQuery = '
            query allSchemaTypes {
                __schema {
                    types {
                        name
                        kind
                        description
                    }
                }
            }
        '

        Invoke-GraphQLQuery -Query $introspectionQuery -Uri $uri -Raw

        Sends a GraphQL introspection query to the endpoint 'https://mytargetserver/v1/graphql' with the results returned as JSON.
    .EXAMPLE
        $uri = "https://mytargetserver/v1/graphql"

        $results = Invoke-GraphQLQuery -Uri $uri

        Sends a GraphQL introspection query using the default value for the Query parameter (as opposed to specifying it) to the endpoint 'https://mytargetserver/v1/graphql' with the results returned as objects and assigning the results to the $results variable.
    .EXAMPLE
        $uri = "https://mytargetserver/v1/graphql"

        $myQuery = '
            query GetUsers {
                users {
                    created_at
                    id
                    last_seen
                    name
                }
            }
        '

        Invoke-GraphQLQuery -Query $myQuery -Uri $uri -Raw

        Sends a GraphQL query to the endpoint 'https://mytargetserver/v1/graphql' with the results returned as JSON.
    .EXAMPLE
        $uri = "https://mytargetserver/v1/graphql"

        $myQuery = '
            query GetUsers {
                users {
                    created_at
                    id
                    last_seen
                    name
            }
        }
        '

        $result = Invoke-GraphQLQuery -Query $myQuery -Uri $uri
        $result.data.users | Format-Table

        Sends a GraphQL query to the endpoint 'https://mytargetserver/v1/graphql' with the results returned as objects and navigates the hierarchy to return a table view of users.
    .EXAMPLE
        $jwt = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE2MjAzOTMwMjgsIm5iZiI6MTYyMDM5MzAyNywiZXhwIjoxNjIwMzkzMzI4LCJzdWIiOiJtZUBjb21wYW55LmNvbSIsImp0aSI6ImMwZTk0ZTY0ODc4ZjRlZDFhZWM3YWYwYzViOWM2ZWI5Iiwicm9sZSI6InVzZXIifQ.HaTXDunEjmyUsHs7daLe-AxEpmq58QqqFziydm7MBic"

        $headers = @{Authorization="Bearer $jwt"}

        $uri = "https://mytargetserver/v1/graphql"

        $myQuery = '
            query GetUsers {
                users {
                    created_at
                    id
                    last_seen
                    name
            }
        }
        '

        $result = Invoke-GraphQLQuery -Query $myQuery -Headers $headers -Uri $uri
        $result.data.users | Format-Table

        Sends a GraphQL query using JWT for authentication to the endpoint 'https://mytargetserver/v1/graphql' with the results returned as objects and navigates the hierarchy to return a table view of users.
    .EXAMPLE
        $uri = "https://mytargetserver/v1/graphql"

        $myMutation = '
            mutation MyMutation {
                insert_users_one(object: {id: "57", name: "FirstName LastName"}) {
                id
            }
        }
        '

        $requestHeaders = @{ "x-api-key"="aoMGY{+93dx&t!5)VMu4pI8U8T.ULO" }

        $jsonResult = Invoke-GraphQLQuery -Mutation $myMutation -Headers $requestHeaders -Uri $uri -Raw

        Sends a GraphQL mutation to the endpoint 'https://mytargetserver/v1/graphql' with the results returned as JSON.
    .EXAMPLE
        gql -q 'query { users { created_at id last_seen name } }' -u 'https://mytargetserver/v1/graphql' -r
        
        Sends a GraphQL query to an endpoint with the results returned as JSON (as a one-liner using aliases).
    .LINK
        https://github.com/anthonyg-1/PSGraphQL/blob/main/PSGraphQL/Functions/Invoke-GraphQLQuery.ps1
        https://graphql.org/
        Format-Table
        Get-GraphQLVariableList
    #>
    [CmdletBinding()]
    [Alias("gql", "Invoke-GraphQLMutation", "Invoke-GraphQLOperation")]
    [OutputType([System.Management.Automation.PSCustomObject], [System.String], [GraphQLResponseObject])]
    Param(
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $false, Position = 0)]
        [ValidateLength(12, 1073741791)]
        [Alias("Mutation", "Operation", "q", "m", "o")]
        [System.String]$Query = "query introspection { __schema { types { name kind description } } }",

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $false, Position = 1)]
        [ValidateLength(1, 4096)]
        [Alias("op")]
        [System.String]$OperationName,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $false, Position = 2)]
        [Alias("v", "Arguments")]
        [Object]$Variables,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $false, Position = 3)]
        [Alias("h")]
        [System.Collections.Hashtable]$Headers,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $false, Position = 4)]
        [Alias("u")]
        [System.Uri]$Uri,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $false, Position = 5)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,

        [Parameter(Mandatory = $false, Position = 6)]
        [Alias("AsJson", "json", "r")]
        [Switch]$Raw,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $false, Position = 7)]
        [Alias("ct")]
        [string]$ContentType = "application/json",

        [Parameter(Mandatory = $false, ParameterSetName = "Detailed", Position = 7)]
        [Switch]$Detailed,

        [switch]$IgnoreSSLError
    )
    BEGIN {
        # Return type when using the -Detailed switch:
        class GraphQLResponseObject {
            [Int]$StatusCode = 0
            [String]$StatusDescription = ""
            [String]$Response = ""
            [PSObject]$ParsedResponse = $null
            [String]$RawResponse = ""
            [HashTable]$ResponseHeaders = @{ }
            [TimeSpan]$ExecutionTime
            [Microsoft.PowerShell.Commands.WebRequestSession]$Session
        }

        # Compresses and trims GraphQL operations for processing by this module's functions:
        function Compress-String([string]$InputString) {
            $output = ([String]::Join(" ",($InputString.Split("`r`n")))).Trim()
            return $output
        }

        # Ignore SSL errors
        if ($IgnoreSSLError.IsPresent) {
            if (-not ("TrustAllCertsPolicy" -as [type])) {
                Add-Type @"
                using System.Net;
                using System.Security.Cryptography.X509Certificates;
                public class TrustAllCertsPolicy : ICertificatePolicy {
                    public bool CheckValidationResult(
                        ServicePoint srvPoint, X509Certificate certificate,
                        WebRequest request, int certificateProblem) {
                        return true;
                    }
                }
"@
            }
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        }    
    }
    PROCESS {
        # The object that will ultimately be serialized and sent to the GraphQL endpoint:
        $jsonRequestObject = [ordered]@{ }

        # Trim all spaces and flatten $OperationName parameter value and add to $jsonRequestObject:
        if ($PSBoundParameters.ContainsKey("OperationName")) {
            $cleanedOperationInput = Compress-String -InputString $OperationName
            $jsonRequestObject.Add("operationName", $cleanedOperationInput)
        }

        # Determine if $Variables is JSON or a HashTable and add to $jsonRequestObject:
        if ($PSBoundParameters.ContainsKey("Variables")) {
            $ArgumentException = New-Object -TypeName System.ArgumentException -ArgumentList "Unable to parse incoming GraphQL variables. Please ensure that passed values are either valid JSON or of type System.Collections.HashTable."

            if ($Variables.GetType().Name -eq "Hashtable") {
                $jsonRequestObject.Add("variables", $Variables)
            }
            elseif ($Variables.GetType().Name -eq "String") {
                $variableTable = @{ }

                try {
                    $deserializedVariables = $Variables | ConvertFrom-Json -ErrorAction Stop

                    $deserializedVariables.PSObject.Properties | ForEach-Object {
                        $variableTable.Add($_.Name, $_.Value)
                    }

                    $jsonRequestObject.Add("variables", $variableTable)
                }
                catch {
                    Write-Error -Exception $ArgumentException -Category InvalidArgument -ErrorAction Stop
                }
            }
            else {
                Write-Error -Exception $ArgumentException -Category InvalidArgument -ErrorAction Stop
            }
        }

        # Trim all spaces and flatten $Query parameter value and add to $jsonRequestObject:
        $cleanedQueryInput = Compress-String -InputString $Query
        if (($cleanedQueryInput.ToLower() -notlike "query*") -and ($cleanedQueryInput.ToLower() -notlike "mutation*") ) {
            $ArgumentException = New-Object -TypeName ArgumentException -ArgumentList "Not a valid GraphQL query or mutation. Verify syntax and try again."
            Write-Error -Exception $ArgumentException -Category InvalidArgument -ErrorAction Stop
        }

        # Add $Query $jsonRequestObject:
        $jsonRequestObject.Add("query", $cleanedQueryInput)

        # Serialize $jsonRequestObject:
        [string]$jsonRequestBody = ""
        try {
            $jsonRequestBody = $jsonRequestObject | ConvertTo-Json -Depth 100 -Compress -ErrorAction Stop -WarningAction SilentlyContinue
        } catch {
            Write-Error -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
        }

        [HashTable]$params = @{Uri = $Uri
            Method                 = "Post"
            Body                   = $jsonRequestBody
            ContentType            = $ContentType
            ErrorAction            = "Stop"
            UseBasicParsing        = $true
        }

        if ($PSBoundParameters.ContainsKey("Headers")) {
            $params.Add("Headers", $Headers)
        }

        # Use or establish a web session:
        $currentSession = "currentSession"
        if ($PSBoundParameters.ContainsKey("WebSession")) {
            $params.Add("WebSession", $WebSession)
        } else {
            $params.Add("SessionVariable", $currentSession)
        }

        if ($PSBoundParameters.ContainsKey("Detailed")) {
            # Object to be returned for the Detailed parameter:
            $gqlResponse = [GraphQLResponseObject]::new()

            # Skip HTTP error checking only when the Detailed parameter is used:
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                $params.Add("SkipHttpErrorCheck", $true)
            }

            $response = $null
            try {
                # Capture the start time:
                $startDateTime = Get-Date

                # Execute the GraphQL operation:
                $response = Invoke-WebRequest @params

                # Capture the end time in order to obtain the delta for the ExecutionTime property:
                $endDateTime = Get-Date

                # Calculate execution time:
                $gqlResponse.ExecutionTime = (New-TimeSpan -Start $startDateTime -End $endDateTime)
            } catch {
                Write-Error -Exception $_.Exception -Category InvalidOperation -ErrorAction Stop
            }

            # Populate properties of object to be returned:
            $gqlResponse.StatusCode = $response.StatusCode
            $gqlResponse.StatusDescription = $response.StatusDescription
            $gqlResponse.Response = $response.Content

            # Attempt to deserialize Content from JSON, if not populate ParsedResponse with a null value:
            try {
                $gqlResponse.ParsedResponse = $($response.Content | ConvertFrom-Json -ErrorAction Stop -WarningAction SilentlyContinue)
            } catch {
                $gqlResponse.ParsedResponse = $null
            }

            $gqlResponse.RawResponse = $response.RawContent

            if ($PSBoundParameters.ContainsKey("WebSession")) {
                $gqlResponse.Session = $WebSession
            } else {
                $gqlResponse.Session = $currentSession
            }

            # Populate ResponseHeaders property:
            [HashTable]$responseHeaders = @{ }
            $response.Headers.GetEnumerator() | ForEach-Object {
                $responseHeaders.Add($_.Key, $_.Value)
            }
            $gqlResponse.ResponseHeaders = $responseHeaders

            return $gqlResponse
        } else {
            try {
                $response = Invoke-RestMethod @params
            } catch {
                Write-Error -Exception $_.Exception -Category InvalidOperation -ErrorAction Stop
            }

            if ($PSBoundParameters.ContainsKey("Raw")) {
                try {
                    return $($response | ConvertTo-Json -Depth 100 -ErrorAction Stop -WarningAction SilentlyContinue)
                } catch {
                    Write-Error -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
                }
            } else {
                try {
                    return $response
                } catch {
                    Write-Error -Exception $_.Exception -Category InvalidResult -ErrorAction Stop
                }
            }
        }
    }
}
