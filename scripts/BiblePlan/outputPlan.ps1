$d = 0
$ntresult.foreach({
    $d++
    [pscustomobject]@{
        Day = $d
        Readings = @($NTC[$_.start..$_.end] | Group-Object -Property Book).foreach({
            switch ($_)
            {
                {$_.group.count -eq 1}
                {"$($_.Name)" + " $($_.group.chapter[0])" }
                {$_.group.count -gt 1}
                {
                    "$($_.Name)" + " $($_.group.chapter[0])" + '-' + "$($_.group.chapter[-1])"
                }
            }
        }) -join ';'
    }
})