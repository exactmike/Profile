function Get-TimeInZone {
[CmdletBinding(DefaultParameterSetName = 'ZoneID')]
param(
    [Parameter(Mandatory,ParameterSetName = 'ZoneID')]
    [string[]]$TimeZoneID
    ,
    [Parameter(Mandatory,ParameterSetName = 'ZoneName')]
    [string[]]$TimeZoneName
    ,
    [Parameter()]
    [DateTime]$DateTime = $(Get-Date)
)
    $Zones = @(switch ($PSCmdlet.ParameterSetName)
    {
        'ZoneID'
        {$TimeZoneID}
        'ZoneName'
        {$TimeZoneName}
    })

    foreach ($tz in $Zones)
    {
        $zone = Get-TimeZone -Id $tz
        $ZoneDateTime = Get-Date $([System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($DateTime,$tz))
        switch ($zone.IsDaylightSavingTime($ZoneDateTime))
        {
            $true
            {
                [PSCustomObject]@{
                    DateTime = Get-Date -Date $([System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($DateTime,$tz))
                    ZoneName = $zone.DaylightName
                }
            }
            $false
            {
                [PSCustomObject]@{
                    DateTime = Get-Date -Date $([System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($DateTime,$tz))
                    ZoneName = $zone.StandardName
                }
            }
        }
    }

}