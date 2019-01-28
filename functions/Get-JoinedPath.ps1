function Get-JoinedPath
{
    [cmdletbinding()]
    param(
        [string[]]$Path
    )
    foreach ($p in $Path)
    {
        if ($p -contains ':' -and $p -notmatch ''){}
    }
    [IO.Path]::Combine($path)
}
