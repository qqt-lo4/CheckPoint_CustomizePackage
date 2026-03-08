function Copy-RemoteFile {
    <#
    .SYNOPSIS
        Copies a file to a remote location with credential support

    .DESCRIPTION
        Copies a file to a destination, automatically creating a PSDrive with credentials
        if the initial copy fails. Useful for copying to remote UNC paths requiring authentication.

    .PARAMETER source
        Source file path.

    .PARAMETER destination
        Destination path (local or UNC).

    .PARAMETER Force
        Overwrite existing files.

    .PARAMETER Credential
        Credentials for accessing remote destination.

    .OUTPUTS
        None. Copies the file to the destination.

    .EXAMPLE
        Copy-RemoteFile -source "C:\file.txt" -destination "\\server\share\file.txt" -Credential $cred

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory)]
        [string]$source,
        [Parameter(Mandatory)]
        [string]$destination,
        [switch]$Force,
        [pscredential]$Credential
    )
    try {
        Copy-Item -Path $source -Destination $destination -Force:($Force.IsPresent)
    } catch {
        if ($destination -match "^(\\\\[a-zA-Z0-9.-]+\\[^\\]+)(\\)?(.+)$") {
            $psd = New-PSDrive -Name "RemotePath" -Credential $Credential -PSProvider FileSystem -Root ($Matches.1)
            Copy-Item -Path $source -Destination ("RemotePath:\" + $Matches.3) -Force:($Force.IsPresent)
            Remove-PSDrive $psd.Name
        }
    }
}