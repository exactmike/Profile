    Function Update-GitSourcedModule {

    [cmdletbinding()]
    param(
        $path = $(Get-Location).path
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
            $Name = Split-Path -Leaf -Path $gsm
            $GitStatus = Get-GitStatus | Select-Object -property @{n='Name';e={$Name}},Branch,Upstream,BehindBy,AheadBy,HasWorking
            Write-Information -MessageData $GitStatus
            $Message = "Fetching $Name from $($GitStatus.Upstream)"
            Write-Information -MessageData $Message
            git fetch
            $GitStatus = Get-GitStatus
            switch ($GitStatus.HasWorking)
            {
                $true
                {
                    $Message = "$($Name) has $($gitStatus.Working.Count) file(s) with local uncommitted changes: $($GitStatus.Working -join ', ')"
                    Write-Information -MessageData $Message -Tags Warning
                }
                $false
                {
                    if ($GitStatus.BehindBy -gt 0)
                    {
                        $Message = "Pull $($Name) for $($GitStatus.Branch) from $($GitStatus.Upstream)"
                        Write-Information -MessageData $Message
                        git pull
                    }
                    if ($GitStatus.AheadBy -gt 0)
                    {
                        $Message = "Push $($Name) for $($GitStatus.Branch) to $($GitStatus.Upstream)"
                        Write-Information -MessageData $Message
                        git push
                    }
                    if ($GitStatus.BehindBy -eq 0 -and $gitStatus.AheadBy -eq 0)
                    {
                        $Message = "$Name is even with $($GitStatus.Upstream)"
                        Write-Information -MessageData $Message
                    }
                }
            }
            $GitStatus = Get-GitStatus | Select-Object -property @{n='Name';e={$Name}},Branch,Upstream,BehindBy,AheadBy,HasWorking
            Write-Information -MessageData $GitStatus
        }
        Pop-Location
    }

    }
