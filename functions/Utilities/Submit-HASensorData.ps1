function Submit-HASensorData
{
    [CmdletBinding()]
    param(
        [parameter()]
        [string]$HomeAssistantURL
        ,
        [parameter()]
        [string]$SensorName = 'sensor.duke_energy_consumption'
        ,
        [parameter()]
        $Value
        ,
        [parameter()]
        [ValidateSet('mWh', 'Wh', 'kWh', 'MWh', 'GWh', 'TWh', 'cal', 'kcal', 'Mcal', 'Gcal')]
        [string]$UnitOfMeasurement
        ,
        [parameter()]
        [ValidateSet('energy')]
        [string]$DeviceClass
        ,
        [parameter()]
        [ValidateSet('total_increasing')]
        [string]$StateClass
        ,
        [parameter(Mandatory)]
        [string]$FriendlyName
        ,
        [parameter(Mandatory)]
        [string]$LLAToken
    )

    $headers = @{
        'Authorization' = "Bearer $LLAToken"
        'Content-Type'  = 'application/json'
    }

    $body = @{
        state      = $Value
        attributes = @{
            unit_of_measurement = $UnitOfMeasurement
            device_class        = $DeviceClass
            state_class         = $StateClass
            friendly_name       = $FriendlyName
        }
    } | ConvertTo-Json -Depth 4


    $IRMParams = @{
        Method = 'Post'
        ErrorAction = 'Stop'
        Uri = "$HomeAssistantURL/api/states/$SensorName"
        Headers = $headers
        Body = $body
    }

    Invoke-RestMethod @IRMParams

}