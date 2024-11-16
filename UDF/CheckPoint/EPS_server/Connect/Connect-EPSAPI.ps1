function Connect-EPSAPI {
    Param(
        [Parameter(Mandatory)]
        [string]$Server,
        [int]$Port,
        [Parameter(Mandatory)]
        [string]$Username,
        [Parameter(Mandatory)]
        [securestring]$Password,
        [switch]$IgnoreSSLError,
        [switch]$GlobalVar
    )
    Begin {
        $sURL = "https://$server`:$Port/webmgmt/graphql/"
        $sOperationName = "loginOnPremise"
        $sQuery = "query loginOnPremise(`$user: String!, `$password: String!) {
            loginOnPremise(user: `$user, password: `$password) {
              token
              apiVersion
              isReadOnly
              serverVersionInfo {
                majorVersion
                takeNumber
                hotFixVersions
                beBundle
                branchName
                __typename
              }
              __typename
            }
          }"
        $hVariables = @{
            user = $Username
            password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
        }
    }
    Process {
        $iwr = Invoke-GraphQLQuery -Uri $sURL -OperationName $sOperationName -Query $sQuery -Variables $hVariables -IgnoreSSLError:$ignoreSSLError.IsPresent
        if ($null -ne $iwr) {
            $oResult = [PSCustomObject]@{
                Server = $Server
                Port = $Port
                BaseURL = $sURL
                User = $Username
                Password = $Password
                Token = $iwr.data.loginOnPremise.token
                IgnoreSSLError = $IgnoreSSLError.IsPresent
                WebRequest = $iwr
            }
            $oResult | Add-Member -MemberType ScriptMethod -Name "Reconnect" -Value {
                $sOperationName = "loginOnPremise"
                $sQuery = "query loginOnPremise(`$user: String!, `$password: String!) {
                    loginOnPremise(user: `$user, password: `$password) {
                      token
                      apiVersion
                      isReadOnly
                      serverVersionInfo {
                        majorVersion
                        takeNumber
                        hotFixVersions
                        beBundle
                        branchName
                        __typename
                      }
                      __typename
                    }
                  }"
                $hVariables = @{
                    user = $this.User
                    password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($this.Password))
                }
                $iwr = Invoke-GraphQLQuery -Uri $this.BaseURL -OperationName $sOperationName -Query $sQuery -Variables $hVariables -IgnoreSSLError:$this.IgnoreSSLError
                $this.token = $iwr.data.loginOnPremise.token
                $this.WebRequest = $iwr
            }
            $oResult | Add-Member -MemberType ScriptMethod -Name "CallAPI" -Value {
                Param([string]$OperationName,[string]$Query,[hashtable]$Variables)
                $oAPICall = Invoke-GraphQLQuery -Uri $this.BaseURL -IgnoreSSLError:$this.IgnoreSSLError `
                                          -Query $Query -OperationName $OperationName -Variables $Variables -Headers @{token = $this.Token}
                if ($oAPICall.errors) {
                    $this.Reconnect()
                    $oAPICall = Invoke-GraphQLQuery -Uri $this.BaseURL -IgnoreSSLError:$this.IgnoreSSLError `
                                        -Query $Query -OperationName $OperationName -Variables $Variables -Headers @{token = $this.Token}
                }
                return $oAPICall
            }

            $oResult | Add-Member -MemberType ScriptMethod -Name "CallAPIGet" -Value {
                Param([string]$APIEndpoint, [hashtable]$Parameters, [bool]$Verbose = $false)
                if ($this.IgnoreSSLError -and ($PSVersionTable.PSEdition -eq "Desktop")) {
                    Invoke-IgnoreSSL
                }
                $sURL = ConvertTo-URL -URL ("https://" + $this.Server + ":" + $this.Port + "/" + $APIEndpoint) -Arguments $Parameters
                $hHeaders = @{
                    token = $this.Token
                    "x-mgmt-run-as-job" = "off"
                }
                $iwrArgs = @{
                    URI = $sURL
                    Headers = $hHeaders
                    Method = "Get"
                }
                $oAPICall = try {
                    Invoke-WebRequest @iwrArgs
                } catch [System.Net.WebException] {
                    $this.Reconnect()
                    Invoke-WebRequest @iwrArgs
                }
                $oResult = $oAPICall.Content | ConvertFrom-Json
                if ($Verbose) {
                    $hResult = [ordered]@{
                        http = $oAPICall
                        json = $oResult
                    }
                    return $hResult    
                } else {
                    $oResult
                }
            }
            
            
            if ($GlobalVar.IsPresent) {
                $Global:EPSAPI = $oResult
            } else {
                return $oResult
            }
        }
    }
}
