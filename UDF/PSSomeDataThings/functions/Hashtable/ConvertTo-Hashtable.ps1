# function ConvertTo-Hashtable {
#     [CmdletBinding()]
#     param (
#         [Parameter(ValueFromPipeline)]
#         $InputObject
#     )

#     process {
#         ## Return null if the input is null. This can happen when calling the function
#         ## recursively and a property is null
#         if ($null -eq $InputObject) {
#             return $null
#         }

#         ## Check if the input is an array or collection. If so, we also need to convert
#         ## those types into hash tables as well. This function will convert all child
#         ## objects into hash tables (if applicable)
#         if ($InputObject -is [hashtable]) {
#             $InputObject
#         } elseif (($InputObject -is [System.Collections.IEnumerable]) -and ($InputObject -isnot [string])) {
#             $collection = @(
#                 foreach ($object in $InputObject) {
#                     ConvertTo-Hashtable -InputObject $object
#                 }
#             )
#             ## Return the array but don't enumerate it because the object may be pretty complex
#             Write-Output -NoEnumerate $collection
#         } elseif ($null -ne ($InputObject.GetType().ImplementedInterfaces.FullName | Where-Object { $_ -like "Microsoft.Graph.PowerShell.Runtime.IAssociativeArray*" })) {
#             ## Convert it to its own hash table and return it
#             $hash = [ordered]@{}
#             $aProperties = $InputObject.PSObject.Properties | Where-Object { $_.Name -ne "AdditionalProperties" }
#             foreach ($property in $aProperties) {
#                 $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
#             }
#             $hash
#         } elseif ($InputObject -is [psobject]) { ## If the object has properties that need enumeration
#             ## Convert it to its own hash table and return it
#             $hash = [ordered]@{}
#             foreach ($property in $InputObject.PSObject.Properties) {
#                 $hash.Add($property.Name, (ConvertTo-Hashtable -InputObject $property.Value))
#             }
#             $hash
#         } else {
#             ## If the object isn't an array, collection, or other object, it's already a hash table
#             ## So just return it.
#             $InputObject
#         }
#     }
# }

function ConvertTo-Hashtable {
    <#
    .SYNOPSIS
        Recursively converts objects to ordered hashtables

    .DESCRIPTION
        Converts PSCustomObjects, PSObjects, arrays, and Microsoft Graph types
        to ordered hashtables recursively. Strings, numbers, and other primitives
        are returned as-is. Existing hashtables are passed through unchanged.

    .PARAMETER InputObject
        The object to convert (supports pipeline)

    .OUTPUTS
        OrderedDictionary, Array, or the original value type.

    .EXAMPLE
        $json | ConvertFrom-Json | ConvertTo-Hashtable

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )
    process {
        ## Return null if the input is null
        if ($null -eq $InputObject) {
            return $null
        }
        
        ## If already a hashtable, return it
        if ($InputObject -is [hashtable]) {
            return $InputObject
        }
        
        ## Check if the input is an array or collection
        if (($InputObject -is [System.Collections.IEnumerable]) -and ($InputObject -isnot [string])) {
            $collection = @(
                foreach ($object in $InputObject) {
                    ConvertTo-Hashtable -InputObject $object
                }
            )
            ## Return the array but don't enumerate it
            Write-Output -NoEnumerate $collection
        }
        ## Check for Microsoft Graph specific types
        elseif ($null -ne ($InputObject.GetType().ImplementedInterfaces.FullName | Where-Object { $_ -like "Microsoft.Graph.PowerShell.Runtime.IAssociativeArray*" })) {
            $hash = [ordered]@{}
            $aProperties = $InputObject.PSObject.Properties | Where-Object { $_.Name -ne "AdditionalProperties" }
            foreach ($property in $aProperties) {
                $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
            }
            return $hash
        }
        ## If the object has properties (PSObject/PSCustomObject)
        elseif ($InputObject -is [psobject]) {
            $hash = [ordered]@{}
            foreach ($property in $InputObject.PSObject.Properties) {
                $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
            }
            return $hash
        }
        ## Otherwise return as-is
        else {
            return $InputObject
        }
    }
}