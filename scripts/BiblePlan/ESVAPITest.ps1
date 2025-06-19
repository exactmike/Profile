#param(
    $passage = 'Proverbs+14'
#)

$myAPIKey = $APIKey
$headers = @{
    Authorization = "Token $myAPIKey"
}
$AudioEndpoint = 'https://api.esv.org/v3/passage/audio/'
$query = '?q=' + $passage
$uri= $AudioEndpoint + $query

Invoke-RestMethod -FollowRelLink -Uri $uri -Method Get -Headers $headers -OutFile test.mp3
