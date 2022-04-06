Function New-Timer
{
    #Requires -module OutSpeech
    <#
      .Synopsis
      Creates a new countdown timer which can show progress and/or issue speech$Speech reports of remaining time.
      .Description
      Creates a new PowerShell Countdown Timer which can show progress using a progress bar and can issue speech$Speech reports of progress according to the Units and Frequency specified.
      Additionally, as the timer counts down, alternative speech$Speech report units and frequency may be specified using the altReport parameter.
      .Parameter Units
      Specify the countdown timer length units.  Valid values are Seconds, Minuts, Hours, or Days.
      .Parameter Length
      Specify the length of the countdown timer.  Default units for length are Minutes.  Otherwise length uses the Units specified with the Units Parameter.
      .Parameter Speech
      Turns on speech reporting of countdown progress according to the specified units and frequency.
      .Parameter ShowProgress
      Shows countdown progress with a progress bar.  The progress bar updates approximately once per second.
      .Parameter Frequency
      Specifies the frequency of speech$Speech reports of countdown progress in Units
      .Parameter altReport
      Allows specification of additional speech$Speech report patterns as a countdown timer progresses.  Accepts an array of hashtable objects which must contain Keys for Units, Frequency, and Countdownpoint (in Units specified in the hashtable)
  #>
    [cmdletbinding()]
    param(
        [parameter()]
        [validateset('Seconds', 'Minutes', 'Hours', 'Days')]
        $Units = 'Minutes'
        ,
        [parameter()]
        $Length
        ,
        [switch]$Speech
        ,
        [switch]$ShowProgress
        ,
        [double]$Frequency = 1
        ,
        [hashtable[]]$AltReport #Units,Frequency,CountdownPoint
        ,
        [int]$Delay
        ,
        [int32]$SpeechVolume #Valid Values 1 through 100
        ,
        [int32]$SpeechRate #Valid Values -10 through 10 (0 is normal, higher is faster)
    )

    switch ($units)
    {
        'Seconds' {$timespan = [timespan]::FromSeconds($length)}
        'Minutes' {$timespan = [timespan]::FromMinutes($length)}
        'Hours' {$timespan = [timespan]::FromHours($length)}
        'Days' {$timespan = [timespan]::FromDays($length)}
    }

    if ($Speech)
    {
        if ($null -eq $script:TimerSpeechConfigured)
        {
            Write-Verbose -Message 'Configuring Timer Speech'

            $EnableSpeechParams = @{
                ConfigurationName = 'Timer'
                Volume            = 70
                Rate              = 0
            }
            Enable-SpeechConfiguration @EnableSpeechParams

            $EnableSpeechParams = @{
                ConfigurationName = 'FastTimer'
                Volume            = 70
                Rate              = 6
            }
            Enable-SpeechConfiguration @EnableSpeechParams

            $Script:TimerSpeechConfigured = $true

        }

        $outSpeechParams = @{
            ConfigurationName = 'Timer'
        }
    }

    if ($altReport.Count -ge 1)
    {
        $vrts = @(
            foreach ($vr in $altReport)
            {
                $vrt = [PSCustomObject]@{
                    seconds        = $null
                    frequency      = $null
                    units          = $null
                    countdownpoint = $null
                }
                switch ($vr.Units)
                {
                    'Seconds'
                    {
                        #convert frequency units to seconds
                        $vrt.seconds = $vr.frequency
                        $vrt.frequency = $vr.frequency
                        $vrt.units = $vr.Units
                        $vrt.countdownpoint = $vr.countdownpoint
                    }
                    'Minutes'
                    {
                        #convert frequency units to seconds
                        $vrt.seconds = $vr.frequency * 60
                        $vrt.frequency = $vrt.seconds * $vr.frequency
                        $vrt.units = $vr.units
                        $vrt.countdownpoint = $vr.countdownpoint * 60
                    }
                    'Hours'
                    {
                        #convert frequency units to seconds
                        $vrt.seconds = $vr.frequency * 60 * 60
                        $vrt.frequency = $vrt.seconds * $vr.frequency
                        $vrt.units = $vr.units
                        $vrt.countdownpoint = $vr.countdownpoint * 60 * 60
                    }
                    'Days'
                    {
                        #convert frequency units to seconds
                        $vrt.seconds = $vr.frequency * 24 * 60 * 60
                        $vrt.frequency = $vrt.seconds * $vr.frequency
                        $vrt.units = $vr.units
                        $vrt.countdownpoint = $vr.countdownpoint * 60 * 60 * 24
                    }
                }
                $vrt
            }
        )
        $vrts = @($vrts | Sort-Object -Property countdownpoint -Descending)
        Write-Verbose -Message "Alt Voice Reports: $($vrts | ConvertTo-Json)"
    }

    if ($delay) {New-Timer -units Seconds -length $delay -speech -showprogress -Frequency 5}

    if ($showprogress)
    {
        $writeprogressparams = @{
            Activity         = "Starting Timer for $length $units"
            Status           = 'Running'
            PercentComplete  = 0
            CurrentOperation = 'Starting'
            SecondsRemaining = $timespan.TotalSeconds
            Id               = 2147483646
        }
        Write-Progress @writeprogressparams
    }

    $startTime = [datetime]::Now
    $endTime = $startTime.AddTicks($timespan.Ticks)

    do
    {
        if ($nextsecond)
        {
            $nextsecond = $nextsecond.AddSeconds(1)
        }
        else
        {
            $nextsecond = $starttime.AddSeconds(1)
        }

        $currentTime = [datetime]::Now

        [timespan]$remaining = $endTime - $currentTime

        $secondsRemaining = if ($remaining.TotalSeconds -gt 0) {$remaining.TotalSeconds.toUint64($null)} else {0}

        if ($showprogress)
        {
            $writeprogressparams.CurrentOperation = 'Countdown'
            $writeprogressparams.SecondsRemaining = $secondsremaining
            $writeprogressparams.PercentComplete = ($secondsremaining / $timespan.TotalSeconds) * 100
            $writeprogressparams.Activity = "Running Timer for $length $units"
            Write-Progress @writeprogressparams
        }

        switch ($Units)
        {
            'Seconds'
            {
                $seconds = $Frequency
                if ($Speech -and ($secondsremaining % $seconds -eq 0))
                {
                    if ($Frequency -lt 4)
                    {
                        Out-Speech -InputObject "$secondsremaining" @outSpeechParams -ConfigurationName 'FastTimer'
                    }
                    else
                    {
                        Out-Speech -InputObject "$secondsremaining seconds remaining" @outSpeechParams
                    }
                }
            }
            'Minutes'
            {
                $seconds = $frequency * 60
                if ($Speech -and ($secondsremaining % $seconds -eq 0))
                {
                    $minutesremaining = $remaining.TotalMinutes.tostring('#.##')
                    if ($minutesremaining -ge 1)
                    {
                        Out-Speech -InputObject "$minutesremaining minutes remaining" @outSpeechParams
                    }
                    else
                    {
                        if ($secondsremaining -ge 1)
                        {
                            Out-Speech -InputObject "$secondsremaining seconds remaining" @outSpeechParams
                        }
                    }
                }
            }
            'Hours'
            {
                $seconds = $frequency * 60 * 60
                if ($Speech -and ($secondsremaining % $seconds -eq 0))
                {
                    $hoursremaining = $remaining.TotalHours.tostring('#.##')
                    if ($hoursremaining -ge 1)
                    {
                        Out-Speech -InputObject "$hoursremaining hours remaining" @outSpeechParams
                    }
                    else
                    {
                        $minutesremaining = $remaining.TotalMinutes.tostring('#.##')
                        if ($minutesremaining -ge 1)
                        {
                            Out-Speech -InputObject "$minutesremaining minutes remaining" @outSpeechParams
                        }
                        else
                        {
                            if ($secondsremaining -ge 1)
                            {
                                Out-Speech -InputObject "$secondsremaining seconds remaining" @outSpeechParams
                            }
                        }
                    }
                }
            }
            'Days'
            {
                $seconds = $frequency * 24 * 60 * 60
                if ($Speech -and ($secondsremaining % $seconds -eq 0))
                {
                    $daysremaining = $remaining.TotalDays.tostring('#.##')
                    if ($daysremaining -ge 1)
                    {
                        Out-Speech -InputObject "$daysremaining days remaining" @outSpeechParams
                    }
                    else
                    {
                        $hoursremaining = $remaining.TotalHours.tostring('#.##')
                        if ($hoursremaining -ge 1)
                        {
                            Out-Speech -InputObject "$hoursremaining hours remaining" @outSpeechParams
                        }
                        else
                        {
                            $minutesremaining = $remaining.TotalMinutes.tostring('#.##')
                            if ($minutesremaining -ge 1)
                            {
                                Out-Speech -InputObject "$minutesremaining minutes remaining" @outSpeechParams
                            }
                            else
                            {
                                if ($secondsremaining -ge 1)
                                {
                                    Out-Speech -InputObject "$secondsremaining seconds remaining" @outSpeechParams
                                }
                            }
                        }

                    }
                }
            }
        }

        $currentvrt = $vrts.where( {$_.countdownpoint -ge $($secondsremaining - 1)})[0]


        if ($currentvrt)
        {
            $Frequency = $currentvrt.frequency
            $Units = $currentvrt.units
            $vrts = @($vrts.where( {$_.countdownpoint -ne $currentvrt.countdownpoint}))
            Write-Verbose -Message "Current Voice Report: $($currentvrt | ConvertTo-Json)"
        }

        Start-Sleep -Milliseconds $($nextsecond - ([datetime]::Now)).TotalMilliseconds

    }

    until ($secondsremaining -eq 0)
    if ($showprogress)
    {
        $writeprogressparams.completed = $true
        $writeprogressparams.Activity = "Completed Timer for $length $units"
        Write-Progress @writeprogressparams
    }

}
