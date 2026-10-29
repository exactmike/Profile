    Function Get-Base64StringFromGUID {
        
    [cmdletbinding()]
    param
    (
        [guid]$Guid
    )
    [Convert]::ToBase64String($Guid.ToByteArray())

    }
