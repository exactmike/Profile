    Function Get-ExchangeRecipient {
        
    [cmdletbinding()]
    param
    (
        [parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Identity
        ,
        [parameter(Mandatory)]
        [System.Management.Automation.Runspaces.PSSession[]]$ExchangeSession
    )
    DynamicParam
    {
        $dictionary = New-ExchangeOrganizationDynamicParameter -Mandatory -Multivalued
        $dictionary
    }
    begin
    {
        #Test the ExchangeSession(s)
    }
    process
    {
        foreach ($id in $Identity)
        {
            $InvokeCommandParams = @{
                #ErrorAction = 'Stop'
                WarningAction = 'SilentlyContinue'
                ErrorAction   = 'Continue'
                scriptblock   = [scriptblock] {Get-Recipient -Identity $id -WarningAction SilentlyContinue -ErrorAction Continue}
                Cmdlet        = 'Get-Recipient'
            }
            foreach ($s in $ExchangeSession)
            {
                $InvokeCommandParams.Session = $s
                Invoke-Command @InvokeCommandParams
            }
        }
    }#process

    }
