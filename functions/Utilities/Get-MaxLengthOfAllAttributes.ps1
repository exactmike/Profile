function Get-MaxLengthOfAllAttributes
{
    [cmdletbinding()]
    param(
        [switch]$ShowProgress
        ,
        [parameter(ValueFromPipeline)]
        [psobject[]]$InputObject
    )
    begin
    {
        $AllPropertyMaxLengths = @{}
        if ($ShowProgress -and $PSBoundParameters.Keys.Contains('InputObject'))
        {
            $TotalCount = $InputObject.Count
            $i = 0
            $CountKnown = $true
        }
        else
        {
            $TotalCount = 0
            $CountKnown = $false
        }
        $WriteProgressParams = @{
            Activity        = 'Analyzing Objects'
            Status          =  "$i of $totalCount"
            PercentComplete = 0
        }
    }#begin
    process
    {
        foreach ($o in $InputObject)
        {
            if ($ShowProgress)
            {
                $i++
                if ($CountKnown -eq $false)
                {
                    $TotalCount++
                }
                $WriteProgressParams.Status = "$i of $totalcount"
                $WriteProgressParams.PercentComplete = $i/$TotalCount*100
                Write-Progress @WriteProgressParams
            }
            $OPropertyList = $o | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
            foreach ($p in $OPropertyList)
            {
                if ($o.$p.capacity -ne $null)
                {
                    $length = @($o.$p.Length) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
                }
                else
                {
                    $length = $o.$p.Length
                }
                if ($AllPropertyMaxLengths.ContainsKey($p))
                {
                    if ($length -gt $AllPropertyMaxLengths.$p)
                    {
                        $AllPropertyMaxLengths.$p = $($length)
                    }
                }
                else
                {
                    $AllPropertyMaxLengths.$p = $length
                }
            }
        }
    }#process
    end
    {
        $AllPropertyMaxLengths.GetEnumerator() | Sort-Object -Property Name
    }#end
}
