
<#PSScriptInfo
.DESCRIPTION
 Gets a series of datetime objects for a specified start, interval, units (for the interval) and limit (for the number of datetime instances you want returned).
.VERSION 1.0.0
.GUID b8ca403c-daaa-451f-bbf4-92591a1e05aa
.AUTHOR ThatExactMike
.COMPANYNAME Exact Solutions
.COPYRIGHT 2019
.TAGS DateTime Series Intervals
.LICENSEURI https://github.com/exactmike/profile/License
.PROJECTURI https://gist.github.com/exactmike/517c5005319952c785a191c6143ca467
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
.PRIVATEDATA
#>
<#
.SYNOPSIS
    Gets a series of datetime objects for a specified start, interval, units (for the interval) and limit (for the number of datetime instances you want returned).
.DESCRIPTION
    Gets a series of datetime objects for a specified start, interval, units (for the interval) and limit (for the number of datetime instances you want returned).
    For example, You can get every 14th day from this Friday for the next 10 sets of 14 days.
    Or, you can get every 4th minute for the next 400 minutes by specifying limit 100, units minutes, interval 4.
.EXAMPLE
    $vday = Get-Date -Year 2019 -Month 2 -Day 14 -Hour 12 -Minute 0 -Second 0
    Get-DateSeries -Start $vday -Interval 14 -Units Days -Limit 10

    Thursday, February 14, 2019 12:00:00 PM
    Thursday, February 28, 2019 12:00:00 PM
    Thursday, March 14, 2019 12:00:00 PM
    Thursday, March 28, 2019 12:00:00 PM
    Thursday, April 11, 2019 12:00:00 PM
    Thursday, April 25, 2019 12:00:00 PM
    Thursday, May 9, 2019 12:00:00 PM
    Thursday, May 23, 2019 12:00:00 PM
    Thursday, June 6, 2019 12:00:00 PM
    Thursday, June 20, 2019 12:00:00 PM

    NOTE:Date input and output format results may differ depending on your Culture settings.
    From (and including) the Start, gets a datetime object for the 10 dates with each date being 14 days apart.
.EXAMPLE
    $vday = Get-Date -Year 2019 -Month 2 -Day 14 -Hour 12 -Minute 0 -Second 0
    Get-DateSeries -Start $vday -Interval 14 -Units Days -Limit 10 -SkipStart

    Thursday, February 28, 2019 12:00:00 PM
    Thursday, March 14, 2019 12:00:00 PM
    Thursday, March 28, 2019 12:00:00 PM
    Thursday, April 11, 2019 12:00:00 PM
    Thursday, April 25, 2019 12:00:00 PM
    Thursday, May 9, 2019 12:00:00 PM
    Thursday, May 23, 2019 12:00:00 PM
    Thursday, June 6, 2019 12:00:00 PM
    Thursday, June 20, 2019 12:00:00 PM
    Thursday, July 4, 2019 12:00:00 PM

    NOTE:Date input and output format results may differ depending on your Culture settings.
    From the Start, gets a datetime object for the next 10 dates with each date being 14 days apart. -SkipStart excludes the start date from the result set.
.EXAMPLE
    Get-DateSeries -Start '2019-02-14 11:30:00' -Interval 5 -Units Minutes -Limit 10

    Thursday, February 14, 2019 11:30:00 AM
    Thursday, February 14, 2019 11:35:00 AM
    Thursday, February 14, 2019 11:40:00 AM
    Thursday, February 14, 2019 11:45:00 AM
    Thursday, February 14, 2019 11:50:00 AM
    Thursday, February 14, 2019 11:55:00 AM
    Thursday, February 14, 2019 12:00:00 PM
    Thursday, February 14, 2019 12:05:00 PM
    Thursday, February 14, 2019 12:10:00 PM
    Thursday, February 14, 2019 12:15:00 PM

    NOTE:Date input and output format results may differ depending on your Culture settings.
    Gets a date time object for every 5 minutes from 11:30:00 through 12:15:00
.INPUTS
    DateTime
.OUTPUTS
    DateTime
#>
function Get-DateSeries
{
    [CmdletBinding()]
    [Alias('gds')]
    [OutputType([DateTime[]])]
    Param
    (
        # Specifies a DateTime object from which to start the series calculation. Values that can be dynamically converted by PowerShell to DateTime are also acceptable. Is included in the series output unless -SkipStart is specified.
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [datetime]
        $Start,
        # Specifies the value to use as the interval between datetime objects in the series in the Units specified in -Units.
        [Parameter(
            Mandatory,
            Position = 1
        )]
        [ValidateRange(1, [int]::MaxValue)]
        [int]
        $Interval,
        # Specifies the value to use for the interval of time Units to create the series.
        [Parameter(
            Mandatory,
            Position = 2
        )]
        [ValidateSet('Milliseconds','Seconds','Minutes','Hours','Days','Weeks','Months','Years')]
        [string]
        $Units,
        # Specifies how many results to include in the series
        [Parameter(
            Mandatory,
            Position = 3
        )]
        [ValidateRange(1,[int]::MaxValue)]
        [Int]
        $Limit
        ,
        # Specifies to NOT include the Start datetime in the series.  Otherwise, the start datetime is included.
        [Parameter(
            Position = 4
        )]
        [switch]
        $SkipStart
    )
    process
    {
        $iteration = 0
        if ($true -ne $SkipStart)
        {
            $Start
            $iteration++
        }
        $outputDate = $Start
        while ($iteration -lt $Limit) {
            $iteration++
            $nextDate = $(
                Switch ($Units)
                {
                    'Milliseconds'
                    {
                        $outputDate.AddMilliseconds($Interval)
                    }
                    'Seconds'
                    {
                        $outputDate.AddSeconds($Interval)
                    }
                    'Minutes'
                    {
                        $outputDate.AddMinutes($Interval)
                    }
                    'Hours'
                    {
                        $outputDate.AddHours($Interval)
                    }
                    'Days'
                    {
                        $outputDate.AddDays($Interval)
                    }
                    'Weeks'
                    {
                        $intervalInDays = $Interval * 7
                        $outputDate.AddDays($intervalInDays)
                    }
                    'Months'
                    {
                        $outputDate.AddMonths($Interval)
                    }
                    'Years'
                    {
                        $outputDate.AddYears($Interval)
                    }
                }
            )
            $nextDate
            $outputDate = $nextDate
        }
    }
}
