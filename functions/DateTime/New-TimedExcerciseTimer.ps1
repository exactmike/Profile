    Function New-TimedExcerciseTimer {
        
    New-Timer -units Minutes -length 3 -voice -showprogress -Frequency .25 -altReport @{Units = 'Seconds'; Frequency = 1; Countdownpoint = 10} -delay 5

    }
