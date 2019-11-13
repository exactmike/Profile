function Update-ManagedInstall
{

    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [string]$Name
        ,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$RequiredVersion
        ,
        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]$AutoUpgrade
        ,
        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]$AutoRemove
        ,
        [Parameter(ValueFromPipelineByPropertyName)]
        [String[]]$ExemptMachine
        ,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('Parameter')]
        $AdditionalParameter
        ,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [InstallManager]$InstallManager
        #,
        #[Parameter()]
        #[string]$Repository
    )

    begin
    {
        $localmachinename = [System.Net.Dns]::GetHostName()
    }

    process
    {
        if ($localmachinename -notin $ExemptMachine)
        {
            Write-Information -MessageData "Using $InstallManager to Process Install Definition: $Name"
            switch ($InstallManager)
            {
                'PowerShellGet'
                {
                    $installedModuleInfo = Get-InstalledModuleInfo -Name $Name
                    $installModuleParams = @{
                        Name          = $Name
                        Scope         = 'AllUsers'
                        Force         = $true
                        AcceptLicense = $true
                        AllowClobber  = $true
                    }
                    if (-not [string]::IsNullOrEmpty($AdditionalParameter))
                    {
                        foreach ($ap in $AdditionalParameter.split(';'))
                        {
                            $parameter, $value = $ap.split(' ')
                            switch ($value) { 'TRUE' { $value = $true } 'FALSE' { $value = $false } }
                            $installModuleParams.$parameter = $value
                        }
                    }
                    switch ($true -eq $AutoUpgrade)
                    {
                        $true
                        {
                            if ($false -eq $installedModuleInfo.IsLatestVersion -or $null -eq $installedModuleInfo.IsLatestVersion)
                            {
                                Install-Module @installModuleParams
                            }
                        }
                        $false
                        {
                            #notification/logging that a new version is available
                        }
                    }
                    if ($RequiredVersion.Count -ge 1)
                    {
                        $installedModuleInfo = Get-InstalledModuleInfo -Name $Name
                        foreach ($rv in $RequiredVersion)
                        {
                            if ($rv -notin $installedModuleInfo.AllInstalledVersions)
                            {
                                $installModuleParams.RequiredVersion = $rv
                                Install-Module @installModuleParams
                            }
                        }
                    }
                    if ($true -eq $AutoRemove)
                    {
                        $installedModuleInfo = Get-InstalledModuleInfo -Name $Name
                        [System.Collections.ArrayList]$keepVersions = @()
                        $RequiredVersion.ForEach( { $keepVersions.add($_) }) | Out-Null
                        if ($true -eq $autoupgrade)
                        {
                            $keepVersions.add($installedModuleInfo.LatestRepositoryVersion) | Out-Null
                        }
                        $removeVersions = @($installedModuleInfo.AllInstalledVersions | Where-Object -FilterScript { $_ -notin $keepVersions })
                        if ($removeVersions.Count -ge 1)
                        {
                            $UninstallModuleParams = @{
                                Name  = $Name
                                Force = $true
                            }
                        }
                        foreach ($rV in $removeVersions)
                        {
                            $UninstallModuleParams.RequiredVersion = $rV
                            Uninstall-Module @UninstallModuleParams
                        }
                    }
                }
                'chocolatey'
                {
                    $installedModuleInfo = Get-InstalledByChoco -Name $Name
                    $options = ''
                    if (-not [string]::IsNullOrEmpty($AdditionalParameter))
                    {
                        foreach ($ap in $AdditionalParameter.split(';'))
                        {
                            $parameter, $value = $ap.split(' ')
                            $options += "--$parameter"
                            if ($null -ne $value)
                            {
                                $options += "=`"'$value'`" "
                            }
                            else
                            {
                                $options += ' '
                            }
                        }
                    }
                    switch ($true -eq $AutoUpgrade)
                    {
                        $true
                        {
                            if ($false -eq $installedModuleInfo.IsLatestVersion -or $null -eq $installedModuleInfo.IsLatestVersion)
                            {
                                Invoke-Command -ScriptBlock $([scriptblock]::Create("choco upgrade $Name --Yes --LimitOutput $options"))
                            }
                        }
                        $false
                        {
                            if ($null -eq $installedModuleInfo)
                            {
                                Invoke-Command -ScriptBlock $([scriptblock]::Create("choco upgrade $Name --Yes --LimitOutput $options"))
                            }
                            #notification/logging that a new version is available
                        }
                    }
                }
            }
        }
        else
        {
            Write-Information -MessageData "$localmachinenanme is in ExemptMachines entry. Skipping Install Definition: $Name"
        }
    }
    end
    {

    }
}