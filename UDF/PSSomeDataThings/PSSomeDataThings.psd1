@{
    # Module manifest for PSSomeDataThings

    # Script module associated with this manifest
    RootModule        = 'PSSomeDataThings.psm1'

    # Version number of this module
    ModuleVersion     = '1.0.0'

    # ID used to uniquely identify this module
    GUID              = 'd5bf00a6-2b9b-4a9c-8fbc-ffb81f1d4519'

    # Author of this module
    Author            = 'Loïc Ade'

    # Description of the functionality provided by this module
    Description       = 'Data manipulation utilities: array pagination, CSV parsing, hashtable operations, JSON helpers, regex repository, string processing, and type conversion.'

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
            Tags       = @('Data', 'Array', 'Hashtable', 'String', 'CSV', 'JSON', 'Regex', 'Conversion')
            ProjectUri = ''
        }
    }
}
