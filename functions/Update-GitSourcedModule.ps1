    Function Update-GitSourcedModule {
        
    [cmdletbinding()]
    param(
        $path = $(pwd).path
        ,
        [switch]$Recurse
    )
    $GetGitSourcedModuleParams = @{
        path = $path
    }
    if ($true -eq $Recurse)
    {
        $GetGitSourcedModuleParams.Recurse = $true
    }
    $GitSourcedModules = @(Get-GitSourcedModule @GetGitSourcedModuleParams)
    if ($GitSourcedModules.Count -ge 1)
    {
        Push-Location
        foreach ($gsm in $GitSourcedModules)
        {
            Set-Location -LiteralPath $gsm
            $GitStatus = Get-GitStatus
            $Name = Split-Path -Leaf -Path $gsm
            $Message = "Fetching $Name from $($GitStatus.Upstream)"
            Write-Verbose -Message $Message
            git fetch
            $GitStatus = Get-GitStatus
            switch ($GitStatus.HasWorking)
            {
                $true
                {
                    $Message = "$($cd.PSChildName) has $($gitStatus.Working.Count) file(s) with local uncommitted changes: $($GitStatus.Working -join ', ')"
                    Write-Warning -Message $Message
                }
                $false
                {
                    if ($GitStatus.BehindBy -gt 0)
                    {
                        $Message = "Pull $($cd.PSChildName) for $($GitStatus.Branch) from $($GitStatus.Upstream)"
                        Write-Verbose -Message $Message
                        git pull
                    }
                    if ($GitStatus.AheadBy -gt 0)
                    {
                        $Message = "Push $($cd.PSChildName) for $($GitStatus.Branch) to $($GitStatus.Upstream)"
                        Write-Verbose -Message $Message
                        git push
                    }
                }
            }
        }
        Pop-Location
    }

    }
