    Function Get-GUIDFromBase64String {
        
    [cmdletbinding()]
    param
    (
        $ImmutableID
    )
    [GUID][convert]::frombase64string($ImmutableID)

    }
