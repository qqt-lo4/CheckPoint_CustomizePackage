@{
    # Module manifest for PSSomeFileThings

    # Script module associated with this manifest
    RootModule        = 'PSSomeFileThings.psm1'

    # Version number of this module
    ModuleVersion     = '1.0.0'

    # ID used to uniquely identify this module
    GUID              = 'f1df3a9e-a9ef-4a51-a45a-985aef62874c'

    # Author of this module
    Author            = 'Loïc Ade'

    # Description of the functionality provided by this module
    Description       = 'File system utilities: 7-Zip archive creation, CAB file operations, path manipulation, file rotation, and remote file copy.'

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
            Tags       = @('File', 'Archive', '7Zip', 'CAB', 'Path', 'FileRotation')
            ProjectUri = ''
        }
    }
}