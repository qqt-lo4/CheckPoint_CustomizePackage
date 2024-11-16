function Read-CLIDialogConnectionInfo {
    [CmdLetBinding(DefaultParameterSetName = "Manual")]
    [OutputType([pscredential])]
    param (
        [AllowNull()]
        [object]$ConnectionInfo,
        [switch]$AskInForm,
        [string]$DomainRegex = "(?<domain>[A-Za-z._0-9-]+)",
        [string]$UsernameRegex = "(?<user>[\p{L}\p{Pc}\p{Pd}\p{Nd} ]+)",
        [string]$EnterInfoQuestion = "Please enter informations to connect to%a:",
        [string]$HeaderAppName = "",
        [string]$ReuseConnectionInfoQuestion = "Connection informations are already in the `$ConnectionInfo variable. Do you want to keem them?",
        [System.ConsoleColor]$QuestionForegroundColor = (Get-Host).UI.RawUI.ForegroundColor,
        [System.ConsoleColor]$TextForegroundColor = (Get-Host).UI.RawUI.ForegroundColor,
        [System.ConsoleColor]$TextBackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [System.ConsoleColor]$HeaderForegroundColor = [System.ConsoleColor]::Green,
        [System.ConsoleColor]$HeaderBackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [System.ConsoleColor]$FocusedTextForegroundColor = (Get-Host).UI.RawUI.ForegroundColor,
        [System.ConsoleColor]$FocusedTextBackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [System.ConsoleColor]$FocusedHeaderForegroundColor = [System.ConsoleColor]::Blue,
        [System.ConsoleColor]$FocusedHeaderBackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [System.ConsoleColor]$ButtonBackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [System.ConsoleColor]$ButtonForegroundColor = (Get-Host).UI.RawUI.ForegroundColor,
        [System.ConsoleColor]$FocusedButtonBackgroundColor = (Get-Host).UI.RawUI.ForegroundColor,
        [System.ConsoleColor]$FocusedButtonForegroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [string]$Prefix = "  ",
        [string]$FocusedPrefix = "> ",
        [Parameter(ParameterSetName = "Manual")]
        [string]$DefaultServer,
        [Parameter(ParameterSetName = "Manual")]
        [int]$DefaultPort = -1,
        [Parameter(ParameterSetName = "Manual")]
        [string]$DefaultUsername,
        [Parameter(ParameterSetName = "Manual")]
        [switch]$Server,
        [Parameter(ParameterSetName = "Manual")]
        [switch]$Port,
        [Parameter(ParameterSetName = "Manual")]
        [switch]$Credential,
        [Parameter(ParameterSetName = "Autodetect")]
        [string]$AppName,
        [Parameter(ParameterSetName = "Autodetect")]
        [object]$Config = $Global:Config,
        [switch]$AsHashtable
    )
    Begin {
        if (($null -ne $ConnectionInfo) -and ($ConnectionInfo.PSObject.TypeNames[0] -ne "ConnectionInfo")) {
            throw "Connection info must be null or type ConnectionInfo"
        }
        $oRequiredAppConnectInfo = if ($PSCmdlet.ParameterSetName -eq "Autodetect") {
            $Config.RequiredConnectionInfo.$AppName
        } else {
            @{
                Server = [bool]$Server
                Port = [bool]$Port
                Credential = [bool]$Credential
            }
        }
        $bNoneArguments = ((-not $oRequiredAppConnectInfo.Server) -and (-not $oRequiredAppConnectInfo.Port) -and (-not $oRequiredAppConnectInfo.Credential))
        $bAskServer = $oRequiredAppConnectInfo.Server -or $bNoneArguments
        $bAskPort = $oRequiredAppConnectInfo.Port -or $bNoneArguments
        if ($bAskPort -and (-not $bAskServer)) {
            throw [System.ArgumentException] "Can't ask port without server"
        }
        $bAskCred = $oRequiredAppConnectInfo.Credential -or $bNoneArguments
        $sDefaultServer = if ($PSCmdlet.ParameterSetName -eq "Autodetect") {
            if (($Config.Apps.$AppName) -and ($Config.Apps.$AppName.Server)) {
                $Config.Apps.$AppName.Server
            } else {
                $DefaultServer
            }
        } else {
            if ($ConnectionInfo -and $AskInForm -and $ConnectionInfo.Server) {
                if ($DefaultServer) {
                    $DefaultServer
                } else {
                    $ConnectionInfo.Server
                }
            } else {
                $DefaultServer
            }
        }
        $sDefaultPort = if ($PSCmdlet.ParameterSetName -eq "Autodetect") {
            if ($Config.Apps.$AppName -and $Config.Apps.$AppName.Port) {
                $Config.Apps.$AppName.Port
            } else {
                if ($DefaultPort -eq -1) { "" } else { $DefaultPort }
            }
        } else {
            if ($ConnectionInfo -and $AskInForm -and ($ConnectionInfo.Port -ge 0)) {
                if ($DefaultPort -ge 0) {
                    $DefaultPort
                } else {
                    $ConnectionInfo.Port
                }
            } else {
                if ($DefaultPort -eq -1) { "" } else { $DefaultPort }
            }
        }
        $sDefaultUsername = if ($PSCmdlet.ParameterSetName -eq "Autodetect") {
            if ($Config.Apps.$AppName -and $Config.Apps.$AppName.User) {
                $Config.Apps.$AppName.User
            } else {
                $DefaultUsername
            }
        } else {
            if ($ConnectionInfo -and $AskInForm -and $ConnectionInfo.Username) {
                if ($DefaultUsername) {
                    $DefaultUsername
                } else {
                    $ConnectionInfo.Username
                }
            } else {
                $DefaultUsername
            }
        }
        $sDefaultPassword = if ($ConnectionInfo -and $AskInForm -and $ConnectionInfo.Password) {
            $ConnectionInfo.Password
        } else {
            $null
        }
        $sPortRegex = "^655[012][0-9]$|^6553[0-5]$|^65[0-4][0-9]{2}$|^6[0-4][0-9]{3}$|^[1-5][0-9]{4}$|^[1-9][0-9]{3}$|^[1-9][0-9]{2}$|^[1-9][0-9]$|^[0-9]$"
        $sUsernameRegex = "^(?<principalname>$DomainRegex\\$UsernameRegex)`$|^(?<upn>$UsernameRegex@$DomainRegex)`$|^(?<name>$UsernameRegex)`$"
        $sServerRegex = "^(?<dnspart>[\p{L}\p{Pc}\p{Pd}\p{Nd}]{1,63})(\.(?<dnspart>[\p{L}\p{Pc}\p{Pd}\p{Nd}]{1,63}))*$"
    }
    Process {
        if ($ConnectionInfo -and (-not $AskInForm)) {
            $sYesButtonText = "Yes, keep using %s".Replace("%s", $ConnectionInfo.Server) | Set-StringUnderline -Position 0
            $sNoButtonText = "No, enter new connection info" | Set-StringUnderline -Position 0
            $bKeepCred = Invoke-YesNoCLIDialog -Message $ReuseConnectionInfoQuestion -YesButtonText $sYesButtonText -NoButtonText $sNoButtonText -Vertical -SpaceBefore 5
            Write-Host ""
            if ($bKeepCred -eq "Yes") {
                return $ConnectionInfo 
            }
        }
        
        $hTextBoxOptions = @{
            TextBackgroundColor = $TextBackgroundColor
            TextForegroundColor = $TextForegroundColor
            HeaderBackgroundColor = $HeaderBackgroundColor
            HeaderForegroundColor = $HeaderForegroundColor
            FocusedTextBackgroundColor = $FocusedTextBackgroundColor
            FocusedTextForegroundColor = $FocusedTextForegroundColor
            FocusedHeaderBackgroundColor = $FocusedHeaderBackgroundColor
            FocusedHeaderForegroundColor = $FocusedHeaderForegroundColor
            Prefix = $Prefix
            FocusedPrefix = $FocusedPrefix
        }
        $hButtonColorOptions = @{
            BackgroundColor = $ButtonBackgroundColor
            ForegroundColor = $ButtonForegroundColor
            FocusedBackgroundColor = $FocusedButtonBackgroundColor
            FocusedForegroundColor = $FocusedButtonForegroundColor
        }
        $aRows = @()
        $iSpaceLength = 0
        $sEnterInfoQuestion = if ($HeaderAppName -eq "") {
            $EnterInfoQuestion.Replace("%a", "")
        } else {
            $EnterInfoQuestion.Replace("%a", " $HeaderAppName")
        }
        $aRows += New-CLIDialogText -Text $sEnterInfoQuestion -ForegroundColor $QuestionForegroundColor -AddNewLine
        $aEmptyLines = @()
        $iPreviousLine = -1
        if ($bAskServer) { 
            $sHeaderName = "Server"
            $aRows += New-CLIDialogTextBox -Header $sHeaderName -Text $sDefaultServer -Regex $sServerRegex @hTextBoxOptions -ValidationErrorReason "has forbidden characters" -FieldNameInErrorReason "Server" 
            if ($iSpaceLength -lt $sHeaderName.Length) { $iSpaceLength = $sHeaderName.Length }
            if (-not $sDefaultServer) {
                $aEmptyLines += 0
            }
            $iPreviousLine = 0
        }
        if ($bAskPort) { 
            $sHeaderName = "Port"
            $aRows += New-CLIDialogTextBox -Header $sHeaderName -Text $sDefaultPort -Regex $sPortRegex @hTextBoxOptions -ValidationErrorReason "must be a number between 0 and 65535" -FieldNameInErrorReason "Port" 
            if ($iSpaceLength -lt $sHeaderName.Length) { $iSpaceLength = $sHeaderName.Length }
            if ($sDefaultPort -eq "") {
                $aEmptyLines += 1
            }
            $iPreviousLine = 1
        }
        if ($bAskCred) {
            $sHeaderName = "Username"
            $aRows += New-CLIDialogTextBox -Header $sHeaderName -Text $sDefaultUsername -Regex $sUsernameRegex @hTextBoxOptions -ValidationErrorReason "has forbidden characters" -FieldNameInErrorReason "Username"
            if ($iSpaceLength -lt $sHeaderName.Length) { $iSpaceLength = $sHeaderName.Length }
            $iCurrentLine = $iPreviousLine + 1
            if ($sDefaultUsername -eq "") {
                $aEmptyLines += $iCurrentLine
            }
            $iPreviousLine = $iCurrentLine
            $sHeaderName = "Password"
            if ($sDefaultPassword) {
                $aRows += New-CLIDialogTextBox -Header $sHeaderName -Text $sDefaultPassword -Regex "^.+$" -PasswordChar "*" @hTextBoxOptions -ValidationErrorReason "can't be empty" -FieldNameInErrorReason "Password"    
            } else {
                $aRows += New-CLIDialogTextBox -Header $sHeaderName -Regex "^.+$" -PasswordChar "*" @hTextBoxOptions -ValidationErrorReason "can't be empty" -FieldNameInErrorReason "Password"    
            }            
            if ($iSpaceLength -lt $sHeaderName.Length) { $iSpaceLength = $sHeaderName.Length }
            $iCurrentLine = $iPreviousLine + 1
            $aEmptyLines += $iCurrentLine
        }
        $aRows += New-CLIDialogObjectsRow -Row @(
            New-CLIDialogSpace -Length ($iSpaceLength + $Prefix.Length + 2)
            New-CLIDialogButton -Text "OK" -Underline 0 -Keyboard O -Validate @hButtonColorOptions
            New-CLIDialogButton -Text "Cancel" -Underline 0 -Keyboard C -Cancel @hButtonColorOptions
        )
        
        $oDialog = New-CLIDialog -Rows $aRows
        $oDialog.FocusedRow = if ($aEmptyLines.Count -eq 0) { 0 } else { $aEmptyLines[0] }
        $oDialogResult = Invoke-CLIDialog -InputObject $oDialog -Validate -ErrorDetails -PauseAfterErrorMessage
    } 
    End {
        if ($oDialogResult.PSTypeNames[0] -eq "DialogResult.Action.Cancel") {
            return $oDialogResult
        } else {
            $hResult = $oDialogResult.DialogResult.Form.GetValue()
            $oResult = if ($AsHashtable.IsPresent) {
                $hResult
            } else {
                New-Object -TypeName pscustomobject -Property $hResult
            }
            $oResult.psobject.TypeNames.Insert(0, "ConnectionInfo")
            if ($oResult.Username -and $oResult.Password) {
                $oResult | Add-Member -MemberType ScriptMethod -Name "GetCredential" -Value {
                    New-Object System.Management.Automation.PSCredential ($this.Username, $this.Password)
                }
            }
            return New-DialogResultValue -Value $oResult -DialogResult $oDialogResult.DialogResult
        }
    }
}
