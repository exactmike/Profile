function Send-IftttRichNotification
{
    #Attribution: https://www.dennisrye.com/post/send-smartphone-notifications-powershell-ifttt/
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EventName,

        [Parameter(Mandatory)]
        [string]$Key,

        [string]$Value1,

        [string]$Value2,

        [string]$Value3
    )

    $webhookUrl = "https://maker.ifttt.com/trigger/{0}/with/key/{1}" -f $EventName, $Key

    $body = @{
        value1 = $Value1
        value2 = $Value2
        value3 = $Value3
    }

    Invoke-RestMethod -Method Get -Uri $webhookUrl -Body $body
}