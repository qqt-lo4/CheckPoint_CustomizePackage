@{
    # Module manifest for PSSomeCLIThings

    # Script module associated with this manifest
    RootModule        = 'PSSomeCLIThings.psm1'

    # Version number of this module
    ModuleVersion     = '1.0.0'

    # ID used to uniquely identify this module
    GUID              = '621ac807-ed02-40fe-9a6e-2fd157e84341'

    # Author of this module
    Author            = 'Loïc Ade'

    # Description of the functionality provided by this module
    Description       = 'CLI interaction toolkit: dialog system, menu builder, console formatting, string utilities, and process helpers.'

    # Minimum version of PowerShell required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = @(
        # Other
        'Convert-ConsoleColorToInt'
        'Invoke-Pause'
        'Invoke-Process'
        'Read-Array'
        'Wait-ProgressBar'
        'Write-ColoredString'
        'Write-Separator'

        # Dialog\Base
        'New-CLIDialog'
        'New-CLIDialogButton'
        'New-CLIDialogCheckBox'
        'New-CLIDialogObjectsRow'
        'New-CLIDialogProperty'
        'New-CLIDialogRadioButton'
        'New-CLIDialogSeparator'
        'New-CLIDialogSpace'
        'New-CLIDialogTableItems'
        'New-CLIDialogText'
        'New-CLIDialogTextBox'
        'New-DialogResultAction'
        'New-DialogResultScriptblock'
        'New-DialogResultValue'

        # Dialog
        'Edit-Hashtable'
        'Find-Object'
        'Invoke-CLIDialog'
        'Invoke-YesNoCLIDialog'
        'Read-CLIDialogConnectionInfo'
        'Read-CLIDialogCredential'
        'Read-CLIDialogHashtable'
        'Read-CLIDialogIP'
        'Read-CLIDialogNumericValue'
        'Read-CLIDialogValidatedValue'
        'Select-CLIDialogCSVFile'
        'Select-CLIDialogJsonFile'
        'Select-CLIDialogObjectInArray'
        'Select-CLIFileFromFolder'

        # Format
        'Format-ArrayHashtable'
        'Format-CustomHeaderTable'
        'Format-ListCustom'
        'Format-PropertyToList'
        'Format-TableCustom'
        'Get-ColumnFormat'

        # Menu
        'Invoke-Menu'
        'New-Menu'
        'New-MenuAction'
        'New-MenuItem'
        'New-MenuRow'

        # String
        'Set-StringFormat'
        'Set-StringUnderline'
    )

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport  = @()

    # Aliases to export from this module
    AliasesToExport    = @()

    # Private data to pass to the module specified in RootModule
    PrivateData       = @{
        PSData = @{
            Tags       = @('CLI', 'Dialog', 'Menu', 'Console', 'Formatting', 'TUI')
            ProjectUri = ''
        }
    }
}
