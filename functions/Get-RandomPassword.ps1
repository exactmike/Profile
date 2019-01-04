    Function Get-RandomPassword {
        
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
