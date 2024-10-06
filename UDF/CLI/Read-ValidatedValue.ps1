function Read-ValidatedValue {
    Param(
        [string]$header,
        [string]$regex,
        [switch]$allowCancel,
        [string]$regexCancel,
        [switch]$AsSecureString,
        [string]$errorMessage = "Invalid value, please enter value with correct format.",
        [string]$DefaultValue
    )
    $result = ""
    while ($true) {
        $sHeader = if (($null -eq $DefaultValue) -or ($DefaultValue -eq "")) { $header } else { "$header [$DefaultValue]" }
        $result = Read-Host -Prompt $sHeader -AsSecureString:($AsSecureString.IsPresent)
        if ((-not $AsSecureString) -and ($result.Trim() -eq "") -and $DefaultValue) {
            $result = $DefaultValue
        }
        $aMatches = $result | Select-String -Pattern $regex -AllMatches
        if ($aMatches) {
            return [PSCustomObject]@{
                AnswerType = "Value"
                Value = $result
                Matches = $aMatches.Matches
            }
        } else {
            if ($allowCancel.IsPresent) {
                $aCancelMatches = $result | Select-String -Pattern $regexCancel -AllMatches
                if ($aCancelMatches) {
                    return [PSCustomObject]@{
                        AnswerType = "Cancel"
                        Value = $result
                        Matches = $aCancelMatches.Matches
                    }
                }
            }
            Write-Host $errorMessage
        }
    }
}
