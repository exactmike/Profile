    Function Get-ByteArrayFromGUID {
        
    [cmdletbinding()]
    param
    (
        [guid]$GUID
    )
    $GUID.ToByteArray()

    }
