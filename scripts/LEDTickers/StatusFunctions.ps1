function Set-LEDTickerOffline
{
    [CmdletBinding()]
    param(
        [parameter()]
        [ValidateLength(0,11)]
        [string]$MeetingText
    )
    $te1 = New-LEDTextElement -text 'OFFLINE' -size 3 -align C -color CC9900 -x 31 -y 10
    $le1 = New-LEDLineElement -color CC3300 -x1 0 -x2 63 -y1 12 -y2 12
    $te2 = New-LEDTextElement -text $MeetingText.ToUpper() -size 2 -align C -color CC9900 -x 31 -y 20
    Out-LEDTicker -Element $te1, $le1, $te2

}

function Set-LEDTickerOnAir
{
    [CmdletBinding()]
    param(
        [switch]$mic
        ,
        [switch]$Video
    )

    $MicText = switch ($mic) { $true { 'MIC ON' } $false { 'MIC OFF' } }
    $VidText = switch ($Video) { $true { 'VIDEO ON' } $false { 'VIDEO OFF' } }

    $te1 = New-LEDTextElement -text 'ON-AIR' -size 3 -align C -color FFCC00 -x 31 -y 10
    $le1 = New-LEDLineElement -color CC3300 -x1 0 -x2 63 -y1 12 -y2 12
    $te2 = New-LEDTextElement -text $MicText -size 2 -align C -color FFCC00 -x 31 -y 20
    $te3 = New-LEDTextElement -text $VidText -size 2 -align C -color FFCC00 -x 31 -y 28
    Out-LEDTicker -Element $te1, $le1, $te2, $te3

}