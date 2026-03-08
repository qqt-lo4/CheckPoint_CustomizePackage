<#
.SYNOPSIS
    Enum of Check Point Endpoint Security features bitmask values

.DESCRIPTION
    Defines bitmask values for Check Point Endpoint Security features.
    Each value represents a different feature that can be installed.

.NOTES
    Author  : Loïc Ade
    Version : 1.0.0
#>
enum EPSFeatures {
    DA = 1
    FDE = 2
    ME = 4
    FW1 = 8
    COMP = 16
    PC = 32
    AM = 64
    FF = 128
    EC = 256
    SC = 512
    URLF = 1024
    DS = 2048
    AB = 4096
    DLP = 8192
    EFR = 65536
    TE = 131072
}

function ConvertTo-EPSInstalledFeatures {
    <#
    .SYNOPSIS
        Converts Check Point EPS feature flags to feature names

    .DESCRIPTION
        Converts a numeric features bitmask to an array or string of Check Point Endpoint Security
        feature names. Each bit represents a different EPS feature (DA, FDE, ME, FW1, etc.).

    .PARAMETER Features
        Numeric bitmask representing installed features.

    .PARAMETER StringOutput
        If specified, returns a string with features separated by FeatureSeparatorChar.

    .PARAMETER FeatureSeparatorChar
        Character to use as separator when StringOutput is specified. Default: "-".

    .PARAMETER RemoveDA
        If specified, removes DA (Data Awareness) from the output.

    .OUTPUTS
        [String] or [Array]. Feature names as string or array depending on StringOutput parameter.

    .EXAMPLE
        ConvertTo-EPSInstalledFeatures -Features 73

    .EXAMPLE
        ConvertTo-EPSInstalledFeatures -Features 73 -StringOutput

    .EXAMPLE
        ConvertTo-EPSInstalledFeatures -Features 8201 -StringOutput -FeatureSeparatorChar "," -RemoveDA

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [int]$Features,
        [switch]$StringOutput,
        [char]$FeatureSeparatorChar = "-",
        [switch]$RemoveDA
    )
    $aResult = @()
    [EPSFeatures].GetEnumNames() | ForEach-Object {
        if ($Features -band [EPSFeatures]::$_) {
            if (-not ($RemoveDA -and ([EPSFeatures]::$_ -eq "DA"))) {
                $aResult += [EPSFeatures]::$_
            }
        }
    }
    if ($StringOutput) {
        return $aResult -join $FeatureSeparatorChar
    } else {
        return $aResult
    }
}
