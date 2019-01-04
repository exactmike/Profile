    Function Test-ADPsDrive {
        
    [cmdletbinding()]
    param
    (
        [string]$Name
        ,
        [switch]$IsRootofDirectory
    )

    #Check PSDrive:  Should be AD, Should be Root of the PSDrive
    Try
    {
        $ADPSDrive = Get-PSDrive -name $name -PSProvider ActiveDirectory -ErrorAction Stop
    }
    Catch
    {
        Write-Verbose -message "No PSDrive with Name $name and PSProviderType ActiveDirectory exists."
        $false
    }

    $PSDriveTests = @{
        ProviderIsActiveDirectory = $($ADPSDrive.Provider.name -eq 'ActiveDirectory')
    }

    if ($IsRootDSE)
    {
        $psdriveTests.RootIsRootOfDirectory = ($ADPSDrive.Root -eq '//RootDSE/')
    }

    if ($PSDriveTests.Values -contains $false)
    {
        $false
    }
    else
    {
        $true
    }

    }
