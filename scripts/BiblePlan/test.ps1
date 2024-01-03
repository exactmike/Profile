# code for New-SplitArrayRange 

$prefixSum = [System.Collections.Generic.List[decimal]]::new()
$e = 0
$NTC.foreach({ #$inputArray
        $prefixSum.add($_.WordCount + $prefixSum[$e - 1]) #$NumericValueAttribute
        $e++
    })

$uff = .32
$lff = .745
$limit = 1400
$upperlimit = $limit * $(1 + $uff)
$lowerlimit = $limit * $(1 - $lff)
$lastsum = 0
for (
    $i,$p,$start = 0,1,0
    $i -lt $NTC.count
    $i++
)
{
    $tempsum = $prefixSum[$i] - $lastsum
    switch ($tempsum)
        {
            {$tempsum -le $upperlimit -and $tempsum -ge $lowerlimit} # in range
            # lessthan or equal to the limit plus the fudge factor percentage
            # AND greater than or equal to the limit minus the fudge factor percentage
            {
                [PSCustomObject]@{
                    Part  = $p
                    Start = $start
                    End   = $i
                    Sum   = $tempsum
                }
                $lastsum = $prefixSum[$i] # record lastsum which is current element
                $start = $i + 1 # next start ready which will be next element
                $p++ # ready for next part
            }
            {$tempsum -gt $upperlimit} # above range - fall back to last element
            {
                
                [PSCustomObject]@{
                    Part  = $p
                    Start = $start
                    End   = $i -1
                    Sum   = $prefixSum[$i-1] - $lastsum
                }
                $lastsum = $prefixSum[$i-1] # record lastsum which is last element
                $start = $i # next start ready which will be current element
                $p++ # ready for next part
            }
            {$tempsum -lt $lowerlimit} # below range - usually continue to next element
            {
                if ($i -eq $($otc.count -1))
                {
                    [PSCustomObject]@{
                        Part  = $p
                        Start = $start
                        End   = $i
                        Sum   = $tempsum
                    }
                }
            }
        }
}