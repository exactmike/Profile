function Get-SortableSizeValue {
    <#
    .SYNOPSIS
        This function converts unsortable Exchange quota and limit value strings to a sortable value.
    .DESCRIPTION
        Exchange provides strings for quota and limit values that are not sortable, especially if the values span different scale tiers (MB, GB, etc.). An example of a string is "20 GB (21,474,836,480 bytes)". This function converts those values to a sortable value.  It also preserves the "Unlimited" value that Exchange returns for attributes set with no limit.
    .EXAMPLE
        Get-SortableSizeValue -Value 20 GB (21,474,836,480 bytes) -Scale GB
    #>
    
    [cmdletbinding()]
    param(
        #
        [string]$Value
        ,
        #
        [parameter()]
        [validateSet('KB', 'MB', 'GB', 'TB', 'PB')]
        [string]$Scale
    )

    switch ($Value) {
        'Unlimited' {
            'Unlimited'
        }
        Default {
            $Bytes = $Value.tostring().split([char[]]'() ')[3].replace(',', '')
            [math]::Round($(
                    switch ($Scale) {
                        'KB'
                        { $Bytes / 1KB }
                        'MB'
                        { $Bytes / 1MB }
                        'GB'
                        { $Bytes / 1GB }
                        'TB'
                        { $Bytes / 1TB }
                        'PB'
                        { $Bytes / 1PB }
                    }
                ), 2
            )

        }
    }
}