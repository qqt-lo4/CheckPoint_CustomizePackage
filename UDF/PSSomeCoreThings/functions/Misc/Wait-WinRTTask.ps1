Function Wait-WinRTTask {
    <#
    .SYNOPSIS
        Converts and waits for a Windows Runtime async task to complete

    .DESCRIPTION
        Bridges WinRT async operations to synchronous PowerShell by converting
        an IAsyncOperation to a .NET Task and waiting for its result.

    .PARAMETER WinRtTask
        The WinRT async operation to wait for.

    .PARAMETER ResultType
        The expected result type of the async operation.

    .OUTPUTS
        The result of the completed async task.

    .EXAMPLE
        $result = Wait-WinRTTask -WinRtTask $asyncOp -ResultType ([string])

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    Param($WinRtTask, $ResultType)
    $asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
    $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
    $netTask = $asTask.Invoke($null, @($WinRtTask))
    $netTask.Wait(-1) | Out-Null
    $netTask.Result
}