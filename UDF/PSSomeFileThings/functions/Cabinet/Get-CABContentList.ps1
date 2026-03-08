function Get-CABContentList {
    <#
    .SYNOPSIS
        Lists files in a CAB archive

    .DESCRIPTION
        Retrieves the list of files contained in a Windows CAB (Cabinet) archive
        using the expand.exe utility.

    .PARAMETER CABFile
        Path to the CAB file.

    .OUTPUTS
        [String[]]. Array of file names contained in the CAB archive.

    .EXAMPLE
        Get-CABContentList -CABFile "C:\archive.cab"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$CABFile
    )
    $sCommandResult = (&expand -D $CABFile)
    $sCommandResult = $sCommandResult | Select-String -Pattern ("^" + $CABFile.Replace("\", "\\") +": (.+)$") | ForEach-Object { $_.Matches.Groups[1].Value }
    return $sCommandResult
}