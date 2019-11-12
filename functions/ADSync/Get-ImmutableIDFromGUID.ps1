    Function Get-ImmutableIDFromGUID {
        
    [cmdletbinding()]
    param
    (
        [guid]$Guid
    )
    [Convert]::ToBase64String($Guid.ToByteArray())

    }
