function Invoke-IgnoreSSL {
    <#
    .SYNOPSIS
        Disables SSL certificate validation for web requests

    .DESCRIPTION
        Configures the PowerShell session to ignore SSL certificate errors.
        On PowerShell 5, registers a custom ServerCertificateValidationCallback
        that accepts all certificates. On PowerShell 7+, sets SkipCertificateCheck
        as default parameter for Invoke-WebRequest and Invoke-RestMethod.

    .OUTPUTS
        None.

    .EXAMPLE
        Invoke-IgnoreSSL

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    # For PowerShell 5
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        
        if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type) {
            $certCallback = @"
                using System;
                using System.Net;
                using System.Net.Security;
                using System.Security.Cryptography.X509Certificates;
                public class ServerCertificateValidationCallback
                {
                    public static void Ignore()
                    {
                        ServicePointManager.ServerCertificateValidationCallback = 
                            delegate
                            (
                                Object obj, 
                                X509Certificate certificate, 
                                X509Chain chain, 
                                SslPolicyErrors errors
                            )
                            {
                                return true;
                            };
                    }
                }
"@
            Add-Type $certCallback
            [ServerCertificateValidationCallback]::Ignore()
        }
    }
    # For PowerShell 7+
    else {
        $Global:PSDefaultParameterValues = @{
            'Invoke-WebRequest:SkipCertificateCheck' = $true
            'Invoke-RestMethod:SkipCertificateCheck' = $true
        }
    }
}