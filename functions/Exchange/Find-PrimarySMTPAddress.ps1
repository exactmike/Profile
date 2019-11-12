    Function Find-PrimarySMTPAddress {
        
    [cmdletbinding()]
    Param
    (
        [parameter(mandatory = $true)]
        [Alias('EmailAddresses')]
        [string[]]$ProxyAddresses
    )
    $PrimaryAddresses = @($ProxyAddresses | Where-Object {$_ -clike 'SMTP:*'} | ForEach-Object {($_ -split ':')[1]})
    switch ($PrimaryAddresses.count)
    {
        1
        {
            $PrimarySMTPAddress = $PrimaryAddresses[0]
            $PrimarySMTPAddress
        }#1
        0
        {
            $null
        }#0
        Default
        {
            $false
        }#Default
    }#switch

    }
