    Function Get-QualifiedADUserObject {
        
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$ActiveDirectoryInstance
        ,
        [string]$LDAPFilter
        #'(&(sAMAccountType=805306368)(proxyAddresses=SMTP:*)(extensionattribute15=DirSync))'
        #'(&((sAMAccountType=805306368))(mail=*)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))'
        ,
        [string[]]$Properties = $script:ADUserAttributes
    )
    #Retrieve all qualified (per the filter)AD User Objects including the specified properties
    Write-StartFunctionStatus -CallingFunction $MyInvocation.MyCommand
    #Connect-ADInstance -ActiveDirectoryInstance $ActiveDirectoryInstance -ErrorAction Stop > $null
    Set-Location -Path "$($ActiveDirectoryInstance):\"
    $GetADUserParams = @{
        ErrorAction = 'Stop'
        Properties  = $Properties
    }
    if ($PSBoundParameters.ContainsKey('LDAPFilter'))
    {
        $GetADUserParams.LDAPFilter = $LDAPFilter
    }
    else
    {
        $GetADUserParams.Filter = '*'
    }
    Try
    {
        $message = 'Retrieve qualified Active Directory User Accounts.'
        Write-Log -verbose -message $message -EntryType Attempting
        $QualifiedADUsers = @(Get-ADUser @GetADUserParams | Select-Object -Property $Properties)
        $message = $message + " Count:$($QualifiedADUsers.count)"
        Write-Log -verbose -message $message -EntryType Succeeded
        Write-Output -InputObject $QualifiedADUsers
    }
    Catch
    {
        $myerror = $_
        Write-Log -Message 'Active Directory user objects could not be retrieved.' -ErrorLog -Verbose
        Write-Log -Message $myerror.tostring() -ErrorLog
    }
    Write-EndFunctionStatus $MyInvocation.MyCommand

    }
