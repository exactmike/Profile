    Function Test-RecipientObjectForUnwantedSMTPAddresses {
        
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$WantedDomains
        ,
        [Parameter(Mandatory)]
        [ValidateScript( {($_ | Test-Member -name 'EmailAddresses') -or ($_ | Test-Member -name 'ProxyAddresses')})]
        [psobject[]]$Recipient
        ,
        [Parameter()]
        [ValidateSet('ReportUnwanted', 'ReportAll', 'TestOnly')]
        [string]$Operation = 'TestOnly'
        ,
        [bool]$ValidateSMTPAddress = $true
    )
    foreach ($R in $Recipient)
    {
        Switch ($R)
        {
            {$R | Test-Member -Name 'EmailAddresses'}
            {$AddrAtt = 'EmailAddresses'}
            {$R | Test-Member -Name 'ProxyAddresses'}
            {$AddrAtt = 'ProxyAddresses'}
        }
        $Addresses = @($R.$addrAtt)
        $TestedAddresses = @(
            foreach ($A in $Addresses)
            {
                if ($A -like 'smtp:*')
                {
                    $RawA = $A.split(':')[1]
                    $ADomain = $RawA.split('@')[1]
                    $IsSupportedDomain = $ADomain -in $WantedDomains
                    $outputRecord =
                    [pscustomobject]@{
                        DistinguishedName  = $R.DistinguishedName
                        Identity           = $R.Identity
                        Address            = $RawA
                        Domain             = $ADomain
                        IsSupportedDomain  = $IsSupportedDomain
                        IsValidSMTPAddress = $null
                    }
                    if ($ValidateSMTPAddress)
                    {
                        $IsValidSMTPAddress = Test-EmailAddress -EmailAddress $RawA
                        $outputRecord.IsValidSMTPAddress = $IsValidSMTPAddress
                    }
                }
                $outputRecord
            }
        )
        switch ($Operation)
        {
            'TestOnly'
            {
                if ($TestedAddresses.IsSupportedDomain -contains $false -or $TestedAddresses.IsValidSMTPAddress -contains $false)
                {$false}
                else
                {$true}
            }
            'ReportUnwanted'
            {
                $UnwantedAddresses = @($TestedAddresses | Where-Object -FilterScript {$_.IsSupportedDomain -eq $false -or $_.IsValidSMTPAddress -eq $false})
                if ($UnwantedAddresses.Count -ge 1)
                {
                    $UnwantedAddresses
                }
            }
            'ReportAll'
            {
                $TestedAddresses
            }
        }
    }#foreach R in Recipient

    }
