function New-CorrelationVector {
    <#
    .SYNOPSIS
        Creates a new Correlation Vector string value

    .DESCRIPTION
        Generates a new Correlation Vector (MS-CV) string by creating
        a CorrelationVector object and returning its string representation.
        This is a convenience wrapper around New-CorrelationVectorObject.

    .OUTPUTS
        System.String. The correlation vector string (e.g., "ABCDefgh12345678.1")

    .EXAMPLE
        $cv = New-CorrelationVector
        # Returns a string like "ABCDefgh12345678.1"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    $cv = New-CorrelationVectorObject
    return $cv.GetValue()
}
