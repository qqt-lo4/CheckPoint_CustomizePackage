class tracDefaultsSettings {
    [hashtable]$options
    [System.Collections.ArrayList]$optionsorder
    hidden [string]$tracDefaultsPath

    tracDefaultsSettings([string]$tracDefaultsPath) {
        if (($null -eq $tracDefaultsPath) `
            -or ($tracDefaultsPath -eq "") `
            -or (-not (Test-Path -Path $tracDefaultsPath))) {
            throw [System.IO.FileNotFoundException] "Trac.defaults file does not exists"
        }
        $this.tracDefaultsPath = $tracDefaultsPath
        $this.options = @{}
        $this.optionsorder = New-Object System.Collections.ArrayList
        Get-Content -Path $tracDefaultsPath | ForEach-Object {
                                                  if ($_.Trim() -ne "") {
                                                      $setting = [tracDefaultsSetting]::newFromLine($_)
                                                      $this.options.Add($setting.name, $setting)
                                                      $this.optionsorder.Add($setting.name)
                                                  }
                                              }
    }

    [boolean]HasOption([string]$optionname) {
        return $this.options.ContainsKey($optionname)
    }

    [boolean]SetOptionValue([string]$optionname, [string]$value) {
        if ($this.HasOption($optionname)) {
            $this.options[$optionname].value = $value
            return $true
        } else {
            return $false
        }
    }

    [string]GetOptionValue([string]$optionname) {
        if ($this.HasOption($optionname)) {
            return $this.options[$optionname].value
        } else {
            return $null
        }
    }

    [string]ToString() {
        $result = ""
        for ($i=0; $i -lt $this.optionsorder.Count; $i++) {
            [tracDefaultsSetting]$setting = $this.options[$this.optionsorder[$i]] 
            $result += $setting.ToString() 
            if ($i -lt $this.optionsorder.Count - 1) {
                $result += "`n"
            }
        }
        return $result
    }

    [string]Backup() {
        $folder = Split-Path -Path $this.tracDefaultsPath -Parent
        $filename = Split-Path -Path $this.tracDefaultsPath -Leaf
        $newfile = $folder + "\" + $filename.Replace(".", "_") + ".backup_" + $(Get-Date -Format "yyyyMMdd_HHmmss")

        Copy-Item -Path $this.tracDefaultsPath -Destination $newfile
        if (Test-Path -Path $newfile) {
            return $newfile
        } else {
            return ""
        }
    }

    [void]Save() {
        $result = $this.ToString()
        $this.Backup()
        [IO.File]::WriteAllText($this.tracDefaultsPath, $result)
    }
}