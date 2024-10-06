function Get-FileTypeShellExtensionCommand {
    Param(
        [Parameter(Mandatory)]
        [string]$FileType,
        [Parameter(Mandatory)]
        [Alias("Command")]
        [string]$ShellExtensionName
    )
    Begin {
        function Split-CommandLine {
            Param(
                [Parameter(Mandatory, Position=0)][string]$cmd
            )
            $result = if ($cmd -match "^`"(?<program>.+)`" (?<arguments>.*)$") {
                [pscustomobject]@{
                    program = $Matches.program
                    arguments = $Matches.arguments
                }
            } else {
                if ($cmd -match "^(?<program>[^ ]+) (?<arguments>.*)$") {
                    [pscustomobject]@{
                        program = $Matches.program
                        arguments = $Matches.arguments
                    }
                }
            }
            return $result
        }
        $hkcr = Get-PSDrive -PSProvider registry | Where-Object { $_.root -eq "HKEY_CLASSES_ROOT" }
        if ($null -eq $hkcr) {
            $hkcr = New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR
        }
        $sRootKey = if ($FileType -match "^\..+$")  {
            (Get-ItemProperty ($hkcr.Name + ":\$FileType"))."(default)"
        } else {
            $FileType
        }
    }
    Process {
        $regPath =  $hkcr.Name + ":\" + $sRootKey + "\Shell\$ShellExtensionName\Command"
        if (Test-Path $regPath) {
            $command = ((Get-ItemProperty ($regPath))."(default)")
            $objCommand = Split-CommandLine $command
            return @{
                Program = $objCommand.program
                Arguments = $objCommand.arguments
            }
        } else {
            throw [System.IO.FileNotFoundException] "Command or file type not found"
        }
    }
}