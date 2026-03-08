@{
    # Module manifest for PSSomeAppsThings

    # Script module associated with this manifest
    RootModule        = 'PSSomeAppsThings.psm1'

    # Version number of this module
    ModuleVersion     = '1.0.0'

    # ID used to uniquely identify this module
    GUID              = '3fe4102b-4801-4bc3-8466-00c74ceafccb'

    # Author of this module
    Author            = 'Loïc Ade'

    # Description of the functionality provided by this module
    Description       = 'Application management functions: installed programs listing, Winget operations, Microsoft Store integration, and Windows Installer (MSI) utilities.'

    # Minimum version of PowerShell required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = '*'

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport  = @()

    # Aliases to export from this module
    AliasesToExport    = @()

    # Private data to pass to the module specified in RootModule
    PrivateData       = @{
        PSData = @{
            Tags       = @('Applications', 'Winget', 'MicrosoftStore', 'MSI', 'WindowsInstaller', 'PackageManagement')
            ProjectUri = ''
        }
    }
}
