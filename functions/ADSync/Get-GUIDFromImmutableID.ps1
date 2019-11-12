    Function Get-GUIDFromImmutableID {
        
    [cmdletbinding()]
    param
    (
        $ImmutableID
    )
    [GUID][convert]::frombase64string($ImmutableID)

    }
