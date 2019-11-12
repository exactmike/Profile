    Function Get-GitSourcedModule {
        
    [cmdletbinding()]
    param(
        $path = $(pwd).path
        ,
        [switch]$Recurse
    )
    Push-Location
    Set-Location -Path $path
    if ($true -eq $Recurse)
    {
        $ChildDirectories = Get-ChildItem -Directory
        foreach ($cd in $ChildDirectories)
        {
            Set-Location -LiteralPath $cd.FullName
            $GitStatus = Get-GitStatus
            if ($GitStatus -ne $null)
            {
                $cd.FullName
            }
        }
    }
    else
    {
        $GitStatus = Get-GitStatus
        if ($GitStatus -ne $null)
        {
            $(pwd).path
        }
    }
    Pop-Location

    }
