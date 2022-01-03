function Start-SelectedApp
{
    [CmdletBinding()]
    param (
        # Name of the App to Start
        [Parameter(Mandatory,ParameterSetName='Name')]
        [String[]]
        $Name
        ,
        # Name of the Group of Apps to Start
        [Parameter(Mandatory,ParameterSetName='Group')]
        [ValidateSet('DailyCrypto')]
        [String]
        $Group
    )

    begin
    {

    }

    process
    {
        $AppsToStart = @(
            switch ($pscmdlet.ParameterSetName)
            {
                'Name'
                {
                    $Name
                }
                'Group'
                {
                    switch ($Group)
                    {
                        'DailyCrypto'
                        {
                            'MetaMask'
                            'AAVE'
                            'Adamant'
                            'Balancer'
                            'Mai Finance'
                            'Impermax'
                            'Cometh'
                            'QuickSwap'
                            'ParaSwap'
                            'Mantra DAO'
                            'Polygon Beefy'
                        }
                    }
                }
            }
        )
        foreach ($a in $AppsToStart)
        {
            $appID = $(Get-StartApps -Name $a).AppID.tostring()
            $path = 'shell:AppsFolder\' + $appID

            Start-Process $path

        }
    }

    end
    {

    }
}


$MyApps = @(
    'MetaMask'
    'AAVE'
    'Adamant'
    'Balancer'
    'Mai Finance'
    'Impermax'
    'Cometh'
    'QuickSwap'
    'ParaSwap'
    'Yoroi'
    'CoinList'
    'Demex'
    'DODO'
    'Mantra DAO'
    'Polygon Beefy'
)
