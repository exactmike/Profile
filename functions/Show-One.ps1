    Function Show-One {
        
    [cmdletbinding()]
    param
    (
        [parameter(ValueFromPipeline)]
        [psobject[]]$PSObject
        ,
        [switch]$ClearHost
    )
    process
    {
        foreach ($o in $PSObject)
        {
            if ($true -eq $quit)
            {
                break
            }
            if ($true -eq $Clearhost) {Clear-Host}
            $o | Format-List -Property * -Force
            if ($(Read-Host -Prompt "Show next object (any key), or quit (q)?") -eq 'q')
            {
                $quit = $true
            }
        }
    }

    }
