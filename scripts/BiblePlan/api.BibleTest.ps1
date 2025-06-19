#param(
    $passage = 'Proverbs+14'
#)

$myAPIKey = $apiBibleKey
$headers = @{
    'api-key' = $myAPIKey
}

$baseURL = 'https://api.scripture.api.bible/v1/'
$Bibles = 'bibles'
$query = '?language=eng&include-full-details=false'

$uri= $baseURL + $Bibles + $query

Invoke-RestMethod -FollowRelLink -Uri $uri -Method Get -Headers $headers