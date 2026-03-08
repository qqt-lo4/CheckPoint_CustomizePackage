function ConvertFrom-MSZIPYaml {
    <#
    .SYNOPSIS
        Decompresses MSZIP compressed data (mszyml format)
    
    .DESCRIPTION
        Decompresses MSZIP format used by WinGet for versionData.mszyml files
    
    .PARAMETER Buffer
        Byte array containing the compressed MSZIP data
    
    .OUTPUTS
        System.String. The decompressed YAML content as a string.

    .EXAMPLE
        $buffer = [System.IO.File]::ReadAllBytes("versionData.mszyml")
        $decompressed = ConvertFrom-MSZIPYaml -Buffer $buffer

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [byte[]]$Buffer
    )
    
    begin {
        # Magic header for MSZIP chunks: 0x00, 0x00, 0x43, 0x4B ('CK')
        $magicHeader = [byte[]](0x00, 0x00, 0x43, 0x4B)
        $decompressed = [System.IO.MemoryStream]::new()
    }
    
    process {
        Add-Type -AssemblyName System.IO.Compression
        
        # Check if file header matches MSZIP format
        if (-not ($Buffer[26..29] -join ',') -eq ($magicHeader -join ',')) {
            throw "Invalid MSZIP format: magic header not found at position 26"
        }
        
        # Start searching from file header
        $chunkIndex = 26
        
        # Create memory stream from buffer
        $bufferStream = [System.IO.MemoryStream]::new($Buffer)
        
        # Loop through and decompress each chunk
        while ($chunkIndex -lt $Buffer.Length) {
            $chunkIndex += $magicHeader.Length
            $bufferStream.Position = $chunkIndex
            
            try {
                $decompressedChunk = New-Object System.IO.Compression.DeflateStream($bufferStream, [System.IO.Compression.CompressionMode]::Decompress)
                $decompressedChunk.CopyTo($decompressed)
            } catch {
                # End of chunks or decompression error
                break
            }
            $chunkIndex++
        }
    }
    
    end {
        # Read decompressed data
        $decompressed.Position = 0
        $reader = [System.IO.StreamReader]::new($decompressed)
        $result = $reader.ReadToEnd()

        # Cleanup
        $reader.Dispose()
        $decompressed.Dispose()

        # Remove lines containing invalid characters (decompression artifacts)
        # Valid YAML only contains printable characters, tabs, and standard Unicode
        $cleanLines = $result -split "`n" | Where-Object {
            $_ -notmatch '[^\x09\x0A\x0D\x20-\x7E\xA0-\xFFFF]'
        }

        return ($cleanLines -join "`n")
    }
}