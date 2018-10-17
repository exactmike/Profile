function Remove-Member
{
    [cmdletbinding()]
    param
    (
        [parameter(Mandatory, ValueFromPipeline)]
        [psobject[]]$Object
        ,
        [parameter(Mandatory)]
        [string]$Member
    )
    begin {}
    process
    {
        foreach ($o in $Object)
        {
            $o.psobject.Members.Remove($Member)
        }
    }
}
#end function Remove-Member
function New-SplitArrayRange
{
    <#
        .SYNOPSIS
        Provides Start and End Ranges to Split an array into a specified number of parts (new arrays) or parts (new arrays) with a specified number (size) of elements
        .PARAMETER inArray
        A one dimensional array you want to split
        .EXAMPLE
        Split-array -inArray @(1,2,3,4,5,6,7,8,9,10) -parts 3
        .EXAMPLE
        Split-array -inArray @(1,2,3,4,5,6,7,8,9,10) -size 3
        .NOTE
        Derived from https://gallery.technet.microsoft.com/scriptcenter/Split-an-array-into-parts-4357dcc1#content
        #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [array]$inputArray
        ,
        [parameter(Mandatory, ParameterSetName = 'Parts')]
        [int]$parts
        ,
        [parameter(Mandatory, ParameterSetName = 'Size')]
        [int]$size
    )
    switch ($PSCmdlet.ParameterSetName)
    {
        'Parts'
        {
            $PartSize = [Math]::Ceiling($inputArray.count / $parts)
        }#Parts
        'Size'
        {
            $PartSize = $size
            $parts = [Math]::Ceiling($inputArray.count / $size)
        }#Size
    }#switch
    for ($i = 1; $i -le $parts; $i++)
    {
        $start = (($i - 1) * $PartSize)
        $end = (($i) * $PartSize) - 1
        if ($end -ge $inputArray.count) {$end = $inputArray.count}
        $SplitArrayRange = [pscustomobject]@{
            Part  = $i
            Start = $start
            End   = $end
        }
        $SplitArrayRange
    }#for
}
#end function New-SplitArrayRange
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
            Id               = 2147483646
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
                        $speak.SpeakAsync("$secondsremaining") > $null
                    }
                    else
                    {
                        $speak.SpeakAsync("$secondsremaining seconds remaining") > $null
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
                        $speak.SpeakAsync("$minutesremaining minutes remaining") > $null
                    }
                    else
                    {
                        if ($secondsremaining -ge 1)
                        {
                            $speak.SpeakAsync("$secondsremaining seconds remaining") > $null
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
                        $speak.SpeakAsync("$hoursremaining hours remaining") > $null
                    }
                    else
                    {
                        $minutesremaining = $remaining.TotalMinutes.tostring("#.##")
                        if ($minutesremaining -ge 1)
                        {
                            $speak.SpeakAsync("$minutesremaining minutes remaining") > $null
                        }
                        else
                        {
                            if ($secondsremaining -ge 1)
                            {
                                $speak.SpeakAsync("$secondsremaining seconds remaining") > $null
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
                        $speak.SpeakAsync("$daysremaining days remaining") > $null
                    }
                    else
                    {
                        $hoursremaining = $remaining.TotalHours.tostring("#.##")
                        if ($hoursremaining -ge 1)
                        {
                            $speak.SpeakAsync("$hoursremaining hours remaining") > $null
                        }
                        else
                        {
                            $minutesremaining = $remaining.TotalMinutes.tostring("#.##")
                            if ($minutesremaining -ge 1)
                            {
                                $speak.SpeakAsync("$minutesremaining minutes remaining") > $null
                            }
                            else
                            {
                                if ($secondsremaining -ge 1)
                                {
                                    $speak.SpeakAsync("$secondsremaining seconds remaining") > $null
                                }
                            }
                        }

                    }
                }
            }
        }
        $currentvrt = $vrts | Where-Object -FilterScript {$_.countdownpoint -ge $($secondsremaining - 1)} | Select-Object -First 1
        if ($currentvrt)
        {
            $Frequency = $currentvrt.frequency
            $Units = $currentvrt.units
            $vrts = $vrts | Where-Object -FilterScript {$_countdownpoint -ne $currentvrt.countdownpoint}
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
#end function New-Timer
Function Convert-ObjectToHashTable
{

    <#
            .Synopsis
            Convert an object into a hashtable.
            .Description
            This command will take an object and create a hashtable based on its properties.
            You can have the hashtable exclude some properties as well as properties that
            have no value.
            .Parameter Inputobject
            A PowerShell object to convert to a hashtable.
            .Parameter NoEmpty
            Do not include object properties that have no value.
            .Parameter Exclude
            An array of property names to exclude from the hashtable.
            .Example
            PS C:\> get-process -id $pid | select name,id,handles,workingset | ConvertTo-HashTable

            Name                           Value
            ----                           -----
            WorkingSet                     418377728
            Name                           powershell_ise
            Id                             3456
            Handles                        958
            .Example
            PS C:\> $hash = get-service spooler | ConvertTo-Hashtable -Exclude CanStop,CanPauseandContinue -NoEmpty
            PS C:\> $hash

            Name                           Value
            ----                           -----
            ServiceType                    Win32OwnProcess, InteractiveProcess
            ServiceName                    spooler
            ServiceHandle                  SafeServiceHandle
            DependentServices              {Fax}
            ServicesDependedOn             {RPCSS, http}
            Name                           spooler
            Status                         Running
            MachineName                    .
            RequiredServices               {RPCSS, http}
            DisplayName                    Print Spooler

            This created a hashtable from the Spooler service object, skipping empty
            properties and excluding CanStop and CanPauseAndContinue.
            .Notes
            Version:  2.0
            Updated:  January 17, 2013
            Author :  Jeffery Hicks (http://jdhitsolutions.com/blog)

            Read PowerShell:
            Learn Windows PowerShell 3 in a Month of Lunches
            Learn PowerShell Toolmaking in a Month of Lunches
            PowerShell in Depth: An Administrator's Guide

            "Those who forget to script are doomed to repeat their work."

            .Link
            http://jdhitsolutions.com/blog/2013/01/convert-powershell-object-to-hashtable-revised
            .Link
            About_Hash_Tables
            Get-Member
            .Inputs
            Object
            .Outputs
            hashtable
        #>

    [cmdletbinding()]

    Param(
        [Parameter(Position = 0, Mandatory,
            HelpMessage = 'Please specify an object', ValueFromPipeline)]
        [ValidateNotNullorEmpty()]
        $InputObject,
        [switch]$NoEmpty,
        [string[]]$Exclude
    )

    Process
    {
        #get type using the [Type] class because deserialized objects won't have
        #a GetType() method which is what we would normally use.

        $TypeName = [type]::GetTypeArray($InputObject).name
        Write-Verbose -Message "Converting an object of type $TypeName"

        #get property names using Get-Member
        $names = $InputObject | Get-Member -MemberType properties |
            Select-Object -ExpandProperty name

        #define an empty hash table
        $hash = @{}

        #go through the list of names and add each property and value to the hash table
        $names | ForEach-Object {
            #only add properties that haven't been excluded
            if ($Exclude -notcontains $_)
            {
                #only add if -NoEmpty is not called and property has a value
                if ($NoEmpty -AND -Not ($inputobject.$_))
                {
                    Write-Verbose -Message "Skipping $_ as empty"
                }
                else
                {
                    Write-Verbose -Message "Adding property $_"
                    $hash.Add($_, $inputobject.$_)
                }
            } #if exclude notcontains
            else
            {
                Write-Verbose -Message "Excluding $_"
            }
        } #foreach
        Write-Verbose -Message 'Writing the result to the pipeline'
        $hash
    }#close process

}
function Convert-SecureStringToString
{
    <#
            .SYNOPSIS
            Decrypts System.Security.SecureString object that were created by the user running the function.  Does NOT decrypt SecureString Objects created by another user.
            .DESCRIPTION
            Decrypts System.Security.SecureString object that were created by the user running the function.  Does NOT decrypt SecureString Objects created by another user.
            .PARAMETER SecureString
            Required parameter accepts a System.Security.SecureString object from the pipeline or by direct usage of the parameter.  Accepts multiple inputs.
            .EXAMPLE
            Decrypt-SecureString -SecureString $SecureString
            .EXAMPLE
            $SecureString1,$SecureString2 | Decrypt-SecureString
            .LINK
            This function is based on the code found at the following location:
            http://blogs.msdn.com/b/timid/archive/2009/09/09/powershell-one-liner-decrypt-securestring.aspx
            .INPUTS
            System.Security.SecureString
            .OUTPUTS
            System.String
        #>

    [cmdletbinding()]
    param (
        [parameter(ValueFromPipeline = $True)]
        [securestring[]]$SecureString
    )

    BEGIN {}
    PROCESS
    {
        foreach ($ss in $SecureString)
        {
            if ($ss -is 'SecureString')
            {[Runtime.InteropServices.marshal]::PtrToStringAuto([Runtime.InteropServices.marshal]::SecureStringToBSTR($ss))}
        }
    }
    END {}
}
function Get-GuidFromByteArray
{
    [cmdletbinding()]
    param
    (
        [byte[]]$GuidByteArray
    )
    New-Object -TypeName guid -ArgumentList (, $GuidByteArray)
}
#end function Get-GUIDFromByteArray
function Get-ImmutableIDFromGUID
{
    [cmdletbinding()]
    param
    (
        [guid]$Guid
    )
    [Convert]::ToBase64String($Guid.ToByteArray())
}
#end function Get-ImmutableIDFromGUID
function Get-GUIDFromImmutableID
{
    [cmdletbinding()]
    param
    (
        $ImmutableID
    )
    [GUID][convert]::frombase64string($ImmutableID)
}
#end function Get-GUIDFromImmutableID
function Get-ByteArrayFromGUID
{
    [cmdletbinding()]
    param
    (
        [guid]$GUID
    )
    $GUID.ToByteArray()
}
#end function Get-ByteArrayFromGUID
function Get-Checksum
{
    Param (
        [parameter(Mandatory = $True)]
        [ValidateScript( {Test-Path -path $_ -PathType Leaf})]
        [string]$File
        ,
        [ValidateSet('sha1', 'md5')]
        [string]$Algorithm = 'sha1'
    )
    $FileObject = Get-Item -Path $File
    $fs = new-object System.IO.FileStream $($FileObject.FullName), 'Open'
    $algo = [type]"System.Security.Cryptography.$Algorithm"
    $crypto = $algo::Create()
    $hash = [BitConverter]::ToString($crypto.ComputeHash($fs)).Replace('-', '')
    $fs.Close()
    $hash
}
#end function Get-Checksum
function Export-Credential
{
    param(
        [string]$message
        ,
        [string]$username
    )
    $GetCredentialParams = @{}
    if ($message) {$GetCredentialParams.Message = $message}
    if ($username) {$GetCredentialParams.Username = $username}

    $credential = Get-Credential @GetCredentialParams

    $ExportUserName = $credential.UserName
    $ExportPassword = ConvertFrom-SecureString -Securestring $credential.Password

    $exportCredential = [pscustomobject]@{
        UserName = $ExportUserName
        Password = $ExportPassword
    }
    $exportCredential
}
#end function Export-Credential
function Show-One
{
    [cmdletbinding()]
    param
    (
        [parameter(ValueFromPipeline)]
        [psobject[]]$Input
        ,
        [switch]$ClearHost
    )
    process
    {
        foreach ($i in $input)
        {
            if ($true -eq $clearhost) {Clear-Host}
            $i | Format-List * -force
            Read-Host
        }
    }
}
function Get-UNCPath {
    [cmdletbinding()]
    param (
        [parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [validatescript({Test-Path -Path $_})]
        [string[]]$Path = $(Get-Location).Path
    )
    begin
    {
        function Get-ContainerUNCPath
        {
            param(
                $ContainerPath
            )
            Push-Location
            Set-Location -Path $ContainerPath
            $loc = Get-Location
            if ($null -eq $loc.Drive) {$loc.ProviderPath} 
            else {
                switch ($null -eq $loc.Drive.DisplayRoot)
                {
                    $true #not a network mapped drive - is local.  Might not work for drives mapped to a local subdirectory? need to test and revise if not
                    {
                        Join-Path -path (Join-Path -Path $('\\' + [System.Environment]::MachineName) -ChildPath $($loc.Drive.Name + '$')) -ChildPath $loc.Drive.CurrentLocation
                    }
                    $false #is a network mapped drive
                    {
                        Join-Path -Path $loc.Drive.DisplayRoot -ChildPath $loc.Drive.CurrentLocation   
                    }
                }
            }
            Pop-Location
        }
    }
    process
    {
        foreach ($p in $Path)
        {
            $item = Get-Item -Path $p
            switch ($item.PSIsContainer)
            {
                $true
                {
                    Get-ContainerUNCPath -ContainerPath $item.FullName
                }
                $false
                {
                    Join-Path -Path $(Get-ContainerUNCPath -ContainerPath $(Split-Path -Path $item.FullName -Parent)) -ChildPath $item.name
                }
            }
        }
    }    
}

