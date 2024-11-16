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
    Param(
        [int]$Features,
        [switch]$StringOutput,
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
        return $aResult -join ","
    } else {
        return $aResult
    }
}
