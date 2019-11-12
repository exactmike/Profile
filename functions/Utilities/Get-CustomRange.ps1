    Function Get-CustomRange {
        
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
