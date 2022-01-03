Function New-PomoTimer
{
    [cmdletbinding()]
    param(
        $PomoMinutes = 25
        ,
        $BreakMinutes = 15
    )


    $TotalPomos = 0
    $SinceBreak = 0
    $TotalBreaks = 0
    $SinceBreak = 0

    $userChoiceParams = @{
        Title    = 'Select Next Action'
        Choices  = @('Pomo','Break','Quit')
        Message  = ''
        Numbered = $true
    }
    $userChoice = 'Pomo'

    Do
    {
        switch ($userchoice)
        {
            'Pomo'
            {
                $Length = $PomoMinutes
                $TotalPomos++
                $SinceBreak++
            }
            'Break'
            {
                $Length = $BreakMinutes
                $TotalBreaks++
                $SinceBreak=0
            }
        }
        $newTimerParams = @{
            units        = 'Minutes'
            length       = $Length
            showprogress = $true
            speech       = $true
            Frequency    = 5
            delay        = 10
            AltReport    = @(
                @{
                    Units          = 'Minutes'
                    Frequency      = 1
                    Countdownpoint = 3
                }
                @{
                    Units          = 'Seconds'
                    Frequency      = 5
                    Countdownpoint = 60
                }
                @{
                    Units          = 'Seconds'
                    Frequency      = 1
                    Countdownpoint = 10
                }
            )
        }

        New-Timer @newTimerParams

        $oldChoice = $userChoice
        $userChoice = $null

        Do
        {
            Out-Speech -InputObject "$oldChoice has ended.  Select the next activity." -ConfigurationName 'Timer'
            $userChoiceParams.Message = "Total Pomo: $TotalPomos, Pomo Since Last Break: $SinceBreak, Total Breaks: $TotalBreaks"
            $UserChoice = $userChoiceParams.Choices[$(Read-PromptForChoice @userChoiceParams)]
        }
        Until ( $null -ne $userChoice )

    }
    until (
        $UserChoice -eq 'quit'
    )

}
