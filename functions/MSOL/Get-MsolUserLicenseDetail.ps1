Function Get-MsolUserLicenseDetail
{

    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserPrincipalName')]
        [string[]]$UserPrincipalName
        ,
        [parameter(ValueFromPipeline = $true, ParameterSetName = 'MSOLUserObject')]
        #[Microsoft.Online.Administration.User[]]
        $msoluser
    )
    begin
    {
        function getresult
        {
            param($user)
            $result += [pscustomobject]@{
                UserPrincipalName           = $user.UserPrincipalName
                LicenseAssigned             = $user.Licenses.AccountSKUID
                EnabledServices             = @($user.Licenses.servicestatus | Select-Object -Property @{n = 'Service'; e = { $_.serviceplan.servicename } }, @{n = 'Status'; e = { $_.provisioningstatus } } | Where-Object Status -ne 'Disabled' | Select-Object -ExpandProperty Service)
                DisabledServices            = @($user.Licenses.servicestatus | Select-Object -Property @{n = 'Service'; e = { $_.serviceplan.servicename } }, @{n = 'Status'; e = { $_.provisioningstatus } } | Where-Object Status -eq 'Disabled' | Select-Object -ExpandProperty Service)
                UsageLocation               = $user.UsageLocation
                LicenseReconciliationNeeded = $user.LicenseReconciliationNeeded
            }#result
            $result
        }
    }#begin
    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'UserPrincipalName'
            {
                foreach ($UPN in $UserPrincipalName)
                {
                    try
                    {
                        Write-Log -Message "Attempting: Get-MsolUser for UserPrincipalName $UPN"
                        $user = Get-MsolUser -UserPrincipalName $UPN -ErrorAction Stop
                        Write-Log -Message "Succeeded: Get-MsolUser for UserPrincipalName $UPN"
                        getresult -user $user
                    }#try
                    catch
                    {
                        Write-Log -message "Unable to locate MSOL User with UserPrincipalName $UPN" -ErrorLog
                        Write-Log -message $_.tostring() -ErrorLog
                    }#catch

                }#foreach
            }#UserPrincipalName
            'MSOLUserObject'
            {
                foreach ($user in $msoluser)
                {
                    getresult -user $user
                }#foreach
            }#MSOLUserObject
        }#switch
    }#process
    end
    {
    }#end

}
