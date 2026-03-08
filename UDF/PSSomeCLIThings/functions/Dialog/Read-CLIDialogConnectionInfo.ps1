function Read-CLIDialogConnectionInfo {
    <#
    .SYNOPSIS
        Prompts the user to enter connection information (server, port, credentials) via an interactive CLI dialog.

    .DESCRIPTION
        This function displays an interactive CLI dialog to collect connection information from the user,
        including server address, port number, username, and password. It supports two parameter sets:
        Manual mode (explicitly specify which fields to ask) and Autodetect mode (uses application
        configuration to determine required fields). The function can reuse existing ConnectionInfo
        objects, validate input with regex patterns, and return results as either hashtables or custom
        objects with PSTypeName "ConnectionInfo". It includes a GetCredential() script method when
        credentials are collected.

    .PARAMETER ConnectionInfo
        An existing ConnectionInfo object to reuse. If provided and AskInForm is not set, the user
        will be prompted whether to keep the existing connection info or enter new values. Can be $null.
        Must have PSTypeName "ConnectionInfo" if not null.

    .PARAMETER AskInForm
        Switch parameter. When set, always displays the form even if ConnectionInfo is provided,
        pre-populating fields with existing values from ConnectionInfo.

    .PARAMETER DomainRegex
        Regular expression pattern to match domain names in usernames. Used for parsing usernames
        in formats like "DOMAIN\User" or "user@domain.com". Default: "(?<domain>[A-Za-z._0-9-]+)"

    .PARAMETER UsernameRegex
        Regular expression pattern to match username portions. Supports Unicode letters, connectors,
        dashes, digits, and spaces. Default: "(?<user>[\p{L}\p{Pc}\p{Pd}\p{Nd} ]+)"

    .PARAMETER EnterInfoQuestion
        The question text displayed at the top of the form. Use "%a" as placeholder for the
        application name. Default: "Please enter informations to connect to%a:"

    .PARAMETER HeaderAppName
        Application name to display in questions and prompts. Replaces "%a" placeholder in
        EnterInfoQuestion. Empty string by default.

    .PARAMETER QuestionForegroundColor
        Foreground color for the question text. Defaults to current console foreground color.

    .PARAMETER TextForegroundColor
        Foreground color for textbox text. Defaults to current console foreground color.

    .PARAMETER TextBackgroundColor
        Background color for textbox text. Defaults to current console background color.

    .PARAMETER HeaderForegroundColor
        Foreground color for textbox headers (field labels). Default: Green

    .PARAMETER HeaderBackgroundColor
        Background color for textbox headers. Defaults to current console background color.

    .PARAMETER FocusedTextForegroundColor
        Foreground color for focused textbox text. Defaults to current console foreground color.

    .PARAMETER FocusedTextBackgroundColor
        Background color for focused textbox text. Defaults to current console background color.

    .PARAMETER FocusedHeaderForegroundColor
        Foreground color for focused textbox headers. Default: Blue

    .PARAMETER FocusedHeaderBackgroundColor
        Background color for focused textbox headers. Defaults to current console background color.

    .PARAMETER ButtonBackgroundColor
        Background color for buttons. Defaults to current console background color.

    .PARAMETER ButtonForegroundColor
        Foreground color for buttons. Defaults to current console foreground color.

    .PARAMETER FocusedButtonBackgroundColor
        Background color for focused button. Defaults to current console foreground color (inverted).

    .PARAMETER FocusedButtonForegroundColor
        Foreground color for focused button. Defaults to current console background color (inverted).

    .PARAMETER Prefix
        Prefix string displayed before unfocused controls. Default: "  " (two spaces)

    .PARAMETER FocusedPrefix
        Prefix string displayed before focused controls. Default: "> "

    .PARAMETER DefaultServer
        Default value for the server field. Used in Manual mode or as fallback in Autodetect mode.

    .PARAMETER DefaultPort
        Default value for the port field. Use -1 to leave empty. Used in Manual mode or as fallback
        in Autodetect mode. Default: -1

    .PARAMETER DefaultUsername
        Default value for the username field. Used in Manual mode or as fallback in Autodetect mode.

    .PARAMETER Server
        Switch parameter (Manual mode). When set, prompts for server address.

    .PARAMETER Port
        Switch parameter (Manual mode). When set, prompts for port number. Requires Server to also be set.

    .PARAMETER Credential
        Switch parameter (Manual mode). When set, prompts for username and password.

    .PARAMETER AppName
        Application name (Autodetect mode). Used to lookup required connection fields from the
        Config object at $Config.RequiredConnectionInfo.$AppName and default values from
        $Config.Apps.$AppName.

    .PARAMETER Config
        Configuration object (Autodetect mode). Must contain RequiredConnectionInfo and Apps
        properties with application-specific settings. Default: $Global:Config

    .PARAMETER AsHashtable
        Switch parameter. When set, returns result as hashtable instead of PSCustomObject.
        The ConnectionInfo PSTypeName is still added.

    .OUTPUTS
        Returns a PSCustomObject or Hashtable with PSTypeName "ConnectionInfo" containing:
        - Server: Server address (if requested)
        - Port: Port number (if requested)
        - Username: Username (if credentials requested)
        - Password: SecureString password (if credentials requested)
        - GetCredential(): Script method that returns PSCredential object (if credentials requested)
        Returns $null if user cancels the dialog.

    .EXAMPLE
        $connInfo = Read-CLIDialogConnectionInfo -Server -Port -Credential
        if ($connInfo) {
            Connect-RemoteServer -Server $connInfo.Server -Port $connInfo.Port -Credential $connInfo.GetCredential()
        }

        Prompts for server, port, and credentials in Manual mode. Uses the returned info to connect.

    .EXAMPLE
        $connInfo = Read-CLIDialogConnectionInfo -AppName "MySQLServer" -Config $Global:Config
        # Config determines which fields are required based on $Config.RequiredConnectionInfo.MySQLServer

        Uses Autodetect mode with application configuration to determine required fields.

    .EXAMPLE
        $connInfo = Read-CLIDialogConnectionInfo -Server -DefaultServer "localhost" -DefaultPort 8080
        # Pre-populates server as "localhost" and port as 8080

        Uses Manual mode with default values pre-filled.

    .EXAMPLE
        $connInfo = Read-CLIDialogConnectionInfo -ConnectionInfo $existingConn -Server -Port -Credential
        # Asks user if they want to reuse $existingConn or enter new values

        Offers to reuse existing connection info or prompt for new values.

    .EXAMPLE
        $connInfo = Read-CLIDialogConnectionInfo -Server -Credential -AsHashtable
        # Returns hashtable instead of PSCustomObject

        Returns connection info as hashtable with ConnectionInfo PSTypeName.

    .NOTES
        Module: CLIDialog
        Author: Loïc Ade
        Modified: 2025-11-22
        Version: 1.0.1
        Dependencies: New-CLIDialogText, New-CLIDialogTextBox, New-CLIDialogSpace, New-CLIDialogButton, New-CLIDialogObjectsRow, New-CLIDialog, Invoke-CLIDialog, Invoke-YesNoCLIDialog, Set-StringUnderline

        This function is designed for applications that need to collect connection parameters
        interactively from users, particularly for remote server connections, database connections,
        or API endpoints.

        PARAMETER SETS:
        1. Manual: Explicitly specify which fields to request via switches (-Server, -Port, -Credential)
        2. Autodetect: Use application configuration to determine required fields via -AppName and -Config

        FIELD REQUIREMENTS:
        - If no switches are provided in Manual mode, all fields (Server, Port, Credential) are requested
        - Port cannot be requested without Server (throws ArgumentException)
        - In Autodetect mode, $Config.RequiredConnectionInfo.$AppName determines which fields are required

        VALIDATION:
        - Server: Must match DNS name pattern (labels up to 63 chars, letters, numbers, hyphens, underscores)
        - Port: Must be valid port number (0-65535)
        - Username: Supports formats "DOMAIN\User", "user@domain.com", or simple "username"
        - Password: Cannot be empty

        REGEX PATTERNS:
        - Server regex: ^(?<dnspart>[\p{L}\p{Pc}\p{Pd}\p{Nd}]{1,63})(\.(?<dnspart>[\p{L}\p{Pc}\p{Pd}\p{Nd}]{1,63}))*$
        - Port regex: Validates numbers 0-65535
        - Username regex: Combines DomainRegex and UsernameRegex to support multiple formats

        DEFAULT VALUE PRIORITY (Autodetect mode):
        1. Config.Apps.$AppName values (highest priority)
        2. Default* parameter values
        3. ConnectionInfo object values (if AskInForm is set)

        CONNECTIONINFO OBJECT STRUCTURE:
        ```powershell
        [PSCustomObject]@{
            PSTypeName = "ConnectionInfo"
            Server = "example.com"
            Port = 443
            Username = "user@domain.com"
            Password = [SecureString]
            GetCredential = [ScriptMethod] # Returns PSCredential
        }
        ```

        REUSE BEHAVIOR:
        - If ConnectionInfo is provided and AskInForm is false, asks user "Do you want to keep them?"
        - User can choose to reuse existing info or enter new values
        - If user chooses "Yes", existing ConnectionInfo is returned unchanged

        FOCUS BEHAVIOR:
        - Dialog automatically focuses the first empty field
        - If all fields have default values, focuses the first field (index 0)

        COLOR CUSTOMIZATION:
        All colors can be customized via parameters. Default colors adapt to current console theme,
        making the dialog work well in both light and dark terminal color schemes.

        KEYBOARD NAVIGATION:
        - Tab/Shift+Tab: Move between fields
        - Enter: Submit form (when on OK button or any valid field)
        - O: Press OK button
        - C: Press Cancel button
        - Esc: Cancel dialog

        ERROR HANDLING:
        - Invalid ConnectionInfo type throws exception
        - Port without Server throws ArgumentException
        - Validation errors display inline with field-specific error messages
        - Cancellation returns $null (not an error)

        CHANGELOG:

        Version 1.0.1 - 2025-11-22 - Loïc Ade
            - Corrected an error when Cancel was pressed by user 

        Version 1.0.0 - 2023-12-17 - Loïc Ade
            - Initial release
            - Support for Manual and Autodetect parameter sets
            - Server, Port, and Credential collection
            - Input validation with customizable regex patterns
            - ConnectionInfo reuse functionality
            - GetCredential() script method for PSCredential creation
            - Full color customization support
            - Unicode username support
            - Multiple username format support (DOMAIN\User, user@domain.com, username)
            - Automatic focus on first empty field
            - Integration with CLI Dialog framework
    #>
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
        $oResult = $null
        if ($ConnectionInfo -and (-not $AskInForm)) {
            $sYesButtonText = "Yes, keep using %s".Replace("%s", $ConnectionInfo.Server) | Set-StringUnderline -Position 0
            $sNoButtonText = "No, enter new connection info" | Set-StringUnderline -Position 0
            $ReuseConnectionInfoQuestion = if ($HeaderAppName -ne $null) {
                "Connection informations are already in the `$ConnectionInfo variable. Do you want to keem them to connect to $($HeaderAppName)?"
            } else {
                "Connection informations are already in the `$ConnectionInfo variable. Do you want to keem them?"
            }
            $bKeepCred = Invoke-YesNoCLIDialog -Message $ReuseConnectionInfoQuestion -YesButtonText $sYesButtonText -NoButtonText $sNoButtonText -Vertical -SpaceBefore 5
            Write-Host ""
            if ($bKeepCred -eq "Yes") {
                $oResult = $ConnectionInfo 
            }
        }
        
        if ($oResult -eq $null) {
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
            if ($oDialogResult.PSTypeNames[0] -eq "DialogResult.Action.Cancel") {
                $oResult = $null
            } else {
                $hResult = $oDialogResult.DialogResult.Form.GetValue()
                $oResult = if ($AsHashtable.IsPresent) {
                    $hResult
                } else {
                    New-Object -TypeName pscustomobject -Property $hResult
                }
            }
        }
    } 
    End {
        if ($null -eq $oResult) {
            return $null
        } else {
            $oResult.psobject.TypeNames.Insert(0, "ConnectionInfo")
            if ($oResult.Username -and $oResult.Password) {
                $oResult | Add-Member -MemberType ScriptMethod -Name "GetCredential" -Force -Value {
                    New-Object System.Management.Automation.PSCredential ($this.Username, $this.Password)
                }
            }
            return $oResult
        }
    }
}
