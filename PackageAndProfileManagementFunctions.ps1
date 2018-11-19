function Get-UninstallEntry
{
  [cmdletbinding(DefaultParameterSetName = 'SpecifiedProperties')]
  param(
    [parameter(ParameterSetName = 'Raw')]
    [switch]$raw
    ,
    [parameter(ParameterSetName = 'SpecifiedProperties')]
    [string[]]$property = @('DisplayName','DisplayVersion','InstallDate','Publisher')
  )
    # paths: x86 and x64 registry keys are different
    if ([IntPtr]::Size -eq 4) {
        $path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    }
    else {
        $path = @(
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
            'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
        )
    }
    $UninstallEntries = Get-ItemProperty $path
    # use only with name and unistall information
    #.{process{ if ($_.DisplayName -and $_.UninstallString) { $_ } }} |
    # select more or less common subset of properties
    #Select-Object DisplayName, Publisher, InstallDate, DisplayVersion, HelpLink, UninstallString |
    # and finally sort by name
    #Sort-Object DisplayName
    if ($raw) {$UninstallEntries | Sort-Object -Property DisplayName}
    else {
        $UninstallEntries | Sort-Object -Property DisplayName | Select-Object -Property $property
    }
}
#end function Get-UninstallEntry
Function Get-GitSourcedModule
{
    [cmdletbinding()]
    param(
        $path = $(pwd).path
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
            if ($GitStatus -ne $null)
            {
                $cd.FullName
            }
        }
    }
    else
    {
        $GitStatus = Get-GitStatus
        if ($GitStatus -ne $null)
        {
            $(pwd).path
        }
    }
    Pop-Location
}
Function Update-GitSourcedModule
{
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
function Get-AvailableModuleInstallationStatus
{
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param(
        [parameter(ValueFromPipeline,ValueFromPipelineByPropertyName,ParameterSetName = 'Named')]
        [string[]]$Name
    )
    begin
    {
        $AvailableModules = @()
        $PowerShellGetModules = @()
    }
    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'All'
            {
                #Get the locally available modules on this system for the current user based on entries in $env:Psmodulepath
                $AvailableModules = @(Get-Module -ListAvailable)
                #Get the locally available modules that were installed using PowerShellGet Module commands
                $PowerShellGetModules = @(Get-InstalledModule)
            }
            'Named'
            {
                foreach ($n in $Name)
                {
                    #Get the locally available named module(s) on this system for the current user based on entries in $env:Psmodulepath
                    $AvailableModules += Get-Module -ListAvailable -Name $n -ErrorAction Stop
                    #Get the locally available named module(s) that were installed using PowerShellGet Module commands
                    $PowerShellGetModules += Get-InstalledModule -Name $n -ErrorAction SilentlyContinue
                }
            }
        }
    }
    End
    {
        $PowerShellGetModules | ForEach-Object {
            $RepositoryModule = Find-Module -Name $_.name
            Add-Member -InputObject $_ -MemberType NoteProperty -Name LatestVersion -Value $RepositoryModule.Version
        }
        #Create a lookup hashtable for the PowerShellGet Modules
        $PowerShellGetModulesLookup = $PowerShellGetModules | Group-Object -AsHashTable -Property Name
        $ModuleVersionStatuses = @(
            foreach ($am in $AvailableModules)
            {
                #Iterate through available modules
                $ModuleVersionStatus = [PSCustomObject]@{
                    Name = $am.Name
                    Version = $am.Version
                    PowerShellGet = $null
                    LatestVersion = $null
                    UpdateAvailable = $null
                    Location = Split-Path -Path $am.ModuleBase -Parent
                    Guid = $am.Guid.guid
                }
                switch ($PowerShellGetModulesLookup.ContainsKey($am.Name))
                {
                    $true
                    {
                        try
                        {

                            $PSGetModule = $null
                            $PSGetModule = Get-InstalledModule -Name $am.name -RequiredVersion $am.Version -ErrorAction Stop
                            if ($null -ne $PSGetModule)
                            {
                                $ModuleVersionStatus.PowerShellGet = $true
                                $ModuleVersionStatus.LatestVersion = $PowerShellGetModulesLookup.$($am.name).LatestVersion
                                $ModuleVersionStatus.UpdateAvailable = $($ModuleVersionStatus.LatestVersion -gt $ModuleVersionStatus.Version)
                            }
                        }
                        catch
                        {
                            $ModuleVersionStatus.PowerShellGet = $false
                            $ModuleVersionStatus.LatestVersion = 'Unknown'
                            $ModuleVersionStatus.UpdateAvailable = 'Unknown'
                        }
                    }
                    $false
                    {
                        $ModuleVersionStatus.PowerShellGet = $false
                        $ModuleVersionStatus.LatestVersion = 'Unknown'
                        $ModuleVersionStatus.UpdateAvailable = 'Unknown'
                    }
                }
                $ModuleVersionStatus
            }
        )
        $GroupVersionStatusByModuleName = @($ModuleVersionStatuses | Group-Object -Property Name)
        foreach ($g in $GroupVersionStatusByModuleName)
        {
            switch ($g.count -gt 1)
            {
                $true
                {
                    [PSCustomObject]@{
                        Name = $g.Name
                        LatestVersionInstalled = $g.group.Version | Sort-Object -Descending | Select-Object -First 1
                        InstalledVersions = @($g.group.Version | Sort-Object -Descending -Unique)
                        PowerShellGet = if ($g.group.PowerShellGet -contains $true) {$true} else {$false}
                        LatestVersion = $g.group.LatestVersion | Sort-Object -Descending | Select-Object -First 1
                        UpdateAvailable = if ($g.group.UpdateAvailable -contains $false) {$false} else {$true}
                        Location = @($g.group.Location | Select-Object -Unique)
                        Guid = @($g.group.Guid | Select-Object -Unique)
                    }


                }
                $false
                {
                    [PSCustomObject]@{
                        Name = $g.Name
                        LatestVersionInstalled = $g.group[0].Version
                        InstalledVersions = @($g.group[0].Version)
                        PowerShellGet = $g.group[0].PowerShellGet
                        LatestVersion = $g.group[0].LatestVersion
                        UpdateAvailable = $g.group[0].UpdateAvailable
                        Location = @($g.group[0].Location)
                        Guid = @($g.group[0].Guid)
                    }

                }
            }
        }

    }
}