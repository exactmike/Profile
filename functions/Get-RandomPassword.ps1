Function Get-RandomPassword
{
    [cmdletbinding()]
    Param
    (
        [parameter()]
        [int]$Length = 16
        ,
        [parameter()]
        [validateset('Any', 'NoSpecial')]
        [string]$CharacterSet = 'Any'
    )

    $ArrayOfChars = [char[]]@(
        switch ($CharacterSet)
        {
            'Any'
            {([char]33..[char]95) + ([char[]]([char]97..[char]126))}
            'NoSpecial'
            {([char]65..[char]90) + ([char[]]([char]97..[char]122))}
        }
    )
    (1..$Length | ForEach-Object {$ArrayOfChars | Get-Random}) -join ''
}
