    Function Convert-MailboxToMailUser {
        
    [cmdletbinding(SupportsShouldProcess)]
    param
    (
        [parameter(Mandatory)]
        $Identity
        ,
        [parameter(Mandatory)]
        $ExchangeOrganization
    )
    $ExchangeSystem = Get-OneShellSystem -identity $ExchangeOrganization -ErrorAction Stop
    Connect-OneShellSystem -Identity $ExchangeOrganization -ErrorAction Stop
    $ExchangeSession = Get-OneShellSystemPSSession -identity $ExchangeOrganization -ErrorAction Stop

    $OriginalMailbox = Invoke-Command -Session $ExchangeSession -ScriptBlock {Get-Mailbox -identity $using:Identity -erroraction Stop} -ErrorAction Stop
    #Build Intermediate MEU object
    $MailUserObject = [PSCustomObject]@{
        Identity = $OriginalMailbox.guid.guid
        Alias = $OriginalMailbox.Alias
        DisplayName = $OriginalMailbox.DisplayName
        PrimarySMTPAddress = $OriginalMailbox.PrimarySMTPAddress
        ExternalEmailAddress = $OriginalMailbox.ForwardingSmtpAddress
        EmailAddresses = Get-DesiredProxyAddresses -DesiredOrCurrentAlias $OriginalMailbox.Alias -LegacyExchangeDNs $OriginalMailbox.LegacyExchangeDN  -CurrentProxyAddresses $OriginalMailbox.EmailAddresses
        AcceptMessagesOnlyFrom = $OriginalMailbox.AcceptMessagesOnlyFrom
        BypassModerationFromSendersOrMembers = $OriginalMailbox.BypassModerationFromSendersOrMembers
        CustomAttribute1 = $OriginalMailbox.CustomAttribute1
        CustomAttribute2 = $OriginalMailbox.CustomAttribute2
        CustomAttribute3 = $OriginalMailbox.CustomAttribute3
        CustomAttribute4 = $OriginalMailbox.CustomAttribute4
        CustomAttribute5 = $OriginalMailbox.CustomAttribute5
        CustomAttribute6 = $OriginalMailbox.CustomAttribute6
        CustomAttribute7 = $OriginalMailbox.CustomAttribute7
        CustomAttribute8 = $OriginalMailbox.CustomAttribute8
        CustomAttribute9 = $OriginalMailbox.CustomAttribute9
        CustomAttribute10 = $OriginalMailbox.CustomAttribute10
        CustomAttribute11 = $OriginalMailbox.CustomAttribute11
        CustomAttribute12 = $OriginalMailbox.CustomAttribute12
        CustomAttribute13 = $OriginalMailbox.CustomAttribute13
        CustomAttribute14 = $OriginalMailbox.CustomAttribute14
        CustomAttribute15 = $OriginalMailbox.CustomAttribute15
        ExtensionCustomAttribute1 = $OriginalMailbox.ExtensionCustomAttribute1
        ExtensionCustomAttribute2 = $OriginalMailbox.ExtensionCustomAttribute2
        ExtensionCustomAttribute3 = $OriginalMailbox.ExtensionCustomAttribute3
        ExtensionCustomAttribute4 = $OriginalMailbox.ExtensionCustomAttribute4
        ExtensionCustomAttribute5 = $OriginalMailbox.ExtensionCustomAttribute5
        ExchangeGUID = $OriginalMailbox.ExchangeGUID
        GrantSendOnBehalfTo = $OriginalMailbox.GrantSendOnBehalfTo
        HiddenFromAddressListsEnabled = $OriginalMailbox.HiddenFromAddressListsEnabled
        MailTip = $OriginalMailbox.MailTip
        MailTipTranslations = $OriginalMailbox.MailTipTranslations
        MaxReceiveSize = $OriginalMailbox.MaxReceiveSize
        MaxSendSize = $OriginalMailbox.MaxSendSize
        ModeratedBy = $OriginalMailbox.ModeratedBy
        ModerationEnabled = $OriginalMailbox.ModerationEnabled
        Name = $OriginalMailbox.Name
        RecipientLimits = $OriginalMailbox.RecipientLimits
        RejectMessagesFrom = $OriginalMailbox.RejectMessagesFrom
        RequireSenderAuthenticationEnabled = $OriginalMailbox.RequireSenderAuthenticationEnabled
        SimpleDisplayName = $OriginalMailbox.SimpleDisplayName
        UsageLocation = $OriginalMailbox.UsageLocation
    }
    Export-OneShellData -DataToExport $OriginalMailbox -DataToExportTitle $($OriginalMailbox.guid.guid + 'MailboxObjectBackup') -DataType clixml -Depth 4 -ErrorAction Stop
    #disable the original mailbox
    Invoke-Command -Session $ExchangeSession -ScriptBlock {Disable-Mailbox -identity $($Using:MailUserObject).Identity -confirm:$false -erroraction Stop} -ErrorAction Stop
    #enable the replacement mailuser
    $EnableParamsList = 'Identity','ExternalEmailAddress','Alias','DisplayName','PrimarySmtpAddress'
    $EnableParams = @{
        ErrorAction = 'Stop'
        Identity = $MailUserObject.Identity
        Alias = $MailUserObject.Alias
        ExternalEmailAddress = $MailUserObject.ExternalEmailAddress
        PrimarySmtpAddress = $MailUserObject.PrimarySMTPAddress
        DisplayName = $MailUserObject.DisplayName
    }
    Invoke-Command -Session $ExchangeSession -ScriptBlock {Enable-MailUser @using:EnableParams} -ErrorAction Stop
    $SetParams = @{ErrorAction = 'Stop';ForceUpgrade = $true}
    foreach ($m in $(Get-Member -InputObject $MailUserObject -MemberType Properties | Select-Object -ExpandProperty Name))
    {
        if ($null -ne $MailUserObject.$m -and -not [string]::IsNullOrWhiteSpace($MailUserObject.$m))
        {
            if ($m -notin @('PrimarySmtpAddress'))
            {
                $SetParams.$m = $MailUserObject.$m
            }
        }
    }
    Invoke-Command -Session $ExchangeSession -ScriptBlock {Set-MailUser @using:SetParams} -ErrorAction Stop

    }
