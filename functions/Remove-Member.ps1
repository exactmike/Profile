    Function Remove-Member {
        
    [cmdletbinding()]
    param
    (
        [parameter(Mandatory, ValueFromPipeline)]
        [Alias('Object')]
        [PSCustomObject[]]$InputObject
        ,
        [parameter(Mandatory)]
        [string]$Member
    )
    begin {
        $ErrorActionPreference = 'Stop'
    }
    process
    {
        foreach ($o in $InputObject)
        {
            switch ($o.GetType().name)
            {
                'PSCustomObject'
                {
                    Write-Verbose -Message "Using psobject.members.Remove($Member)"
                    $o.psobject.Members.Remove($Member)
                }
                Default
                {
                   Write-Verbose -Message "Using Select-Object -property * -ExcludeProperty $Member"
                   Write-Error -Message "Remove-Member is not effective for objects not of type PSCustomObject. This object is of type $($o.gettype().name)"
                   #$o = $o | Select-Object -Property * -ExcludeProperty $Member
                }
            }
        }
    }

    }
