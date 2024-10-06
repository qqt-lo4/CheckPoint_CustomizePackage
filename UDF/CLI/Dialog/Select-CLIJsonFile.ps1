function Select-CLIJsonFile {
    <#
    .DESCRIPTION
    Function to select json objects from files in $jsonFolder
    Will return the json content of the selected file
    .VERSION 1.0
    First release
    .VERSION 1.1
    Added $Filter to filter files in $jsonFolder
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$JsonFolder,
        [string[]]$JsonColumn = "Description",
        [string[]]$Sort = "Description",
        [string]$SelectHeaderMessage = "Please select an item:",
        [System.ConsoleColor]$HeaderColor = (Get-Host).UI.RawUI.ForegroundColor,
        [AllowNull()]
        [string]$FooterMessage = "Please type item number",
        [System.ConsoleColor]$FooterColor = (Get-Host).UI.RawUI.ForegroundColor,
        [string]$ErrorMessage,
        [string]$FilterFunction,
        $FilteredValue,
        [switch]$AlwaysAskUser,
        [string[]]$Filter = @("*.json", "*.jsonc"),
        [System.ConsoleColor]$SeparatorColor = (Get-Host).UI.RawUI.ForegroundColor,
        [switch]$HeaderTextInSeparator,
        [switch]$DisplaySelectedItem,
        [string]$SelectedItemText = "Selected item:"
    )
    $arrayJson = Get-JSONFileList -JsonFolder $JsonFolder -JsonColumn $JsonColumn -Filter $Filter
    if ($filterFunction) {
        $arrayJson = $(&$filterFunction $arrayJson $filteredValue)
    }
    if ($arrayJson.Count -eq 0) {
        throw [System.IO.DirectoryNotFoundException] $errorMessage
    }
    $selectedJson = if ($AlwaysAskUser.IsPresent -or ($arrayJson.Count -gt 1)) {
        Select-CLIObjectInArray -Objects $arrayJson -SelectedColumns $JsonColumn -Sort $Sort -SelectHeaderMessage $SelectHeaderMessage -FooterMessage $FooterMessage -HeaderColor $HeaderColor -FooterColor $FooterColor -HeaderTextInSeparator:$HeaderTextInSeparator -SeparatorColor $SeparatorColor
    } else { #$arrayJson.Count -eq 1
        Select-CLIObjectInArray -Objects $arrayJson -SelectedColumns $JsonColumn -Sort $Sort -SelectHeaderMessage $SelectHeaderMessage -FooterMessage $FooterMessage -HeaderColor $HeaderColor -FooterColor $FooterColor -HeaderTextInSeparator:$HeaderTextInSeparator -SeparatorColor $SeparatorColor -AutoSelectWhenOneItem
    }
    if ($DisplaySelectedItem) {
        Write-Host (Set-StringFormat $SelectedItemText -Underline)
        Format-TableCustom -InputObject $selectedJson.Value -Property $JsonColumn -HeaderColor Green
        Write-Host ""
    }
    return $selectedJson
}