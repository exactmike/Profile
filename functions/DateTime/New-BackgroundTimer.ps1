    Function New-BackgroundTimer {
        
    [cmdletbinding()]
    param(
        [string]$name
        ,
        [parameter()]
        [validateset('Seconds', 'Minutes', 'Hours', 'Days')]
        $units = 'Minutes'
        ,
        [parameter()]
        $length
        ,
        [switch]$voice
        ,
        [switch]$showprogress
        ,
        [double]$Frequency = 1
        ,
        [hashtable[]]$altReport #Units,Frequency,CountdownPoint
    )
    $BackgroundTimerParams = @{
        JobFunctions = @(
            'New-Timer'
            'Convert-HashTableToObject'
        )
        Name         = $name
        arguments    = @($units, $length, $voice, $showprogress, $Frequency, $altReport)
        script       = [string] {
            $newtimerparams = @{
                Units        = $args[0]
                Length       = $args[1]
                Voice        = $args[2]
                ShowProgress = $args[3]
                Frequency    = $args[4]
                AltReport    = $args[5]
            }
            New-Timer @newtimerparams
        }
    }

    Start-ComplexJob @BackgroundTimerParams


    }
