function Search-ObjectByProperty {
    <#
    .SYNOPSIS
        Searches objects by matching a property value

    .DESCRIPTION
        Finds objects in a collection where one of the specified properties
        matches the given value. Supports searching in nested fields.

    .PARAMETER Objects
        The collection of objects to search

    .PARAMETER Property
        One or more property names to check (tried in order)

    .PARAMETER Field
        Optional nested field name (searches $object.Field.Property)

    .PARAMETER PropertyValue
        The value(s) to search for

    .OUTPUTS
        Object[]. Matching objects from the collection.

    .EXAMPLE
        Search-ObjectByProperty -Objects $users -Property "Name","DisplayName" -PropertyValue "John"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [object]$Objects,
        [Parameter(Mandatory, Position = 1)]
        [string[]]$Property,
        [string]$Field,
        [Parameter(Mandatory, Position = 2)]
        [object]$PropertyValue
    )
    Begin {
        function Search-ObjectByProperty_OneObject {
            Param(
                [Parameter(Mandatory, Position = 0)]
                [object]$Objects,
                [Parameter(Mandatory, Position = 1)]
                [string[]]$Property,
                [string]$Field,
                [Parameter(Mandatory, Position = 2)]
                [object]$PropertyValue
            )
            foreach ($p in $Property) {
                $oResult = if ($Field) {
                    $Objects | Where-Object { $_.$Field.$p -eq $PropertyValue }
                } else {
                    $Objects | Where-Object { $_.$p -eq $PropertyValue }
                }
                
                if ($oResult) {
                    return $oResult
                }
            }
            return $null
        }
        $aResult = @()
    }
    Process {
        foreach ($v in $PropertyValue) {
            $hArgs = @{
                Objects = $Objects
                Property = $Property
                PropertyValue = $v
            }
            if ($Field) {
                $hArgs.Field = $Field
            }
            $oObject = Search-ObjectByProperty_OneObject @hArgs
            if ($oObject) {
                $aResult += $oObject
            }
        }
    }
    End {
        return $aResult
    }
}
