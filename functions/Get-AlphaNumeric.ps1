    Function Get-AlphaNumeric {
        
    $numbers = 1..26
    $letters = Get-CustomRange -first a -second z -type char
    foreach ($n in $numbers)
    {
        [PSCustomObject]@{
            Letter = $letters[($n-1)]
            Number = $n
        }
    }

    }
