function New-CorrelationVectorObject {
    <#
    .SYNOPSIS
    Creates a new CorrelationVector object
    
    .DESCRIPTION
        Creates a PSCustomObject-based CorrelationVector with all necessary properties and methods.
        The object includes GetValue, Increment, Extend, CanIncrement, and CanExtend methods,
        following the Microsoft Correlation Vector v2 specification.

    .OUTPUTS
        PSCustomObject. A CorrelationVector object with BaseVector, CurrentVector properties
        and GetValue(), Increment(), Extend() methods.

    .EXAMPLE
        $cv = New-CorrelationVectorObject
        $cv.GetValue()    # Returns "ABCDefgh12345678.1"
        $cv.Increment()   # Returns "ABCDefgh12345678.2"
        $cv.Extend()      # Returns "ABCDefgh12345678.2.1"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    
    $base64CharSet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    $id0Length = 16
    $maxLength = 63
    
    # Generate seed
    $baseVector = ""
    $random = New-Object System.Random
    for ($i = 0; $i -lt $id0Length; $i++) {
        $baseVector += $base64CharSet[$random.Next($base64CharSet.Length)]
    }
    
    $cv = [PSCustomObject]@{
        BaseVector = $baseVector
        CurrentVector = 1
        Base64CharSet = $base64CharSet
        Id0Length = $id0Length
        MaxLength = $maxLength
        IsInitialized = $true
    }
    
    # Add GetValue method
    $cv | Add-Member -MemberType ScriptMethod -Name GetValue -Value {
        if (-not $this.IsInitialized) {
            return $null
        }
        return "$($this.BaseVector).$($this.CurrentVector)"
    }
    
    # Add CanIncrement method
    $cv | Add-Member -MemberType ScriptMethod -Name CanIncrement -Value {
        param([int]$newVector)
        
        if ($newVector - 1 -eq [int]::MaxValue) {
            return $false
        }
        
        $vectorSize = [Math]::Floor([Math]::Log10($newVector) + 1)
        
        if ($this.BaseVector.Length + $vectorSize + 1 -gt $this.MaxLength) {
            return $false
        }
        
        return $true
    }
    
    # Add Increment method
    $cv | Add-Member -MemberType ScriptMethod -Name Increment -Value {
        if (-not $this.IsInitialized) {
            return $null
        }
        
        $newVector = $this.CurrentVector + 1
        
        if ($this.CanIncrement($newVector)) {
            $this.CurrentVector = $newVector
        }
        
        return $this.GetValue()
    }
    
    # Add CanExtend method
    $cv | Add-Member -MemberType ScriptMethod -Name CanExtend -Value {
        $vectorSize = [Math]::Floor([Math]::Log10($this.CurrentVector) + 1)
        
        if ($this.BaseVector.Length + 1 + $vectorSize + 1 + 1 -gt $this.MaxLength) {
            return $false
        }
        
        return $true
    }
    
    # Add Extend method
    $cv | Add-Member -MemberType ScriptMethod -Name Extend -Value {
        if (-not $this.IsInitialized) {
            return $null
        }
        
        if ($this.CanExtend()) {
            $this.BaseVector = $this.GetValue()
            $this.CurrentVector = 1
        }
        
        return $this.GetValue()
    }
    
    return $cv
}
