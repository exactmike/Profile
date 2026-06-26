Function Enable-AzureADPIMRole
{
    [cmdletbinding()]
    param(
        [string]$UserPrincipalName
        , [String]$Role
        , [string]$Reason
        , [int]$DurationInHours
    )

    if ($null -eq $(Get-Module -Name AzureADPreview))
    {
        throw('Import the AzureADPreview module before using Enable-AzureADPIMRole')
    }

    try
    {
        $TenantDetail = Get-AzureADTenantDetail -ErrorAction Stop
    }
    catch
    {
        throw ('Connect to AzureAD with the Connect-AzureAD command from the AzureADPreview Module before using Enable-AzureADPIMRole')
    }

    $ProviderID = 'aadRoles' #the default keyword for this type of role
    $GetRDParams = @{
        ProviderID = $ProviderID
        ResourceID = $TenantDetail.ObjectId
    }

    $RoleDefinitions = Get-AzureADMSPrivilegedRoleDefinition @GetRDParams

    $RoleDefinition = $RoleDefinitions.where( { $_.DisplayName -eq $Role })
    if ($null -eq $RoleDefinition)
    {
        throw("The value provided for the Role parameter, $Role, is not a valid Role DisplayName.")
    }

    try
    {
        $User = Get-AzureADUser -ObjectId $UserPrincipalName -ErrorAction Stop
    }
    catch
    {
        throw("User object for $UserPrincipalName could not be retrieved.")
    }

    $start = Get-Date
    $end = $start.AddHours($DurationInHours)
    $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
    $schedule.Type = "Once"
    $schedule.StartDateTime = $start.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    $schedule.endDateTime = $end.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

    $OpenAADPRARequestParams = @{
        ProviderID       = $ProviderID
        ResourceId       = $TenantDetail.ObjectID
        RoleDefinitionId = $RoleDefinition.Id
        SubjectId        = $User.ObjectId
        Type             = 'UserAdd'
        AssignmentState  = 'Active'
        Schedule         = $schedule
        Reason           = $Reason
    }

    try
    {
        $AssignmentDetail = Open-AzureADMSPrivilegedRoleAssignmentRequest @OpenAADPRARequestParams -ErrorAction Stop
        [PSCustomObject]@{
            TenantID         = $TenantDetail.ObjectId
            Role             = $Role
            RoleDefinitionId = $RoleDefinition.Id
            User             = $UserPrincipalName
            UserId           = $User.objectId
            AssignmentState  = $AssignmentDetail.AssignmentState
            Reason           = $AssignmentDetail.Reason
            Start            = $start
            End              = $end
        }
    }
    catch
    {
        throw($_)
    }
}

#$PrivilegedRoleAdministrator = $RoleDefinitions.where({$_.DisplayName -eq 'Privileged Role Administrator'})
# Get all role assignments for a user

#$GetURAParams = @{
#    ProviderId = $ProviderID
#    ResourceID = $Connection.TenantID
#    Filter     = "subjectId eq '$($User.ObjectId)'"
#}
#$UserRoleAssignments = Get-AzureADMSPrivilegedRoleAssignment @GetURAParams
