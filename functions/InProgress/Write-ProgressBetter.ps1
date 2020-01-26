Function Write-ProgressBetter
{
    [cmdletbinding(DefaultParameterSetName = 'ProgressCount')]
    param(
        $Activity,
        $Status,
        $Id,
        $Completed,
        $CurrentOperation,
        $ParentId,
        $PercentComplete,
        $SecondsRemaining,
        $SourceID,
        [parameter(ParameterSetName = 'ProgressPercent')]
        [int]$ProgressPercentInterval,
        [parameter(ParameterSetName = 'ProgressCount')]
        [int]$ProgressCountInterval = 10,
        [parameter(Mandatory)]
        [int]$RecordCount,

        [switch]$CalculateSecondsRemaining

    )
    #below is junk code for now
    $ProgressInterval = [int]($($sidhistoryusers.Count) * .01)
    if ($($sidhistoryusercounter) % $ProgressInterval -eq 0)
    {
        Write-Progress -Activity $message -status "Items processed: $($sidhistoryusercounter) of $($sidhistoryusers.Count)" -percentComplete (($sidhistoryusercounter / $($sidhistoryusers.Count)) * 100)
    }
}
