    Function Start-WindowsSecurity {
        
    #useful in RDP sessions especially on Windows 2012
    (New-Object -ComObject Shell.Application).WindowsSecurity()

    }
