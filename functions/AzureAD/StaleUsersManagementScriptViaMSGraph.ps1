Function New-SplitArrayRange
{
    <#
MIT License

Copyright (c) 2021 Mike Campbell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#>
    <#
    .SYNOPSIS
    Provides Start and End Ranges to Split an array into a specified number of parts (new arrays) or parts (new arrays) with a specified number (size) of elements
    .PARAMETER inArray
    A one dimensional array you want to split
    .EXAMPLE
    Split-array -inArray @(1,2,3,4,5,6,7,8,9,10) -parts 3
    .EXAMPLE
    Split-array -inArray @(1,2,3,4,5,6,7,8,9,10) -size 3
    .NOTE
    Derived from https://gallery.technet.microsoft.com/scriptcenter/Split-an-array-into-parts-4357dcc1#content
#>
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [array]$inputArray
        ,
        [parameter(Mandatory, ParameterSetName = 'Parts')]
        [int]$parts
        ,
        [parameter(Mandatory, ParameterSetName = 'Size')]
        [int]$size
    )
    switch ($PSCmdlet.ParameterSetName)
    {
        'Parts'
        {
            $PartSize = [Math]::Ceiling($inputArray.count / $parts)
        }#Parts
        'Size'
        {
            $PartSize = $size
            $parts = [Math]::Ceiling($inputArray.count / $size)
        }#Size
    }#switch
    for ($i = 1; $i -le $parts; $i++)
    {
        $start = (($i - 1) * $PartSize)
        $end = (($i) * $PartSize) - 1
        if ($end -ge $inputArray.count) { $end = $inputArray.count }
        $SplitArrayRange = [pscustomobject]@{
            Part  = $i
            Start = $start
            End   = $end
        }
        $SplitArrayRange
    }#for
}
Function Get-RandomFileName
{
    <#
MIT License

Copyright (c) 2021 Mike Campbell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#>
    [cmdletbinding(DefaultParameterSetName = 'WithExtension')]
    param (
        [parameter(Mandatory, ParameterSetName = 'SpecifiedExtension')]
        [string]$extension
    )

    switch ($PSCmdlet.ParameterSetName)
    {
        'WithExtension'
        {
            ([IO.Path]::GetRandomFileName())
        }
        'SpecifiedExtension'
        {
            "$([io.path]::GetFileNameWithoutExtension([IO.Path]::GetRandomFileName())).$extension"
        }
    }
}
Function Connect-SUMGraph
{
    [CmdletBinding()]
    param(
        [parameter(ParameterSetName = 'Certificate')]
        [string]$CertificateThumbprint
        ,
        [parameter()]
        [guid]$TenantID
        ,
        [parameter()]
        [guid]$ClientID
    )
    $cert = Get-ChildItem -Path cert:\ -Recurse -Include $CertificateThumbprint -ErrorAction Stop | Select-Object -First 1 -ErrorAction Stop
    Write-Information -MessageData "Certificate found: $($cert.Subject; $cert.thumbprint) "
    $Token = Get-MsalToken -TenantId $TenantID.guid -ClientCertificate $cert -ClientId $ClientID.guid -ErrorAction Stop
    Write-Information -MessageData "Token Received for Tenant: $($Token.TenantId)"
    $Global:ssToken = $Token.AccessToken | ConvertTo-SecureString -AsPlainText -Force -ErrorAction Stop
    Write-Information -MessageData 'Token converted for use with MS Graph'
    $Global:IRMParams = @{
        Authentication = 'OAuth'
        Token          = $ssToken
        ErrorAction    = 'stop'
    }
}
Function Get-GraphResultAll
{
    param(
        [hashtable]$OperationParams
    )
    do
    {
        $Result = Invoke-RestMethod @IRMParams @OperationParams
        $Result.value #output current results
        switch ($null -ne $Result.'@odata.nextLink')
        {
            $true
            {
                $OperationParams.URI = $Result.'@odata.nextLink'
            }
            $false
            {
                $OperationParams.URI = $null
            }
        }
    }
    until ($null -eq $OperationParams.URI)
}
Function Get-StaleUser
{
    [CmdletBinding()]
    param(
        [psobject]$User
    )
    $GetStaleUsersParams = @{
        Method  = 'get'
        Headers = @{'ConsistencyLevel' = 'eventual'}
        URI     = "https://graph.microsoft.com/beta/users?`$filter=signInActivity/lastSignInDateTime le $strStaleDateString&`$select=displayName,userPrincipalName,ID,signInActivity,onPremisesSyncEnabled&`$count=true"
    }

    $StaleUsers = @(Get-GraphResultAll -OperationParams $GetStaleUsersParams)
}
function Get-NonSyncedUser
{
    [CmdletBinding()]
    param(
        [hashtable]
        $IRMParams
        ,
        [string[]]$IncludeAttribute = @('displayName', 'userPrincipalName', 'ID', 'signInActivity', 'userType', 'externalUserState', 'onPremisesSyncEnabled', 'employeeId', 'employeeType', 'createdDateTime', 'accountEnabled')
    )

    $IncludeAttributeString = $IncludeAttribute -join ','

    $OperationParams = @{
        Method  = 'get'
        Headers = @{'ConsistencyLevel' = 'eventual'}
        URI     = "https://graph.microsoft.com/beta/users?`$filter=onPremisesSyncEnabled ne true &`$select=$IncludeAttributeString&`$count=true"
    }
    Write-Information -MessageData $($OperationParams | ConvertTo-Json -Compress)
    $Users = @(Get-GraphResultAll -OperationParams $OperationParams)
    $Users | Select-Object -Property id, displayName, userPrincipalName, onPremisesSyncEnabled, userType, externalUserState, employeeId, employeeType, @{n='LastLoginDate'; e={$_.signInActivity.lastSignInDateTime}}, createdDateTime, accountEnabled
}
function Select-StaleNonSyncedUser
{
    [CmdletBinding()]
    param(
        [psobject]
        $NonSyncedUser
        ,
        [int]$StaleDisablePolicyDays
        ,
        [int]$StaleDeletePolicyDays
    )
    $today = Get-Date
    $NonSyncedUser.where({
        ($null -eq $_.LastLoginDate -and $_.createdDateTime -le $today.AddDays(-$StaleDisablePolicyDays)) -or
            ($null -ne $_.LastLoginDate -and $_.LastLoginDate -le $today.AddDays(-$StaleDisablePolicyDays))
        }) |
    Select-Object -Property *,
    @{n='StaleDisablePolicyDays'; e={$StaleDisablePolicyDays}},
    @{n='StaleDeletePolicyDays'; e={$StaleDeletePolicyDays}},
    @{n='StaleAgeDays'; e = {
            if ($null -eq $_.LastLoginDate)
            {
                $($today - $($_.createdDateTime)).Days
            }
            else
            {
                $($today - $($_.LastLoginDate)).Days
            }
        }
    }
}
function Resolve-StaleNonSyncedUserException
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory)]
        [psobject[]]
        $StaleNonSyncedUser,
        [parameter(Mandatory)]
        [psobject[]]
        $Exception
    )

    if ($Exception[0].psobject.TypeNames -notcontains 'StaleUserException')
    {
        throw ('This function accepts exceptions only from New-StaleUserException')
    }

    if ($null -eq $StaleNonSyncedUser[0].StaleAgeDays)
    {
        throw ('This function accepts only StaleNonSyncedUsers from Select-StaleNonSyncedUser')
    }

    $expandedException = @(
        switch ($Exception)
        {
            {$_.ExceptionType -eq 'Group'}
            {
                [pscustomobject]@{
                    ExceptionType = 'Group'
                    GroupID       = $_.value
                    Members       = @(Get-GroupMember -GroupID $_.value)
                }
            }
            {$_.ExceptionType -eq 'AttributeComparison'}
            {
                [pscustomobject]@{
                    ExceptionType      = 'AttributeComparison'
                    Attribute          = $_.Attribute
                    ComparisonOperator = $_.ComparisonOperator
                    ComparisonValue    = $_.ComparisonValue
                }
                #$StaleNonSyncedUser.where({$_.employeeID -like $($exception.employeeID) + '*'})
            }
        }
    )

    $StaleNonSyncedUser.foreach({
            $user = $_
            $userException = $false
            switch ($expandedException)
            {
                {$_.ExceptionType -eq 'Group'}
                {
                    if ($user.id -in $_.Members.id)
                    {
                        $exceptionDescription = "group $($_.GroupID)"
                        $user | Select-Object -Property *, @{n='ExceptionType'; e = {$exceptionDescription}}
                        $userException = $true
                        break
                    }
                }
                {$_.ExceptionType -eq 'AttributeComparison'}
                {
                    if ($user.$($_.Attribute) -like $($_.ComparisonValue))
                    {
                        $exceptionDescription = "$($_.Attribute) -like $($_.ComparisonValue)"
                        $user | Select-Object -Property *, @{n='ExceptionType'; e = {$exceptionDescription}}
                        $userException = $true
                        break
                    }
                }
            }
            if ($false -eq $userException)
            {
                $user | Select-Object -Property *, @{n='ExceptionType'; e = {$null}}
            }
        })
}

function New-StaleUserException
{

    [CmdletBinding(DefaultParameterSetName = 'Group')]
    param (
        [parameter(Mandatory)]
        [validateSet('Group', 'AttributeComparison')]
        [string]$ExceptionType
        ,
        [parameter(Mandatory, ParameterSetName = 'Group')]
        [string]$GroupID
        ,
        [parameter(Mandatory, ParameterSetName = 'AttributeComparison')]
        [string]$Attribute
        ,
        [parameter(Mandatory, ParameterSetName = 'AttributeComparison')]
        [string]$ComparisonValue
    )

    begin
    {

    }

    process
    {
        switch ($ExceptionType)
        {
            'Group'
            {
                [pscustomobject]@{
                    PSTypeName    = 'StaleUserException'
                    ExceptionType = $ExceptionType
                    Value         = $GroupID
                }
            }
            'AttributeComparison'
            {
                [pscustomobject]@{
                    PSTypeName      = 'StaleUserException'
                    ExceptionType   = $ExceptionType
                    Attribute       = $Attribute
                    ComparisonValue = $ComparisonValue
                }
            }
        }
    }

    end
    {

    }

}

function Get-GroupMember
{
    [CmdletBinding()]
    param(
        [guid]$GroupID
    )
    $GetGroupMembersParams = @{
        Method = 'get'
        URI    = "https://graph.microsoft.com/v1.0/groups/{$($GroupID.guid)}/members"
    }
    Get-GraphResultAll -OperationParams $GetGroupMembersParams
}

function Remove-GroupMember
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [guid]$GroupID
        ,
        [parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [guid[]]$MemberID
    )

    process
    {
        foreach ($m in $MemberID)
        {

            $RemoveMemberParams = @{
                method = 'delete'
                URI    = "https://graph.microsoft.com/v1.0/groups/{$($GroupID.guid)}/members/{$($m.guid)}/`$ref"
            }
            Invoke-RestMethod @IRMParams @RemoveMemberParams
        }
    }
}
function Add-GroupMember
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [guid]$GroupID
        ,
        [parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [guid[]]$MemberID
    )
    process
    {
        switch ($MemberID.count) #the limit for group member adds in Microsoft Graph is 20
        {
            #create an array of ranges in either case so we can use the same code below to process member adds either way
            { $_ -gt 20 }
            {
                #create a range for each 20 users to add
                $ranges = @(New-SplitArrayRange -inputArray $MemberID -size 20 -ErrorAction Stop)
            }
            { $_ -le 20 -and $_ -gt 0 } #count is greater than 0 and less than or equal to 20
            {
                #creat a range for all users to add
                $ranges = @(New-SplitArrayRange -inputArray $MemberID -size $MemberID.count -ErrorAction Stop)
            }
            { $_ -eq 0 }
            { } #do nothing if the count is zero
        }
        if ($null -ne $ranges)
        {
            foreach ($r in $ranges)
            {
                $AddMemberObject = [PSCustomObject]@{
                    'members@odata.bind' = @($MemberID[$r.Start..$r.end].foreach(
                            {
                                "https://graph.microsoft.com/v1.0/directoryObjects/{$($_.guid)}"
                            }
                        )
                    )
                }

                $AddMemberJsonContent = $AddMemberObject | ConvertTo-Json

                $AddMembersParams = @{
                    method      = 'Patch'
                    URI         = "https://graph.microsoft.com/v1.0/groups/{$($GroupID.guid)}"
                    ContentType = 'application/json'
                    Body        = $AddMemberJsonContent
                }

                try
                {
                    Invoke-RestMethod @IRMParams @AddMembersParams
                }
                catch
                {
                    throw ($_)
                }
            }
        }
    }
}
function Disable-StaleUser
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [psobject[]]$StaleUser
    )

    process
    {
        foreach ($su in $StaleUser)
        {
            switch ($su.accountEnabled)
            {
                $true
                {
                    $DisableUserParams = @{
                        method      = 'Patch'
                        URI         = "https://graph.microsoft.com/v1.0/users/{$($su.id)}"
                        ContentType = 'application/json'
                        Body        = '{"accountEnabled":false}'
                    }
                    try
                    {
                        Invoke-RestMethod @IRMParams @DisableUserParams
                    }
                    catch
                    {
                        $ScriptErrorStrings.Add($_.tostring())
                        $ScriptErrorStrings.Add("Error disabling UserID $($su.id)")
                    }
                }
                $false
                {
                    Write-Warning "User $($su.id) is already disabled."
                }
            }
        }
    }

}
function Remove-StaleUser
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [psobject[]]$StaleUser
    )

    process
    {
        foreach ($su in $StaleUser)
        {

            $DeleteUserParams = @{
                method = 'Delete'
                URI    = "https://graph.microsoft.com/v1.0/users/{$($su.id)}"
            }

            try
            {
                Invoke-RestMethod @IRMParams @DeleteUserParams
            }
            catch
            {
                $ScriptErrorStrings.Add($_.tostring())
                $ScriptErrorStrings.Add("Error deleting UserID $($su.id)")
            }
        }
    }

}

function Invoke-StaleUserAccountProcessing
{
    #Requires -PSEdition Core -Modules MSAL.PS, ImportExcel
    [cmdletbinding(DefaultParameterSetName = 'Certificate')]
    param(
        [parameter(ParameterSetName = 'Certificate')]
        [string]$CertificateThumbprint
        ,
        [parameter()]
        [guid]$TenantID
        ,
        [parameter()]
        [guid]$ClientID
        ,
        [parameter()]
        [guid]$StaleGroupID
        ,
        [parameter()]
        [guid]$ExceptionGroupID
        ,
        [parameter()]
        [int]$StaleDisablePolicyDays = 30
        ,
        [parameter()]
        [int]$StaleDeletePolicyDays = 60
        ,
        [switch]$DisableStaleAccounts
        ,
        [switch]$DeleteAgedStaleAccounts
        ,
        [parameter()]
        [string]$ReportFolderPath = $env:TEMP
    )


    # Assumptions for Process outside of this script:
    # Permanent exception accounts should be placed in the exceptions group (service accounts that are used only periodically)
    # Accounts that need to be re-enabled but not be a permanant exception should be re-enabled and removed from the Stale Users Group (guest accounts or admin accounts that should be regularly used or given up)

    $exceptions = @(
        New-StaleUserException -ExceptionType Group -GroupID $ExceptionGroupID
        New-StaleUserException -ExceptionType AttributeComparison -Attribute employeeID -ComparisonValue '#*'
    )

    $ScriptErrorStrings = [System.Collections.Generic.List[string]]::new()
    $CompletedOperations = [System.Collections.Generic.List[string]]::new()
    [datetime]$today = (Get-Date)
    $staleDisableDate = $today.AddDays( - $StaleDisablePolicyDays)
    #$strStaleDateString = $staleDate.ToString('yyyy-MM-dd') + 'T00:00:00Z'
    $staleDeleteDate = $today.AddDays( - $StaleDisablePolicyDays)
    #$strDeleteDateString = $DeleteAfterDate.ToString( 'yyyy-M -dd') + 'T00:00:00Z'

    #properties/attributes to include when getting group membership info
    $groupMemberProperties = @('id', 'displayName', 'userPrincipalName')

    $ReportObject = [PSCustomObject]@{
        OperationDetails          = [PSCustomObject]@{
            AuthenticationMethod           = $($PSCmdlet.ParameterSetName + ' ' + $CertificateThumbprint)
            DisableStaleAccounts           = $DisableStaleAccounts
            DeleteAgedStaleAccounts        = $DeleteAgedStaleAccounts
            OperationDateUTC               = $today.ToUniversalTime()
            StaleDisablePolicyDays         = $StaleDisablePolicyDays
            StaleDeletePolicyDays          = $StaleDeletePolicyDays
            StaleDisableDate               = $staleDisableDate.ToUniversalTime()
            StaleDeleteDate                = $staleDeleteDate.ToUniversalTime()
            StaleUsersDetectedCount        = $null
            StartingStaleGroupMembersCount = $null
            ExceptionGroupMembersCount     = $null
            RemovedFromStaleGroupCount     = $null
            AddedStaleGroupMembersCount    = $null
            DisabledStaleUsersCount        = $null
            RemovedStaleUsersCount         = $null
            CompletedOperations            = $null
            ErrorCount                     = $null
        }
        StaleUsersDetected        = $null
        StartingStaleGroupMembers = $null
        ExceptionGroupMembers     = $null
        RemovedFromStaleGroup     = $null
        AddedToStaleGroup         = $null
        DisabledStaleUsers        = $null
        RemovedStaleUsers         = $null
    }
    Try
    {
        try # Connect to Microsoft Graph
        {
            $Operation = 'Authentication'
            Write-Information -MessageData "Operation: $Operation"
            Connect-SUMGraph -CertificateThumbprint $CertificateThumbprint -TenantID $TenantID -ClientID $ClientID -ErrorAction stop
            $CompletedOperations.Add($Operation)
        }
        catch
        {
            $ScriptErrorStrings.Add($_.tostring())
            throw($Operation)
        }

        try # Get All Non AD Synced Users with necessary attributes for evaluating staleness
        {
            $Operation = 'GetNonSyncedUser'
            Write-Information -MessageData "Operation: $Operation"
            $NonSyncedUser = Get-NonSyncedUser -IRMParams $irmParams -ErrorAction Stop
            $CompletedOperations.Add($Operation)
        }
        catch
        {
            $ScriptErrorStrings.Add($_.tostring())
            throw($Operation)
        }
        try # Select the stale users from the Non AD Synced Users
        {
            $Operation = 'SelectStaleNonSyncedUser'
            Write-Information -MessageData "Operation: $Operation"
            $StaleNonSyncedUser = @(Select-StaleNonSyncedUser -NonSyncedUser $NonSyncedUser -StaleDisablePolicyDays $StaleDisablePolicyDays -StaleDeletePolicyDays $StaleDeletePolicyDays -ErrorAction Stop)
            $CompletedOperations.Add($Operation)
        }
        catch
        {
            $ScriptErrorStrings.Add($_.tostring())
            throw($Operation)
        }
        try # resolve any exceptions
        {
            $Operation = 'ResolveStaleUserException'
            Write-Information -MessageData "Operation: $Operation"
            $StaleNonSyncedUserER = @(Resolve-StaleNonSyncedUserException -StaleNonSyncedUser $StaleNonSyncedUser -Exception $exceptions -ErrorAction Stop)
            $CompletedOperations.Add($Operation)
            $ReportObject.StaleUsersDetected = $StaleNonSyncedUserER
            $ReportObject.OperationDetails.StaleUsersDetectedCount = $StaleNonSyncedUserER.count
        }
        catch
        {
            $ScriptErrorStrings.Add($_.tostring())
            throw($Operation)
        }
        try # Get Exception Group members for the report (actual exception processed in previous step)
        {
            $Operation = 'GetExceptionGroupMember'
            Write-Information -MessageData "Operation: $Operation"
            $ExceptionGroupMembers = @(Get-GroupMember -GroupID $ExceptionGroupID -ErrorAction Stop | Select-Object -Property $groupMemberProperties)
            $CompletedOperations.Add($Operation)
            $ReportObject.ExceptionGroupMembers = $ExceptionGroupMembers
            $ReportObject.OperationDetails.ExceptionGroupMembersCount = $ExceptionGroupMembers.count
        }
        catch
        {
            $ScriptErrorStrings.Add($_.tostring())
            throw($Operation)
        }
        try # Get Stale Group Members Current
        {
            $Operation = 'GetStaleGroupMember'
            Write-Information -MessageData "Operation: $Operation"
            $StaleGroupMembersCurrent = @(Get-GroupMember -GroupID $StaleGroupID -ErrorAction Stop | Select-Object -Property $groupMemberProperties)
            $CompletedOperations.Add($Operation)
            $ReportObject.StartingStaleGroupMembers = $StaleGroupMembersCurrent
            $ReportObject.OperationDetails.StartingStaleGroupMembersCount = $StaleGroupMembersCurrent.count
        }
        catch
        {
            $ScriptErrorStrings.Add($_.tostring())
            throw($Operation)
        }
        try # Remove No longer stale users (due to exception detected)
        {
            $Operation = 'RemoveStaleGroupMember'
            Write-Information -MessageData "Operation: $Operation"
            $StaleGroupMembersToRemove = @($StaleGroupMembersCurrent.where({
                        $_.id -in @($StaleNonSyncedUserER.where({$null -ne $_.ExceptionType}).id) -or $_.id -notin @($StaleNonSyncedUserER.id)
                    }))
            if ($StaleGroupMembersToRemove.count -ge 1)
            {
                Remove-GroupMember -GroupID $StaleGroupID -MemberID $StaleGroupMembersToRemove.id
            }
            $CompletedOperations.Add($Operation)
            $ReportObject.RemovedFromStaleGroup = $StaleGroupMembersToRemove
            $ReportObject.OperationDetails.RemovedFromStaleGroupCount = $StaleGroupMembersToRemove.count
        }
        catch
        {
            $ScriptErrorStrings.Add($_.tostring())
            throw($Operation)
        }
        try # Add newly detected stale users to the Stale Group used for observability into pending removals
        {
            $Operation = 'AddStaleGroupMember'
            Write-Information -MessageData "Operation: $Operation"
            $StaleGroupMembersToAdd = @($StaleNonSyncedUserER.where({
                        $_.id -notin $StaleGroupMembersCurrent.id -and $null -eq $_.ExceptionType
                    }))
            if ($StaleGroupMembersToAdd.count -ge 1)
            {
                Add-GroupMember -GroupID $StaleGroupID -MemberID $StaleGroupMembersToAdd.id
            }
            $CompletedOperations.Add($Operation)
            $ReportObject.AddedToStaleGroup = $StaleGroupMembersToAdd
            $ReportObject.OperationDetails.AddedStaleGroupMembersCount = $StaleGroupMembersToAdd.count
        }
        catch
        {
            $ScriptErrorStrings.Add($_.tostring())
            throw($Operation)
        }
        try # Calculate and report on stale users to be disabled and disable them if the parameter was set
        {
            $Operation = 'DisableStaleUser'
            Write-Information -MessageData "Operation: $Operation"
            # calculate users to disable
            $StaleNonSyncedUserToDisable = @($StaleNonSyncedUserER.where({$null -eq $_.ExceptionType -and $_.accountEnabled}))
            $ReportObject.DisabledStaleUsers = $StaleNonSyncedUserToDisable
            $ReportObject.OperationDetails.DisabledStaleUsersCount = $StaleNonSyncedUserToDisable.count
            # Perform Disable Actions if required by parameter
            if ($DisableStaleAccounts)
            {
                if ($StaleNonSyncedUserToDisable.count -ge 1)
                {
                    Disable-StaleUser -StaleUser $StaleNonSyncedUserToDisable -ErrorAction Stop
                }
                $CompletedOperations.Add($Operation)
            }
        }
        catch
        {
            $ScriptErrorStrings.Add($_.tostring())
            throw($Operation)
        }
        try # Calculate and report on stale users to be removed and remove them if the parameter was set
        {
            $Operation = 'RemoveStaleUser'
            Write-Information -MessageData "Operation: $Operation"
            # calculate users to remove
            $StaleNonSyncedUserToRemove = @($StaleNonSyncedUserER.where({$null -eq $_.ExceptionType -and $_.StaleAgeDays -ge $_.StaleDeletePolicyDays}))
            $ReportObject.RemovedStaleUsers = $StaleNonSyncedUserToRemove
            $ReportObject.OperationDetails.RemovedStaleUsersCount = $StaleNonSyncedUserToRemove.count
            # Perform Delete Actions if required by parameter
            if ($DeleteAgedStaleAccounts)
            {
                if ($StaleNonSyncedUserToRemove.count -ge 1)
                {
                    Remove-StaleUser -StaleUser $StaleNonSyncedUserToRemove -ErrorAction Stop
                }
                $CompletedOperations.Add($Operation)
            }
        }
        catch
        {
            $ScriptErrorStrings.Add($_.tostring())
            throw($Operation)
        }
    }
    Catch
    {
        $ScriptErrorStrings.Add($_.tostring())
    }
    $ReportObject.OperationDetails.ErrorCount = $ScriptErrorStrings.count
    $ReportObject.OperationDetails.CompletedOperations = $CompletedOperations -join ';'

    $fileName = Get-RandomFileName -Extension 'xlsx'
    $FullFilePath = Join-Path -Path $ReportFolderPath -ChildPath $fileName
    $ExportExcelParams = @{
        path     = $FullFilePath
        AutoSize = $true
    }

    $ReportObject.OperationDetails | Export-Excel @ExportExcelParams -WorksheetName 'OperationDetails'
    $ScriptErrorStrings | Export-Excel @ExportExcelParams -WorksheetName 'Errors'
    $ReportArrays = @('StaleUsersDetected', 'StartingStaleGroupMembers', 'ExceptionGroupMembers', 'RemovedFromStaleGroup', 'AddedToStaleGroup', 'DisabledStaleUsers', 'RemovedStaleUsers')
    $ReportArrays.foreach( {
            $ReportObject.$_ | Export-Excel @ExportExcelParams -WorksheetName $_
        })
}
