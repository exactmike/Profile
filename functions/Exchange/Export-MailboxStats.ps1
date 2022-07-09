function Export-SelectedMailboxStats
{
    #requires -module ImportExcel
    [cmdletbinding(DefaultParameterSetName = 'RecipientFilter')]
    param(
        [parameter(ParameterSetName = 'RecipientFilter')]
        [string[]]$RecipientFilter = "RecipientTypeDetails -eq 'UserMailbox'"
        ,
        [parameter(ParameterSetName= 'RecipientFilter')]
        [string]$Resultsize = 'Unlimited'
        ,
        [parameter(ParameterSetName= 'SpecifiedIdentity')]
        [string[]]$Identity
        ,
        [parameter(Mandatory)]
        [ValidateScript( { Test-Path -type Container -Path $_ })]
        [string]$OutputFolderPath
        ,
        [switch]$OutputRawStats
        ,
        [parameter()]
        [ValidateSet('GB', 'MB')]
        $StatsDenominator = 'GB'
    )

    $MU = "1$StatsDenominator" #mailboxUnit
    $MailboxProperties = @(
        @{n = 'ExchangeGuid'; e = { $_.ExchangeGuid.guid } }
        @{n = 'ProhibitSendQuota'; e = { [math]::Round([single]$($_.ProhibitSendQuota.tostring().split(@('(', ')', ' '))[3].replace(',', '') / $MU), 2) } }
        @{n = 'ProhibitSendReceiveQuota'; e = { [math]::Round([single]$($_.ProhibitSendReceiveQuota.tostring().split(@('(', ')', ' '))[3].replace(',', '') / $MU), 2) } }
        @{n = 'IssueWarningQuota'; e = { [math]::Round([single]$($_.IssueWarningQuota.tostring().split(@('(', ')', ' '))[3].replace(',', '') / $MU), 2) } }
        @{n = 'RecoverableItemsQuota'; e = { [math]::Round([single]$($_.RecoverableItemsQuota.tostring().split(@('(', ')', ' '))[3].replace(',', '') / $MU), 2) } }
        @{n = 'ArchiveQuota'; e = { [math]::Round([single]$($_.ArchiveQuota.tostring().split(@('(', ')', ' '))[3].replace(',', '') / $MU), 2) } }
        'LitigationHoldEnabled'
        'RetentionPolicy'
        'ArchiveStatus'
        'AutoExpandingArchiveEnabled'
        'RecipientTypeDetails'
    )

    $GetMBParams = @{
        PropertySets = 'hold', 'quota', 'retention', 'archive'
        Properties   = 'ExchangeGuid', 'RecipientTypeDetails'
    }

    switch ($PSCmdlet.ParameterSetName)
    {
        'RecipientFilter'
        {
            $mailboxes = @(
                foreach ($f in $RecipientFilter)
                {
                    $GetMBParams.ResultSize   = $Resultsize
                    $GetMBParams.Filter = $f
                    Get-EXOMailbox @GetMBParams | Select-Object -Property $MailboxProperties
                }
            )
        }
        'SpecifiedIdentity'
        {
            $mailboxes = @(
                foreach ($i in $Identity)
                {
                    $GetMBParams.Identity = $i
                    Get-EXOMailbox @GetMBParams | Select-Object -Property $MailboxProperties
                }
            )
        }
    }

    $StatProperties = @(
        @{n = 'ExchangeGuid'; e = { $_.MailboxGuid.guid } }
        @{n= 'RecipientTypeDetails'; e= {$mb.RecipientTypeDetails}}
        'ItemCount'
        'DeletedItemCount'
        @{n = 'TotalMailboxItemSize'; e = { [Math]::Round([single]$($_.TotalItemSize.tostring().split(@('(', ')', ' '))[3].replace(',', '') / $MU), 2) } }
        @{n = 'TotalRecoverableItemSize'; e = { [Math]::Round([single]$($_.TotalDeletedItemSize.tostring().split(@('(', ')', ' '))[3].replace(',', '') / $MU), 2) } }
        @{n = 'TotalAttachmentSize'; e = {
                [Math]::Round(
                    $([single]$($_.AttachmentTableTotalSize.tostring().split(@('(', ')', ' '))[3].replace(',', '') / $MU) -
                        [single]$($_.AttachmentTableAvailableSize.tostring().split(@('(', ')', ' '))[3].replace(',', '') / $MU)), 2
                )
            }
        }
        @{n = 'ProhibitSendQuota'; e = {$mb.ProhibitSendQuota } }
        @{n = 'ProhibitSendReceiveQuota'; e = {$mb.ProhibitSendReceiveQuota } }
        @{n = 'IssueWarningQuota'; e = {$mb.IssueWarningQuota } }
        @{n = 'RecoverableItemsQuota'; e = {$mb.RecoverableItemsQuota} }
        @{n = 'ArchiveQuota'; e = {$mb.ArchiveQuota } }
        @{n = 'LitigationHoldEnabled'; e = {$mb.LitigationHoldEnabled}}
        @{n = 'RetentionPolicy'; e = {$mb.RetentionPolicy}}
        @{n = 'ArchiveStatus'; e = {$mb.ArchiveStatus}}
        @{n = 'AutoExpandingArchiveEnabled'; e = {$mb.AutoExpandingArchiveEnabled}}
        @{n = 'SizeUnit'; e = {$StatsDenominator}}
    )

    $GetMBSParams = @{
        Identity = $null
        #WarningAction = 'SilentlyContinue'
        #ErrorAction   = 'SilentlyContinue'
    }

    $WPParams = @{
        Activity         = 'Get-EXOMailboxStatistics'
        CurrentOperation = $null
        Status           = $null
        PercentComplete  = $null
    }

    $mbCount = $mailboxes.count
    $mbPCount = 0

    $mailboxStats = @(
        foreach ($mb in $mailboxes)
        {
            $mbPCount++
            $GetMBSParams.Identity = $mb.ExchangeGuid
            $WPParams.CurrentOperation = $mb.ExchangeGuid
            $WPParams.Status = "mailbox $mbPCount of $mbCount"
            $WPParams.PercentComplete = $mbPCount/$mbCount*100
            Write-Progress @WPParams
            Get-EXOMailboxStatistics @GetMBSParams | Select-Object -Property $StatProperties
        }
        Write-Progress @wpparams -complete
    )

    if ($OutputRawStats)
    {
        $mailboxStats
    }

    $DateString = Get-Date -Format yyyyMMddHHmmss

    $OutputFileName = 'MailboxStats-' + $DateString
    $OutputFilePath = Join-Path $OutputFolderPath $($OutputFileName + '.xlsx')

    $eParams = @{
        Path          = $OutputFilePath
        FreezeTopRow  = $true
        TableStyle    = 'Medium16'
        AutoSize      = $true
        WorksheetName = 'mailboxStats'
        InputObject   = $mailboxStats
    }

    Export-Excel @eParams
}

function Export-SelectedMailboxFolderStats
{
    #requires -module ImportExcel
    [cmdletbinding()]
    param(
        [parameter()]
        [validateset(
            'All',
            'Archive',
            'Calendar',
            'Contacts',
            'ConversationHistory',
            'DeletedItems',
            'Drafts',
            'Inbox',
            'JunkEmail',
            'Journal',
            'LegacyArchiveJournals',
            'ManagedCustomFolder',
            'NonIpmRoot',
            'Notes',
            'Outbox',
            'Personal',
            'RecoverableItems',
            'RSSSubscriptions',
            'SentItems',
            'SyncIssues',
            'Tasks'
        )]
        [string[]]$FoldersToInclude

        ,
        [parameter(Mandatory)]
        [ValidateScript( { Test-Path -type Container -Path $_ })]
        [string]$OutputFolderPath
        ,
        [parameter(Mandatory)]
        [psobject]$MailboxStats
        ,
        [switch]$OutputRawStats
        ,
        [parameter()]
        [ValidateSet('GB', 'MB', 'KB')]
        $StatsDenominator = 'MB'
    )

    $FU = "1$StatsDenominator" #haha, FolderUnit
    if ($FoldersToInclude.count -eq 0)
    {
        $FoldersToInclude = @(
            'Archive',
            'Calendar',
            'DeletedItems',
            'Drafts',
            'Inbox',
            'JunkEmail',
            'Outbox',
            'RecoverableItems',
            'SentItems'
        )
    }

    $GetMBFSParams = @{
        FolderScope                 = $null
        Identity                    = $null
        IncludeOldestAndNewestItems = $true
        WarningAction               = 'SilentlyContinue'
        ErrorAction                 = 'SilentlyContinue'
    }

    $folderStatsProperties = @(
        @{n = 'ExchangeGuid'; e = { $_.ContentMailboxGuid.guid } }
        'FolderType'
        'FolderPath'
        'ItemsInFolder'
        'ItemsInFolderAndSubfolders'
        'DeletedItemsInFolder'
        'DeletedItemsInFolderAndSubfolders'
        @{n = 'FolderSize'; e = { [math]::Round([single]$($_.FolderSize.tostring().split(@('(', ')', ' '))[3].replace(',', '') / $FU), 2) } }
        @{n = 'FolderAndSubfolderSize'; e = { [math]::Round([single]$($_.FolderAndSubfolderSize.tostring().split(@('(', ')', ' '))[3].replace(',', '') / $FU), 2) } }
        'OldestItemReceivedDate'
        'NewestItemReceivedDate'
        'OldestItemLastModifiedDate'
        'NewestItemLastModifiedDate'
        @{n='SizeUnit'; e = {$StatsDenominator}}
    )

    $WPParams = @{
        Activity         = "Get-MailboxFolderStatistics for $($foldersToInclude.count) folders per mailbox"
        CurrentOperation = $null
        Status           = $null
        PercentComplete  = $null
    }

    $mbCount = $MailboxStats.count
    $mbPCount = 0

    $folderStats = @(
        foreach ($mb in $MailboxStats)
        {
            $mbPCount++
            $WPParams.CurrentOperation = $mb.ExchangeGuid
            $WPParams.Status = "mailbox $mbPCount of $mbCount"
            $WPParams.PercentComplete = $mbPCount/$mbCount*100
            Write-Progress @WPParams

            foreach ($f in $foldersToInclude)
            {
                $GetMBFSParams.Identity = $mb.ExchangeGuid
                $GetMBFSParams.FolderScope = $f
                Get-MailboxFolderStatistics @GetMBFSParams | Select-Object -Property $folderStatsProperties
            }
        }
    )
    if ($OutputRawStats)
    {
        $folderStats
    }

    $DateString = Get-Date -Format yyyyMMddHHmmss

    $OutputFileName = 'MailboxFolderStats-' + $DateString
    $OutputFilePath = Join-Path $OutputFolderPath $($OutputFileName + '.xlsx')

    $eParams = @{
        Path          = $OutputFilePath
        FreezeTopRow  = $true
        TableStyle    = 'Medium18'
        AutoSize      = $true
        WorksheetName = 'folderStats'
        InputObject   = $FolderStats
    }

    Export-Excel @eParams

}