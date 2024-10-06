function Invoke-POWmi {
	[CmdletBinding(DefaultParameterSetName = 'Credential')]
	Param(
		[ValidateNotNullOrEmpty()]
		[Alias('Name')]
		$PipeName = ([guid]::NewGuid()).Guid.ToString(),
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[scriptblock]$ScriptBlock,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName = 'localhost',
		[Parameter(ParameterSetName = 'Credential',
				 Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[pscredential]$Credential,
		[ValidateRange(1000, 900000)]
		[int32]$Timeout = 120000,
		[Parameter(ParameterSetName = 'ByPassCreds')]
		[switch]$BypassCreds
	)

    function ConvertFrom-CliXml {
        Param (
            [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
            [ValidateNotNullOrEmpty()]
            [String[]]$InputObject
        )
        Begin {
            $OFS = "`n"
            [String]$xmlString = ""
        }
        Process {
            $xmlString += $InputObject
        }
        End {
            $type = [PSObject].Assembly.GetType('System.Management.Automation.Deserializer')
            $ctor = $type.GetConstructor('instance,nonpublic', $null, @([xml.xmlreader]), $null)
            $sr = New-Object System.IO.StringReader $xmlString
            $xr = New-Object System.Xml.XmlTextReader $sr
            $deserializer = $ctor.Invoke($xr)
            $done = $type.GetMethod('Done', [System.Reflection.BindingFlags]'nonpublic,instance')
            while (!$type.InvokeMember("Done", "InvokeMethod,NonPublic,Instance", $null, $deserializer, @())) {
                try {
                    $type.InvokeMember("Deserialize", "InvokeMethod,NonPublic,Instance", $null, $deserializer, @())
                } catch {
                    Write-Warning "Could not deserialize ${string}: $_"
                }
            }
            $xr.Close()
            $sr.Dispose()
        }
    }

    function ConvertFrom-Base64ToObject {
        [CmdletBinding()]
        Param (
            [Parameter(Mandatory = $true,
                    Position = 0)]
            [ValidateNotNullOrEmpty()]
            [Alias('string')]
            [string]$inputString
        )
        $data = [System.convert]::FromBase64String($inputString)
        $memoryStream = New-Object System.Io.MemoryStream
        $memoryStream.write($data, 0, $data.length)
        $memoryStream.seek(0, 0) | Out-Null
        $streamReader = New-Object System.IO.StreamReader(New-Object System.IO.Compression.GZipStream($memoryStream, [System.IO.Compression.CompressionMode]::Decompress))
        $decompressedData = ConvertFrom-CliXml ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($streamReader.readtoend()))))
        return $decompressedData
    }

    function ConvertTo-CliXml {
        param (
            [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
            [ValidateNotNullOrEmpty()]
            [PSObject[]]$InputObject
        )
        return [management.automation.psserializer]::Serialize($InputObject)
    }

    function ConvertTo-Base64StringFromObject {
        [CmdletBinding()]
        [OutputType([string])]
        param (
            [Parameter(Mandatory = $true, Position = 0)]
            [ValidateNotNullOrEmpty()]
            [Alias('object', 'data','input')]
            [psobject]$inputObject
        )
        $tempString = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes([management.automation.psserializer]::Serialize($inputObject)))
        $memoryStream = New-Object System.IO.MemoryStream
        $compressionStream = New-Object System.IO.Compression.GZipStream($memoryStream, [System.io.compression.compressionmode]::Compress)
        $streamWriter = New-Object System.IO.streamwriter($compressionStream)
        $streamWriter.write($tempString)
        $streamWriter.close()
        $compressedData = [System.convert]::ToBase64String($memoryStream.ToArray())
        return $compressedData
    }
	
	$scriptBlockPreEncoded = [scriptblock]{
		#region support functions
		function ConvertTo-CliXml {
			Param (
				[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
				[ValidateNotNullOrEmpty()]
				[PSObject[]]$InputObject
			)
			return [management.automation.psserializer]::Serialize($InputObject)
		}
		
		function ConvertTo-Base64StringFromObject {
			[CmdletBinding()]
			Param (
				[Parameter(Mandatory = $true,
						 ValueFromPipeline = $true,
						 Position = 0)]
				[ValidateNotNullOrEmpty()]
				[object]$inputobject
			)
			
			$holdingXml = ConvertTo-CliXml -InputObject $inputobject
			$preConversion_bytes = [System.Text.Encoding]::UTF8.GetBytes($holdingXml)
			$preconversion_64 = [System.Convert]::ToBase64String($preConversion_bytes)
			$memoryStream = New-Object System.IO.MemoryStream
			$compressionStream = New-Object System.IO.Compression.GZipStream($memoryStream, [System.io.compression.compressionmode]::Compress)
			$streamWriter = New-Object System.IO.streamwriter($compressionStream)
			$streamWriter.write($preconversion_64)
			$streamWriter.close()
			$compressedData = [System.convert]::ToBase64String($memoryStream.ToArray())
			return $compressedData
		}
		#endregion
		
		$namedPipe = new-object System.IO.Pipes.NamedPipeServerStream "<pipename>", "Out"
		$namedPipe.WaitForConnection()
		$streamWriter = New-Object System.IO.StreamWriter $namedPipe
		$streamWriter.AutoFlush = $true
		$TempResultPreConversion = &{ <scriptBlock> }
		$results = ConvertTo-Base64StringFromObject -inputObject $TempResultPreConversion
		$streamWriter.WriteLine("$($results)")
		$streamWriter.dispose()
		$namedPipe.dispose()
	}
	
	$scriptBlockPreEncoded = $scriptBlockPreEncoded -replace "<pipename>", $PipeName
	$scriptBlockPreEncoded = $scriptBlockPreEncoded -replace "<scriptBlock>", $ScriptBlock
	$byteCommand = [System.Text.encoding]::UTF8.GetBytes($scriptBlockPreEncoded)
	$encodedScriptBlock = [convert]::ToBase64string($byteCommand)
	
	$holderData = if ($($env:computername) -eq $ComputerName -or $BypassCreds) {
		Invoke-wmimethod -computername "$($ComputerName)" -class win32_process -name create -argumentlist "powershell.exe (invoke-command ([scriptblock]::Create([system.text.encoding]::UTF8.GetString([System.convert]::FromBase64string('$($encodedScriptBlock)')))))"
	} else {
		Invoke-wmimethod -computername "$($ComputerName)" -class win32_process -name create -argumentlist "powershell.exe (invoke-command ([scriptblock]::Create([system.text.encoding]::UTF8.GetString([System.convert]::FromBase64string(`"$($encodedScriptBlock))`"))))" -Credential $Credential
	}
	
	$namedPipe = New-Object System.IO.Pipes.NamedPipeClientStream $ComputerName, "$($PipeName)", "In"
	$namedPipe.connect($timeout)
	$streamReader = New-Object System.IO.StreamReader $namedPipe
	
	while ($null -ne ($data = $streamReader.ReadLine()))
	{
		$tempData = $data
	}
	
	$streamReader.dispose()
	$namedPipe.dispose()
	
	ConvertFrom-Base64ToObject -inputString $tempData
}
#https://github.com/threatexpress/invoke-pipeshell/blob/master/Invoke-PipeShell.ps1