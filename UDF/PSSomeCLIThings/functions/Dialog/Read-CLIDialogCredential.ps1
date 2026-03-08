function Read-CLIDialogCredential {
    <#
    .SYNOPSIS
        Prompts the user to enter credentials (username and password) via an interactive CLI dialog.

    .DESCRIPTION
        This function displays an interactive CLI dialog to collect user credentials, including
        username and password. It can reuse existing PSCredential objects, validate input with
        regex patterns, and return results as PSCredential objects. This function is a wrapper
        around Read-CLIDialogConnectionInfo that simplifies credential collection by only
        requesting username and password fields.

    .PARAMETER Credential
        An existing PSCredential object to reuse. If provided, the user will be prompted
        whether to keep the existing credentials or enter new values. Can be $null.

    .PARAMETER DomainRegex
        Regular expression pattern to match domain names in usernames. Used for parsing usernames
        in formats like "DOMAIN\User" or "user@domain.com". Default: "(?<domain>[A-Za-z._0-9-]+)"

    .PARAMETER UsernameRegex
        Regular expression pattern to match username portions. Supports Unicode letters, connectors,
        dashes, digits, and spaces. Default: "(?<user>[\p{L}\p{Pc}\p{Pd}\p{Nd} ]+)"

    .PARAMETER EnterCredQuestion
        The question text displayed at the top of the form. Default: "Please enter credentials:"
        This parameter has an alias "Message" for backward compatibility.

    .PARAMETER ReuseCredQuestion
        The question text displayed when credentials already exist and the user is asked whether
        to reuse them. Default: "Credentials are already in the `$Credential variable. Do you want to keem them?"

    .PARAMETER PreviousUsername
        Default value for the username field. If provided, the username textbox will be
        pre-populated with this value and the focus will start on the password field.

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

    .PARAMETER AddCancel
        Switch parameter. When set, adds a Cancel button to the dialog in addition to the OK button.
        Note: Currently not implemented in the underlying Read-CLIDialogConnectionInfo function.

    .OUTPUTS
        Returns a PSCredential object containing the username and password.
        Returns $null if user cancels the dialog.

    .EXAMPLE
        $cred = Read-CLIDialogCredential
        if ($cred) {
            Connect-RemoteServer -Credential $cred
        }

        Prompts for credentials and uses them to connect to a remote server.

    .EXAMPLE
        $cred = Read-CLIDialogCredential -PreviousUsername "DOMAIN\jdoe"
        # Pre-populates username field and focuses on password field

        Pre-fills the username field with a previous value.

    .EXAMPLE
        $cred = Read-CLIDialogCredential -Credential $existingCred
        # Asks user if they want to reuse $existingCred or enter new credentials

        Offers to reuse existing credentials or prompt for new values.

    .EXAMPLE
        $cred = Read-CLIDialogCredential -Message "Enter admin credentials:" -AddCancel
        # Custom message and allows cancellation

        Customizes the prompt message and adds a Cancel button.

    .NOTES
        Module: CLIDialog
        Author: Loïc Ade
        Created: 2025-10-01
        Modified: 2025-10-23
        Version: 2.0.0
        Dependencies: Read-CLIDialogConnectionInfo

        This function is a simplified wrapper around Read-CLIDialogConnectionInfo that
        only requests credential fields (username and password). For more complex scenarios
        that require server address, port, or other connection parameters, use
        Read-CLIDialogConnectionInfo directly.

        VALIDATION:
        - Username: Supports formats "DOMAIN\User", "user@domain.com", or simple "username"
        - Password: Cannot be empty

        REGEX PATTERNS:
        - Username regex: Combines DomainRegex and UsernameRegex to support multiple formats
        - Supports Unicode characters in usernames for international user accounts

        REUSE BEHAVIOR:
        - If Credential is provided, asks user "Do you want to keep them?"
        - User can choose to reuse existing credentials or enter new values
        - If user chooses "Yes", existing PSCredential is returned unchanged

        FOCUS BEHAVIOR:
        - Dialog automatically focuses on the username field by default
        - If PreviousUsername is provided, focuses on the password field instead

        COLOR CUSTOMIZATION:
        All colors can be customized via parameters. Default colors adapt to current console theme,
        making the dialog work well in both light and dark terminal color schemes.

        KEYBOARD NAVIGATION:
        - Tab/Shift+Tab: Move between fields
        - Enter: Submit form (when on OK button or any valid field)
        - O: Press OK button
        - C: Press Cancel button (if AddCancel is set)
        - Esc: Cancel dialog

        ERROR HANDLING:
        - Validation errors display inline with field-specific error messages
        - Cancellation returns $null (not an error)

        CHANGELOG:

        Version 2.0.0 - 2025-10-23 - Loïc Ade
            - Refactored to use Read-CLIDialogConnectionInfo internally
            - Eliminated code duplication
            - Maintained backward compatibility with existing API
            - All functionality now delegated to Read-CLIDialogConnectionInfo

        Version 1.0.0 - 2025-10-01 - Loïc Ade
            - Initial release
            - Username and password collection
            - Input validation with customizable regex patterns
            - PSCredential reuse functionality
            - Full color customization support
            - Unicode username support
            - Multiple username format support (DOMAIN\User, user@domain.com, username)
            - Integration with CLI Dialog framework
    #>
    [OutputType([pscredential])]
    param (
        [AllowNull()]
        [Parameter(Position = 0)]
        [pscredential]$Credential,
        [string]$DomainRegex = "(?<domain>[A-Za-z._0-9-]+)",
        [string]$UsernameRegex = "(?<user>[\p{L}\p{Pc}\p{Pd}\p{Nd} ]+)",
        [Alias("Message")]
        [string]$EnterCredQuestion = "Please enter informations to connect to%a:",
        [string]$ReuseCredQuestion = "Credentials are already in the `$Credential variable. Do you want to keem them?",
        [string]$PreviousUsername,
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
        [switch]$AddCancel,
        [string]$HeaderAppName = ""
    )

    # Convert PSCredential to ConnectionInfo if necessary
    $oConnectionInfo = if ($Credential) {
        [PSCustomObject]@{
            PSTypeName = "ConnectionInfo"
            Username = $Credential.UserName
            Password = $Credential.Password
        }
    } else {
        $null
    }

    # Prepare parameters for Read-CLIDialogConnectionInfo
    $hParams = @{
        ConnectionInfo = $oConnectionInfo
        Credential = $true
        DomainRegex = $DomainRegex
        UsernameRegex = $UsernameRegex
        EnterInfoQuestion = $EnterCredQuestion
        QuestionForegroundColor = $QuestionForegroundColor
        TextForegroundColor = $TextForegroundColor
        TextBackgroundColor = $TextBackgroundColor
        HeaderForegroundColor = $HeaderForegroundColor
        HeaderBackgroundColor = $HeaderBackgroundColor
        FocusedTextForegroundColor = $FocusedTextForegroundColor
        FocusedTextBackgroundColor = $FocusedTextBackgroundColor
        FocusedHeaderForegroundColor = $FocusedHeaderForegroundColor
        FocusedHeaderBackgroundColor = $FocusedHeaderBackgroundColor
        ButtonBackgroundColor = $ButtonBackgroundColor
        ButtonForegroundColor = $ButtonForegroundColor
        FocusedButtonBackgroundColor = $FocusedButtonBackgroundColor
        FocusedButtonForegroundColor = $FocusedButtonForegroundColor
        Prefix = $Prefix
        FocusedPrefix = $FocusedPrefix
        DefaultUsername = $PreviousUsername
        HeaderAppName = $HeaderAppName
    }

    # Call Read-CLIDialogConnectionInfo
    $oResult = Read-CLIDialogConnectionInfo @hParams

    # Convert the ConnectionInfo result to PSCredential
    if ($oResult) {
        return $oResult.GetCredential()
    } else {
        return $null
    }
}
