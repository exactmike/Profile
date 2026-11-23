    Function Start-WindowsSecurity {
    if (-not $IsWindows) {
        throw [System.PlatformNotSupportedException]::new('Start-WindowsSecurity requires Windows.')
    }
        
    #useful in RDP sessions especially on Windows 2012
    (New-Object -ComObject Shell.Application).WindowsSecurity()

    }
