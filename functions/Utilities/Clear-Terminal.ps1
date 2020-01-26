function Clear-Terminal
{
    Clear-Host
    Write-Output "$([char]27)[2J$([char]27)[3J"
}
