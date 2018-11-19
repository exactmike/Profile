function Get-ISEKeyboardShortcuts
{
    #http://www.powershellmagazine.com/2013/01/29/the-complete-list-of-powershell-ise-3-0-keyboard-shortcuts/
    $gps = $psISE.GetType().Assembly
    $rm = New-Object System.Resources.ResourceManager GuiStrings, $gps
    $rs = $rm.GetResourceSet((Get-Culture), $true, $true)
    $rs | where Name -match 'Shortcut\d?$|^F\d+Keyboard'
}
function Set-HostColor
{
    param(
        [Switch]$Light <#= $(
        ## Based on whether we're elevated or not, switch between DARK and LIGHT versions of Solarized:
        $([System.Environment]::OSVersion.Version.Major -gt 5) -and ( # Vista or higher and ...
        new-object Security.Principal.WindowsPrincipal (
        # current user is an administrator (Note: ROLE, not GROUP)
        [Security.Principal.WindowsIdentity]::GetCurrent())
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        )
    #>
    )

    # SOLARIZED HEX        16/8 TERMCOL  XTERM/HEX   L*A*B      RGB         HSB
    # --------- -------    ---- -------  ----------- ---------- ----------- -----------
    $base03 = "#002b36" #  8/4 brblack  234 #1c1c1c 15 -12 -12   0  43  54 193 100  21
    $base02 = "#073642" #  0/4 black    235 #262626 20 -12 -12   7  54  66 192  90  26
    $base01 = "#586e75" # 10/7 brgreen  240 #585858 45 -07 -07  88 110 117 194  25  46
    $base00 = "#657b83" # 11/7 bryellow 241 #626262 50 -07 -07 101 123 131 195  23  51
    $base0 = "#839496" # 12/6 brblue   244 #808080 60 -06 -03 131 148 150 186  13  59
    $base1 = "#93a1a1" # 14/4 brcyan   245 #8a8a8a 65 -05 -02 147 161 161 180   9  63
    $base2 = "#eee8d5" #  7/7 white    254 #e4e4e4 92 -00  10 238 232 213  44  11  93
    $base3 = "#fdf6e3" # 15/7 brwhite  230 #ffffd7 97  00  10 253 246 227  44  10  99
    $yellow = "#b58900" #  3/3 yellow   136 #af8700 60  10  65 181 137   0  45 100  71
    $orange = "#cb4b16" #  9/3 brred    166 #d75f00 50  50  55 203  75  22  18  89  80
    $red = "#dc322f" #  1/1 red      160 #d70000 50  65  45 220  50  47   1  79  86
    $magenta = "#d33682" #  5/5 magenta  125 #af005f 50  65 -05 211  54 130 331  74  83
    $violet = "#6c71c4" # 13/5 brmagenta 61 #5f5faf 50  15 -45 108 113 196 237  45  77
    $blue = "#268bd2" #  4/4 blue      33 #0087ff 55 -10 -45  38 139 210 205  82  82
    $cyan = "#2aa198" #  6/6 cyan      37 #00afaf 60 -35 -05  42 161 152 175  74  63
    $green = "#859900" #  2/2 green     64 #5f8700 60 -20  65 133 153   0  68 100  60
    ## BEGIN SOLARIZING ----------------------------------------------
    if ($Host.Name -eq "Windows PowerShell ISE Host" -and $psISE)
    {
        $psISE.Options.FontName = 'Consolas'

        $psISE.Options.TokenColors['Command'] = $yellow
        $psISE.Options.TokenColors['Position'] = $red
        $psISE.Options.TokenColors['GroupEnd'] = $red
        $psISE.Options.TokenColors['GroupStart'] = $red
        $psISE.Options.TokenColors['NewLine'] = '#FFFFFFFF' # not a printable token
        $psISE.Options.TokenColors['String'] = $cyan
        $psISE.Options.TokenColors['Type'] = $orange
        $psISE.Options.TokenColors['Variable'] = $blue
        $psISE.Options.TokenColors['CommandParameter'] = $green
        $psISE.Options.TokenColors['CommandArgument'] = $violet
        $psISE.Options.TokenColors['Number'] = $red

        if ($Light)
        {
            #$psISE.Options.OutputPaneBackgroundColor = $base3
            $psISE.Options.ConsolePaneBackgroundColor = $base3
            #$psISE.Options.OutputPaneTextBackgroundColor = $base3
            $psISE.Options.ConsolePaneTextBackgroundColor = $base3
            #$psISE.Options.OutputPaneForegroundColor = $base00
            $psISE.Options.ConsolePaneForegroundColor = $base00
            #$psISE.Options.CommandPaneBackgroundColor = $base3
            $psISE.Options.ScriptPaneBackgroundColor = $base3
            $psISE.Options.TokenColors['Unknown'] = $base00
            $psISE.Options.TokenColors['Member'] = $base00
            $psISE.Options.TokenColors['LineContinuation'] = $base01
            $psISE.Options.TokenColors['StatementSeparator'] = $base01
            $psISE.Options.TokenColors['Comment'] = $base1
            $psISE.Options.TokenColors['Keyword'] = $base01
            $psISE.Options.TokenColors['Attribute'] = $base00
        }
        else
        {
            $psISE.Options.ConsolePaneBackgroundColor = $base03
            $psISE.Options.ConsolePaneTextBackgroundColor = $base03
            $psISE.Options.ConsolePaneForegroundColor = $base0
            #$psISE.Options.CommandPaneBackgroundColor = $base03
            $psISE.Options.ScriptPaneBackgroundColor = $base03
            $psISE.Options.TokenColors['Unknown'] = $base0
            $psISE.Options.TokenColors['Member'] = $base0
            $psISE.Options.TokenColors['LineContinuation'] = $base1
            $psISE.Options.TokenColors['StatementSeparator'] = $base1
            $psISE.Options.TokenColors['Comment'] = $base01
            $psISE.Options.TokenColors['Keyword'] = $base1
            $psISE.Options.TokenColors['Attribute'] = $base0
        }

        $Host.PrivateData.VerboseForegroundColor = $PSISE.Options.VerboseForegroundColor = $blue
        $Host.PrivateData.DebugForegroundColor = $PSISE.Options.DebugForegroundColor = $green
        $Host.PrivateData.WarningForegroundColor = $PSISE.Options.WarningForegroundColor = $orange
        $Host.PrivateData.ErrorForegroundColor = $PSISE.Options.ErrorForegroundColor = $red
        $PSISE.Options.ConsolePaneForegroundColor = $base0
        $PSISE.Options.ScriptPaneForegroundColor = $base0

    }
    elseif ($Host.Name -eq "ConsoleHost")
    {
        ## In the PowerShell Console, we can only use console colors, so we have to pick them by name.
        ## For it to look right, you have to have run PowerShell from a shortcut you've modified with Install-Solarized
        if ($Light)
        {
            ## Set the WindowTitlePrefix for my prompt function, so it won't need to test for IsInRole Administrator again.
            # $Host.UI.RawUI.WindowTitle = $global:WindowTitlePrefix = "PoSh ${Env:UserName}@${Env:UserDomain} (ADMIN)"
            $Host.UI.RawUI.BackgroundColor = "White"
            $Host.PrivateData.ProgressBackgroundColor = "Black"
            $Host.UI.RawUI.ForegroundColor = "DarkCyan"
        }
        else
        {
            # $Host.UI.RawUI.WindowTitle = $global:WindowTitlePrefix = "PoSh ${Env:UserName}@${Env:UserDomain}"
            $Host.PrivateData.ProgressBackgroundColor = "White"
            $Host.UI.RawUI.BackgroundColor = "Black"
            $Host.UI.RawUI.ForegroundColor = "DarkRed"
        }

        $Host.PrivateData.ErrorForegroundColor = "Red"
        $Host.PrivateData.WarningForegroundColor = "DarkYellow"
        $Host.PrivateData.DebugForegroundColor = "Green"
        $Host.PrivateData.VerboseForegroundColor = "Blue"
        $Host.PrivateData.ProgressForegroundColor = "Magenta"

        $Host.PrivateData.ErrorBackgroundColor =
        $Host.PrivateData.WarningBackgroundColor =
        $Host.PrivateData.DebugBackgroundColor =
        $Host.PrivateData.VerboseBackgroundColor =
        $Host.UI.RawUI.BackgroundColor
    }
}
function New-TimedExcerciseTimer
{
    New-Timer -units Minutes -length 3 -voice -showprogress -Frequency .25 -altReport @{Units = 'Seconds'; Frequency = 1; Countdownpoint = 10} -delay 5
}
function New-Timer
{
    <#
      .Synopsis
      Creates a new countdown timer which can show progress and/or issue voice reports of remaining time.
      .Description
      Creates a new PowerShell Countdown Timer which can show progress using a progress bar and can issue voice reports of progress according to the Units and Frequency specified.
      Additionally, as the timer counts down, alternative voice report units and frequency may be specified using the altReport parameter.
      .Parameter Units
      Specify the countdown timer length units.  Valid values are Seconds, Minuts, Hours, or Days.
      .Parameter Length
      Specify the length of the countdown timer.  Default units for length are Minutes.  Otherwise length uses the Units specified with the Units Parameter.
      .Parameter Voice
      Turns on voice reporting of countdown progress according to the specified units and frequency.
      .Parameter ShowProgress
      Shows countdown progress with a progress bar.  The progress bar updates approximately once per second.
      .Parameter Frequency
      Specifies the frequency of voice reports of countdown progress in Units
      .Parameter altReport
      Allows specification of additional voice report patterns as a countdown timer progresses.  Accepts an array of hashtable objects which must contain Keys for Units, Frequency, and Countdownpoint (in Units specified in the hashtable)
  #>
    [cmdletbinding()]
    param(
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
        ,
        [int]$delay
    )

    switch ($units)
    {
        'Seconds' {$timespan = [timespan]::FromSeconds($length)}
        'Minutes' {$timespan = [timespan]::FromMinutes($length)}
        'Hours' {$timespan = [timespan]::FromHours($length)}
        'Days' {$timespan = [timespan]::FromDays($length)}
    }

    if ($voice)
    {
        Add-Type -AssemblyName System.speech
        $speak = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer
        $speak.Rate = 3
        $speak.Volume = 100
    }

    if ($altReport.Count -ge 1)
    {
        $vrts = @()
        foreach ($vr in $altReport)
        {
            $vrt = @{}
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
            $ovrt = $vrt | Convert-HashTableToObject
            $vrts += $ovrt
        }
        $vrts = @($vrts | sort-object -Property countdownpoint -Descending)
    }
    if ($delay) {New-Timer -units Seconds -length $delay -voice -showprogress -Frequency 1}
    $starttime = Get-Date
    $endtime = $starttime.AddTicks($timespan.Ticks)

    if ($showprogress)
    {
        $writeprogressparams = @{
            Activity         = "Starting Timer for $length $units"
            Status           = 'Running'
            PercentComplete  = 0
            CurrentOperation = 'Starting'
            SecondsRemaining = $timespan.TotalSeconds
        }
        Write-Progress @writeprogressparams
    }

    do
    {
        if ($nextsecond)
        {
            $nextsecond = $nextsecond.AddSeconds(1)
        }
        else {$nextsecond = $starttime.AddSeconds(1)}
        $currenttime = Get-Date
        [timespan]$remaining = $endtime - $currenttime
        $secondsremaining = if ($remaining.TotalSeconds -gt 0) {$remaining.TotalSeconds.toUint64($null)} else {0}
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
                if ($voice -and ($secondsremaining % $seconds -eq 0))
                {
                    if ($Frequency -lt 3)
                    {
                        $speak.Rate = 5
                        $speak.SpeakAsync("$secondsremaining")| Out-Null
                    }
                    else
                    {
                        $speak.SpeakAsync("$secondsremaining seconds remaining") | Out-Null
                    }
                }
            }
            'Minutes'
            {
                $seconds = $frequency * 60
                if ($voice -and ($secondsremaining % $seconds -eq 0))
                {
                    $minutesremaining = $remaining.TotalMinutes.tostring("#.##")
                    if ($minutesremaining -ge 1)
                    {
                        $speak.SpeakAsync("$minutesremaining minutes remaining")| Out-Null
                    }
                    else
                    {
                        if ($secondsremaining -ge 1)
                        {
                            $speak.SpeakAsync("$secondsremaining seconds remaining")| Out-Null
                        }
                    }
                }
            }
            'Hours'
            {
                $seconds = $frequency * 60 * 60
                if ($voice -and ($secondsremaining % $seconds -eq 0))
                {
                    $hoursremaining = $remaining.TotalHours.tostring("#.##")
                    if ($hoursremaining -ge 1)
                    {
                        $speak.SpeakAsync("$hoursremaining hours remaining")| Out-Null
                    }
                    else
                    {
                        $minutesremaining = $remaining.TotalMinutes.tostring("#.##")
                        if ($minutesremaining -ge 1)
                        {
                            $speak.SpeakAsync("$minutesremaining minutes remaining")| Out-Null
                        }
                        else
                        {
                            if ($secondsremaining -ge 1)
                            {
                                $speak.SpeakAsync("$secondsremaining seconds remaining")| Out-Null
                            }
                        }
                    }
                }
            }
            'Days'
            {
                $seconds = $frequency * 24 * 60 * 60
                if ($voice -and ($secondsremaining % $seconds -eq 0))
                {
                    $daysremaining = $remaining.TotalDays.tostring("#.##")
                    if ($daysremaining -ge 1)
                    {
                        $speak.SpeakAsync("$daysremaining days remaining")| Out-Null
                    }
                    else
                    {
                        $hoursremaining = $remaining.TotalHours.tostring("#.##")
                        if ($hoursremaining -ge 1)
                        {
                            $speak.SpeakAsync("$hoursremaining hours remaining")| Out-Null
                        }
                        else
                        {
                            $minutesremaining = $remaining.TotalMinutes.tostring("#.##")
                            if ($minutesremaining -ge 1)
                            {
                                $speak.SpeakAsync("$minutesremaining minutes remaining")| Out-Null
                            }
                            else
                            {
                                if ($secondsremaining -ge 1)
                                {
                                    $speak.SpeakAsync("$secondsremaining seconds remaining")| Out-Null
                                }
                            }
                        }

                    }
                }
            }
        }
        $currentvrt = $vrts | ? countdownpoint -ge $($secondsremaining - 1) | Select-Object -First 1
        if ($currentvrt)
        {
            $Frequency = $currentvrt.frequency
            $Units = $currentvrt.units
            $vrts = $vrts | ? countdownpoint -ne $currentvrt.countdownpoint
        }
        Start-Sleep -Milliseconds $($nextsecond - (get-date)).TotalMilliseconds
    }
    until ($secondsremaining -eq 0)
    if ($showprogress)
    {
        $writeprogressparams.completed = $true
        $writeprogressparams.Activity = "Completed Timer for $length $units"
        Write-Progress @writeprogressparams
    }
}
function New-BackgroundTimer
{
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

function Get-UpTime
{
    #############################################################################
    # Get-Uptime.ps1
    # This script will report uptime of given computer since last reboot.
    #
    # Pre-Requisites: Requires PowerShell 2.0 and WMI access to target computers (admin access).
    #
    # Usage syntax:
    # For local computer where script is being run: .\Get-Uptime.ps1.
    # For list of remote computers: .\Get-Uptime.ps1 -ComputerList "c:\temp\computerlist.txt"
    #
    # Usage Examples:
    #
    # .\Get-Uptime.ps1 -Computer ComputerName
    # .\Get-Uptime.ps1 -ComputerList "c:\temp\computerlist.txt" | Export-Csv uptime-report.csv -NoTypeInformation
    #
    # Last Modified: 3/20/2012
    #
    # Created by
    # Bhargav Shukla
    # http://blogs.technet.com/bshukla
    # http://www.bhargavs.com
    #
    # DISCLAIMER
    # ==========
    # THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
    # RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
    #############################################################################
    #Requires -Version 2.0

    param
    (
        [Parameter(Position = 0, ValuefromPipeline = $true)][string][alias("cn")]$computer,
        [Parameter(Position = 1, ValuefromPipeline = $false)][string]$computerlist
    )

    If (-not ($computer -or $computerlist))
    {
        $computers = $Env:COMPUTERNAME
    }

    If ($computer)
    {
        $computers = $computer
    }

    If ($computerlist)
    {
        $computers = Get-Content $computerlist
    }

    foreach ($computer in $computers)
    {
        $Computerobj = "" | select ComputerName, Uptime, LastReboot
        $wmi = Get-WmiObject -ComputerName $computer -Query "SELECT LastBootUpTime FROM Win32_OperatingSystem"
        $now = Get-Date
        $boottime = $wmi.ConvertToDateTime($wmi.LastBootUpTime)
        $uptime = $now - $boottime
        $d = $uptime.days
        $h = $uptime.hours
        $m = $uptime.Minutes
        $s = $uptime.Seconds
        $Computerobj.ComputerName = $computer
        $Computerobj.Uptime = "$d Days $h Hours $m Min $s Sec"
        $Computerobj.LastReboot = $boottime
        $Computerobj
    }
}
function Get-UniqueIPsFromTextFiles
{
    # Get-UniqueIPsFromLogs
    # Mike Campbell, mike@exactsolutions.biz
    # 2011-09-12
    # version .1
    ############################################################################################
    # Lists Unique IP Addresses from a set of text based log files
    #
    # Regular Expressions to match IP addresses and description below borrowed from:
    #
    # http://www.regular-expressions.info/examples.html
    #
    # Matching an IP address is another good example of a trade-off between regex complexity
    # and exactness.
    # \b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b
    # will match any IP address just fine,
    # but will also match 999.999.999.999 as if it were a valid IP address.
    # Whether this is a problem depends on the files or data you intend to apply the regex to.
    # To restrict all 4 numbers in the IP address to 0..255, you can use this complex beast:
    # \b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b
    # (everything on a single line).
    # The long regex stores each of the 4 numbers of the IP address into a capturing group.
    # You can use these groups to further process the IP number.
    # If you don't need access to the individual numbers,
    # you can shorten the regex with a quantifier to:
    # \b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b
    # Similarly, you can shorten the quick regex to
    # \b(?:\d{1,3}\.){3}\d{1,3}\b
    #
    # Regex.Matches Method Learned about from here: http://halr9000.com/article/526
    #
    # Auto-Help:
    <#
      PowerShell comes with great support for regular expressions but the -match operator can only find the first occurrence of a pattern. To find all occurrences, you can use the .NET RegEx type. Here is a sample::
      $text = 'multiple emails like tobias.weltner@email.de and tobias@powershell.de in a string'
      $emailpattern = '(?i)\b([A-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z]{2,4})\b'

      $emails = ([regex]$emailpattern).Matches($text) |
      ForEach-Object { $_.Groups[1].Value }

      $emails[0]

      "*" * 100

      $emails
      Note the statement "(?i)" in the regular expression pattern description. The RegEx object by default works case-sensitive. To ignore case, use this control statement.
  #>
    <#.Synopsis
      Searches a set of log files for unique IP addresses, with optional advanced regex matching
      .Parameter LogFileLocation
      A string value specifying the path to the log files to be parsed for unique IP addresses.
      Default value is the current path
      .Parameter Advanced
      Uses an advanced RegEx that avoids matching non IP addresses such as 999.999.999.999
      .Parameter LogFileExtension
      Allows user to specify the log folder extension.  Default is .log.
  #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$LogFileLocation = (get-location).path
        ,
        [parameter()]
        [switch]$Advanced
        ,
        [parameter()]
        [string]$LogFileExtension = '*.log'
    )
    BEGIN {}
    PROCESS
    {
        # get the log file content and store the strings in an array
        $LogStrings = Get-ChildItem -Path $LogFileLocation -Filter $LogFileExtension | Get-Content

        # Determine if the user specified the Advanced RegEx and create Regex Variable Accordingly

        If ($Advanced)
        {
            [regex]$IPRegEx = '\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b'
        }

        Else
        {
            [regex]$IPRegEx = '\b(?:\d{1,3}\.){3}\d{1,3}\b'
        }

        # Locate Matching Values from the string array $LogStrings

        $IPRegEx.Matches($LogStrings) | Select-Object -Property Value -Unique | Sort-Object -Property Value

    }
    END {}

}
function Get-OneDriveFolder
{
    if (Test-Path HKCU:\Software\Microsoft\OneDrive)
    {$OneDrivePath = (Get-ItemProperty -Path HKCU:\Software\Microsoft\OneDrive -Name UserFolder).UserFolder}
    elseif (Test-Path HKCU:\Software\Microsoft\Windows\CurrentVersion\SkyDrive)
    {$OneDrivePath = (Get-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\SkyDrive -Name UserFolder).UserFolder}
    $OneDrivePath
}
function Save-AllISEFiles
{
    <#
      .SYNOPSIS
      Saves all ISE Files except for untitled files. If You have       multiple PowerShellTabs, saves files in all tabs.
  #>
    foreach ($tab in $psISE.PowerShellTabs)
    {
        foreach ($file in $tab.Files)
        {
            if (!$file.IsUntitled)
            {
                $file.Save()
            }
        }
    }
}
function Set-RemoteRegistry
{
    <#
      .SYNOPSIS
      Set-RemoteRegistry allows user to set any given registry key/value pair.

      .DESCRIPTION
      Set-RemoteRegistry allows user to change registry on remote computer using remote registry access.

      .PARAMETER  ComputerName
      Computer name where registry change is desired. If not specified, defaults to computer where script is run.

      .PARAMETER  Hive
      Registry hive where the desired key exists. If no value is specified, LocalMachine is used as default value. Valid values are: ClassesRoot,CurrentConfig,CurrentUser,DynData,LocalMachine,PerformanceData and Users.

      .PARAMETER  Key
      Key where item value needs to be created/changed. Specify Key in the following format: System\CurrentControlSet\Services.

      .PARAMETER  Name
      Name of the item that needs to be created/changed.

      .PARAMETER  Value
      Value of item that needs to be created/changed. Value must be of correct type (as specified by -Type).

      .PARAMETER  Type
      Type of item being created/changed. Valid values for type are: String,ExpandString,Binary,DWord,MultiString and QWord.

      .PARAMETER  Force
      Allows user to bypass confirmation prompts.

      .EXAMPLE
      PS C:\> .\Set-RemoteRegistry.ps1 -Key SYSTEM\CurrentControlSet\services\AudioSrv\Parameters -Name ServiceDllUnloadOnStop -Value 1 -Type DWord

      .EXAMPLE
      PS C:\> .\Set-RemoteRegistry.ps1 -ComputerName ServerA -Key SYSTEM\CurrentControlSet\services\AudioSrv\Parameters -Name ServiceDllUnloadOnStop -Value 0 -Type DWord -Force

      .INPUTS
      System.String

      .OUTPUTS
      System.String

      .NOTES
      Created and maintainted by Bhargav Shukla (MSFT). Please report errors through contact form at http://blogs.technet.com/b/bshukla/contact.aspx. Do not remove original author credits or reference.

      .LINK
      http://blogs.technet.com/bshukla
  #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Position = 0, Mandatory = $false)]
        [System.String]
        $ComputerName = $Env:COMPUTERNAME,
        [Parameter(Position = 1, Mandatory = $false)]
        [ValidateSet("ClassesRoot", "CurrentConfig", "CurrentUser", "DynData", "LocalMachine", "PerformanceData", "Users")]
        [System.String]
        $Hive = "LocalMachine",
        [Parameter(Position = 2, Mandatory = $true, HelpMessage = "Enter Registry key in format System\CurrentControlSet\Services")]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Key,
        [Parameter(Position = 3, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,
        [Parameter(Position = 4, Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Value,
        [Parameter(Position = 5, Mandatory = $true)]
        [ValidateSet("String", "ExpandString", "Binary", "DWord", "MultiString", "QWord")]
        [System.String]
        $Type,
        [Parameter(Position = 6, Mandatory = $false)]
        [Switch]
        $Force
    )

    If ($pscmdlet.ShouldProcess($ComputerName, "Open registry $Hive"))
    {
        #Open remote registry
        try
        {
            $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Hive, $ComputerName)

        }
        catch
        {
            Write-Error "The computer $ComputerName is inaccessible. Please check computer name. Please ensure remote registry service is running and you have administrative access to $ComputerName."
            Return
        }
    }

    If ($pscmdlet.ShouldProcess($ComputerName, "Check existense of $Key"))
    {
        #Open the targeted remote registry key/subkey as read/write
        $regKey = $reg.OpenSubKey($Key, $true)

        #Since trying to open a regkey doesn't error for non-existent key, let's sanity check
        #Create subkey if parent exists. If not, exit.
        If ($regkey -eq $null)
        {
            Write-Warning "Specified key $Key does not exist in $Hive."
            $Key -match ".*\x5C" | Out-Null
            $parentKey = $matches[0]
            $Key -match ".*\x5C(\w*\z)" | Out-Null
            $childKey = $matches[1]

            try
            {
                $regtemp = $reg.OpenSubKey($parentKey, $true)
            }
            catch
            {
                Write-Error "$parentKey doesn't exist in $Hive or you don't have access to it. Exiting."
                Return
            }
            If ($regtemp -ne $null)
            {
                Write-Output "$parentKey exists. Creating $childKey in $parentKey."
                try
                {
                    $regtemp.CreateSubKey($childKey) | Out-Null
                }
                catch
                {
                    Write-Error "Could not create $childKey in $parentKey. You  may not have permission. Exiting."
                    Return
                }

                $regKey = $reg.OpenSubKey($Key, $true)
            }
            else
            {
                Write-Error "$parentKey doesn't exist. Exiting."
                Return
            }
        }

        #Cleanup temp operations
        try
        {
            $regtemp.close()
            Remove-Variable $regtemp, $parentKey, $childKey
        }
        catch
        {
            #Nothing to do here. Just suppressing the error if $regtemp was null
        }
    }

    #If we got this far, we have the key, create or update values
    If ($Force)
    {
        If ($pscmdlet.ShouldProcess($ComputerName, "Create or change $Name's value to $Value in $Key. Since -Force is in use, no confirmation needed from user"))
        {
            $regKey.Setvalue("$Name", "$Value", "$Type")
        }
    }
    else
    {
        If ($pscmdlet.ShouldProcess($ComputerName, "Create or change $Name's value to $Value in $Key. No -Force specified, user will be asked for confirmation"))
        {
            $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", ""
            $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", ""
            $choices = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
            $caption = "Warning!"
            $message = "Value of $Name will be set to $Value. Current value `(If any`) will be replaced. Do you want to proceed?"
            Switch ($result = $Host.UI.PromptForChoice($caption, $message, $choices, 0))
            {
                1
                {
                    Return
                }
                0
                {
                    $regKey.Setvalue("$Name", "$Value", "$Type")
                }
            }
        }
    }

    #Cleanup all variables
    try
    {
        $regKey.close()
        Remove-Variable $ComputerName, $Hive, $Key, $Name, $Value, $Force, $reg, $regKey, $yes, $no, $caption, $message, $result
    }
    catch
    {
        #Nothing to do here. Just suppressing the error if any variable is null
    }
}
function Set-HostOptions
{
    $wi = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $wp = new-object 'System.Security.Principal.WindowsPrincipal' $wi
    if ( $wp.IsInRole("Administrators") -eq 1)
    {$Global:PowershellSessionIsElevated = $true}
    if ($host.Name -like '*ISE*')
    {
        #Start-Steroids
        Set-HostColor
        $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add(“Save All”, {Save-AllISEFiles}, “Ctrl+Shift+S”) | Out-Null
    }
    else
    {
        #$Host.PrivateData.ErrorForegroundColor = 'Red'
        #$Host.PrivateData.ErrorBackgroundColor = 'Black'
        #$Host.PrivateData.WarningForegroundColor = 'Yellow'
        #$Host.PrivateData.WarningBackgroundColor = 'Black'
        #$Host.PrivateData.VerboseForegroundColor = 'Magenta'
        #$Host.PrivateData.VerboseBackgroundColor = 'Black'
        #$Host.PrivateData.DebugForegroundColor = 'Gray'
        #$Host.PrivateData.DebugBackgroundColor = 'Black'
    }
    $FormatEnumerationLimit = 99
}
function Get-DateStamp
{
    [string]$Stamp = Get-Date -Format yyyyMMdd
    $Stamp
}
#End Function Get-DateStamp
function Get-SpecialFolder
{
    <#
            Original source: https://github.com/gravejester/Communary.ConsoleExtensions/blob/master/Functions/Get-SpecialFolder.ps1
            MIT License
            Copyright (c) 2016 Øyvind Kallstad

            Permission is hereby granted, free of charge, to any person obtaining a copy
            of this software and associated documentation files (the "Software"), to deal
            in the Software without restriction, including without limitation the rights
            to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
            copies of the Software, and to permit persons to whom the Software is
            furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all
            copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
            IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
            FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
            AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
            LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
            OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
            SOFTWARE.
        #>
    [cmdletbinding(DefaultParameterSetName = 'All')]
    param (
    )
    DynamicParam
    {
        $Dictionary = New-DynamicParameter -Name 'Name' -Type $([string[]]) -ValidateSet @([Enum]::GetValues([System.Environment+SpecialFolder])) -Mandatory:$true -ParameterSetName 'Selected'
        Write-Output -InputObject $dictionary
    }#DynamicParam
    begin
    {
        #Dynamic Parameter to Variable Binding
        Set-DynamicParameterVariable -dictionary $Dictionary
        switch ($PSCmdlet.ParameterSetName)
        {
            'All'
            {
                $Name = [Enum]::GetValues([System.Environment+SpecialFolder])
            }
            'Selected'
            {
            }
        }
        foreach ($folder in $Name)
        {
            $FolderObject =
            [PSCustomObject]@{
                Name = $folder.ToString()
                Path = [System.Environment]::GetFolderPath($folder)
            }
            Write-Output -InputObject $FolderObject
        }#foreach
    }#begin
}
#End Function Get-SpecialFolder
function Get-CustomRange
{
    #http://www.vistax64.com/powershell/15525-range-operator.html
    [cmdletbinding()]
    param(
        [string] $first
        ,
        [string] $second
        ,
        [string] $type
    )
    $rangeStart = [int] ($first -as $type)
    $rangeEnd = [int] ($second -as $type)
    $rangeStart..$rangeEnd | ForEach-Object { $_ -as $type }
}
#end function Get-CustomRange
function Compare-ComplexObject
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        $ReferenceObject
        ,
        [Parameter(Mandatory)]
        $DifferenceObject
        ,
        [string[]]$SuppressedProperties
        ,
        [parameter()]
        [validateset('All', 'EqualOnly', 'DifferentOnly')]
        [string]$Show = 'All'
    )#param
    #setup properties to compare
    #get properties from the Reference Object
    $RefProperties = @($ReferenceObject | get-member -MemberType Properties | Select-Object -ExpandProperty Name)
    #get properties from the Difference Object
    $DifProperties = @($DifferenceObject | get-member -MemberType Properties | Select-Object -ExpandProperty Name)
    #Get unique properties from the resulting list, eliminating duplicate entries and sorting by name
    $ComparisonProperties = @(($RefProperties + $DifProperties) | Select-Object -Unique | Sort-Object)
    #remove properties where they are entries in the $suppressedProperties parameter
    $ComparisonProperties = $ComparisonProperties | where-object {$SuppressedProperties -notcontains $_}
    $results = @()
    foreach ($prop in $ComparisonProperties)
    {
        $property = $prop.ToString()
        $ReferenceObjectValue = @($ReferenceObject.$($property))
        $DifferenceObjectValue = @($DifferenceObject.$($property))
        switch ($ReferenceObjectValue.Count)
        {
            1
            {
                if ($DifferenceObjectValue.Count -eq 1)
                {
                    $ComparisonType = 'Scalar'
                    If ($ReferenceObjectValue[0] -eq $DifferenceObjectValue[0]) {$CompareResult = $true}
                    If ($ReferenceObjectValue[0] -ne $DifferenceObjectValue[0]) {$CompareResult = $false}
                }#if
                else
                {
                    $ComparisonType = 'ScalarToArray'
                    $CompareResult = $false
                }
            }#1
            0
            {
                $ComparisonType = 'ZeroCountArray'
                $ComparisonResults = @(Compare-Object -ReferenceObject $ReferenceObjectValue -DifferenceObject $DifferenceObjectValue -PassThru)
                if ($ComparisonResults.Count -eq 0) {$CompareResult = $true}
                elseif ($ComparisonResults.Count -ge 1) {$CompareResult = $false}
            }#0
            Default
            {
                $ComparisonType = 'Array'
                $ComparisonResults = @(Compare-Object -ReferenceObject $ReferenceObjectValue -DifferenceObject $DifferenceObjectValue -PassThru)
                if ($ComparisonResults.Count -eq 0) {$CompareResult = $true}
                elseif ($ComparisonResults.Count -ge 1) {$CompareResult = $false}
            }#Default
        }#switch
        $ComparisonObject = New-Object -TypeName PSObject -Property @{Property = $property; CompareResult = $CompareResult; ReferenceObjectValue = $ReferenceObjectValue; DifferenceObjectValue = $DifferenceObjectValue; ComparisonType = $comparisontype}
        $results +=
        $ComparisonObject | Select-Object -Property Property, CompareResult, ReferenceObjectValue, DifferenceObjectValue #,ComparisonType
    }#foreach
    switch ($show)
    {
        'All' {$results}#All
        'EqualOnly' {$results | Where-Object {$_.CompareResult}}#EqualOnly
        'DifferentOnly' {$results |Where-Object {-not $_.CompareResult}}#DifferentOnly
    }#switch $show
}
#end function Compare-ComplexObject
function Start-ComplexJob
{
    <#
        .SYNOPSIS
        Helps Start Complex Background Jobs with many arguments and functions using Start-Job.
        .DESCRIPTION
        Helps Start Complex Background Jobs with many arguments and functions using Start-Job.
        The primary utility is to bring custom functions from the current session into the background job.
        A secondary utility is to formalize the input for creation complex background jobs by using a hashtable template and splatting.
        .PARAMETER  Name
        The name of the background job which will be created.  A string.
        .PARAMETER  JobFunctions
        The name[s] of any local functions which you wish to export to the background job for use in the background job script.
        The definition of any function listed here is exported as part of the script block to the background job.
        .EXAMPLE
        $StartComplexJobParams = @{
        jobfunctions = @(
                'Connect-WAAD'
            ,'Get-TimeStamp'
            ,'Write-Log'
            ,'Write-EndFunctionStatus'
            ,'Write-StartFunctionStatus'
            ,'Export-Data'
            ,'Get-MatchingAzureADUsersAndExport'
        )
        name = "MatchingAzureADUsersAndExport"
        arguments = @($SourceData,$SourceDataFolder,$LogPath,$ErrorLogPath,$OnlineCred)
        script = [scriptblock]{
            $PSModuleAutoloadingPreference = "None"
            $sourcedata = $args[0]
            $sourcedatafolder = $args[1]
            $logpath = $args[2]
            $errorlogpath = $args[3]
            $credential = $args[4]
            Connect-WAAD -MSOnlineCred $credential
            Get-MatchingAzureADUsersAndExport
        }
        }
        Start-ComplexJob @StartComplexJobParams
    #>
    [cmdletbinding()]
    param
    (
        [string]$Name
        ,
        [string[]]$JobFunctions
        ,
        [psobject[]]$Arguments
        ,
        [string]$Script
    )
    #build functions to initialize in job
    $JobFunctionsText = ''
    foreach ($Function in $JobFunctions)
    {
        $FunctionText = 'function ' + (Get-Command -Name $Function).Name + "{`r`n" + (Get-Command -Name $Function).Definition + "`r`n}`r`n"
        $JobFunctionsText = $JobFunctionsText + $FunctionText
    }
    $ExecutionScript = $JobFunctionsText + $Script
    #$initializationscript = [scriptblock]::Create($script)
    $ScriptBlock = [scriptblock]::Create($ExecutionScript)
    $StartJobParams = @{
        Name         = $Name
        ArgumentList = $Arguments
        ScriptBlock  = $ScriptBlock
    }
    #$startjobparams.initializationscript = $initializationscript
    Start-Job @StartJobParams
}
#End Function Start-ComplexJob
function Get-CSVExportPropertySet
{
    <#
            .SYNOPSIS
            Creates an array of property definitions to be used with Select-Object to prepare data with multi-valued attributes for export to a flat file such as csv.

            .DESCRIPTION
            From existing input arrays of scalar and multi-valued properties, creates an array of property definitions to be used with Select-Object or Format-Table. Automates the creation of the @{n=name;e={expression}} syntax for the multi-valued properties then outputs the whole list as a single array.

            .PARAMETER  Delimiter
            Used to specify the custom delimiter to be used between multi-valued entries in the multi-valued attributes input array.  Default is "|" if not specified.  Avoid using a "," if exporting data to a csv file later in your pipeline.

            .PARAMETER  MultiValuedAttributes
            An array of attributes from your source data which you expect to contain multiple values.  These will be converted to @{n=[PropertyName];e={$_.$propertyname -join $Delimiter} in the output of the function.

            .PARAMETER  ScalarAttributes
            An array of attributes from your source data which you expect to contain scalar values.  These will be passed through directly in the output of the function.


            .EXAMPLE
            Get-CSVExportPropertySet -Delimiter ';' -MultiValuedAttributes proxyaddresses,memberof -ScalarAttributes userprincipalname,samaccountname,targetaddress,primarysmtpaddress
            Name                           Value
            ----                           -----
            n                              proxyaddresses
            e                              $_.proxyaddresses -join ';'
            n                              memberof
            e                              $_.memberof -join ';'
            userprincipalname
            samaccountname
            targetaddress
            primarysmtpaddress

            .OUTPUTS
            [array]

        #>
    param
    (
        $Delimiter = '|'
        ,
        [string[]]$MultiValuedAttributes
        ,
        [string[]]$ScalarAttributes
        ,
        [switch]$SuppressCommonADProperties
    )
    $ADUserPropertiesToSuppress = @('CanonicalName', 'DistinguishedName')
    $CSVExportPropertySet = @()
    foreach ($mv in $MultiValuedAttributes)
    {
        $ExpressionString = "`$_." + $mv + " -join '$Delimiter'"
        $CSVExportPropertySet +=
        @{
            n = $mv
            e = [scriptblock]::Create($ExpressionString)
        }
    }#foreach
    if ($SuppressCommonADProperties) {$CSVExportPropertySet += ($ScalarAttributes | Where-Object {$ADUserPropertiesToSuppress -notcontains $_})}
    else {$CSVExportPropertySet += $ScalarAttributes}
    $CSVExportPropertySet
}
#end function Get-CSVExportPropertySet
function Start-WindowsSecurity
{
    #useful in RDP sessions especially on Windows 2012
    (New-Object -ComObject Shell.Application).WindowsSecurity()
}
#end function Start-WindowsSecurity
function Get-RandomFileName
{([IO.Path]::GetRandomFileName())}
#end function Get-RandomFileName
function Get-RandomPassword
{
    [cmdletbinding()]
    Param
    (
        $MinimumLength = 9
        ,
        $MaximumLength = 15
    )
    $ArrayOfChars = [char[]]([char]33..[char]95) + ([char[]]([char]97..[char]126))
    (1..$(Get-Random -Minimum $MinimumLength -Maximum $MaximumLength) | ForEach-Object {$ArrayOfChars | Get-Random}) -join ''
}
#end function Get-RandomPassword
##########################################################################################################
#Import functions from included ps1 files
##########################################################################################################
#. $(Join-Path $PSScriptRoot 'ProfileWizardFunctions.ps1')
. $(Join-Path $PSScriptRoot 'UtilityFunctions.ps1')
. $(Join-Path $PSScriptRoot 'UserInputFunctions.ps1')
. $(Join-Path $PSScriptRoot 'ProgrammingUtilityFunctions.ps1')
. $(Join-Path $PSScriptRoot 'TestFunctions.ps1')
. $(Join-Path $PSScriptRoot 'AzureADFunctions.ps1')
. $(Join-Path $PSScriptRoot 'ExchangeFunctions.ps1')
. $(Join-Path $PSScriptRoot 'ActiveDirectoryFunctions.ps1')
. $(Join-Path $PSScriptRoot 'AADSyncFunctions.ps1')
. $(Join-Path $PSScriptRoot 'ParameterFunctions.ps1')
. $(Join-Path $PSScriptRoot 'PackageAndProfileManagementFunctions.ps1')