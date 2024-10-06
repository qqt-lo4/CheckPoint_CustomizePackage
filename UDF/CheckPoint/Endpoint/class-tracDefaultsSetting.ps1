class tracDefaultsSetting {
    [string]$name
    [string]$type
    [string]$value
    [string]$beforelastvalue
    [string]$lastvalue
    [string]$space1
    [string]$space2
    [string]$space3
    [string]$space4
    [string]$space5

    tracDefaultsSetting([string]$name, [string]$type, [string]$value, [string]$beforelastvalue, [string]$lastvalue, `
                        [string]$space1, [string]$space2, [string]$space3, [string]$space4, [string]$space5) {
        $this.name = $name
        $this.type = $type
        $this.value = $value
        $this.beforelastvalue = $beforelastvalue
        $this.lastvalue = $lastvalue
        $this.space1 = $space1
        $this.space2 = $space2
        $this.space3 = $space3
        $this.space4 = $space4
        $this.space5 = $space5
    }

    [string]ToString() {
        if ((-not ($this.value.StartsWith("`""))) -and (($this.value -eq "") -or ($this.value.Contains(" ")))) {
            $_value = "`"" + $this.value + "`""
        } else {
            $_value = $this.value
        }
        return $this.name + $this.space1 `
             + $this.type + $this.space2 `
             + $_value + $this.space3 `
             + $this.beforelastvalue + $this.space4 `
             + $this.lastvalue + $this.space5
    }

    static [tracDefaultsSetting] newFromLine([string]$line) {
        if ($line -match "^([^ \t]+)((\t| )+)([^ \t]+)((\t| )+)([^\t]+)((\t| )+)([^ \t]+)((\t| )+)([^ \t]+)((\t| )*)$") {
            return New-Object tracDefaultsSetting($Matches.1, $Matches.4, $Matches.7, $Matches.10, $Matches.13, `
                                                  $Matches.2, $Matches.5, $Matches.8, $Matches.11, $Matches.14)
        } else {
            return $null
        }
    }
}