Function Get-LocalGitRepo
{

    [cmdletbinding()]
    param(
        $path = $(Get-Location).path
        ,
        [switch]$Recurse
    )
    Push-Location
    Set-Location -Path $path
    if ($true -eq $Recurse)
    {
        $ChildDirectories = Get-ChildItem -Directory
        foreach ($cd in $ChildDirectories)
        {
            Set-Location -LiteralPath $cd.FullName
            $GitStatus = Get-GitStatus
            if ($null -ne $GitStatus)
            {
                [pscustomobject]@{
                    LocalName = $cd.FullName
                    Branch    = $GitStatus.Branch
                    Upstream  = $GitStatus.Upstream
                    BehindBy  = $GitStatus.BehindBy
                    AheadBy   = $GitStatus.AheadBy
                }
            }
        }
    }
    else
    {
        $GitStatus = Get-GitStatus
        if ($null -ne $GitStatus)
        {
            [pscustomobject]@{
                LocalName = $(Get-Location).path
                Branch    = $GitStatus.Branch
                Upstream  = $GitStatus.Upstream
                BehindBy  = $GitStatus.BehindBy
                AheadBy   = $GitStatus.AheadBy
            }
        }
    }
    Pop-Location

}
