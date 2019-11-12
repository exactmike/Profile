    Function Get-GuidFromByteArray {
        
    [cmdletbinding()]
    param
    (
        [byte[]]$GuidByteArray
    )
    New-Object -TypeName guid -ArgumentList (, $GuidByteArray)

    }
