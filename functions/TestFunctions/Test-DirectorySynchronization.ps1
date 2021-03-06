﻿    Function Test-DirectorySynchronization {
        
  [cmdletbinding()]
  Param(
    [string]$identity
    ,
    [int]$MaxSyncWaitMinutes = 15
    ,
    #could possibly look this up on the DirSync Server task history?
    [int]$DeltaSyncExpectedMinutes = 2
    ,
    $SyncCheckInterval = 15
    , 
    $ExchangeOrganization = 'OL'
    ,
    $RecipientAttributeToCheck = 'RecipientType'
    ,
    $RecipientAttributeValue
    ,
    [switch]$InitiateSynchronization
  )
  Begin {}
  Process
  {
    Connect-Exchange -ExchangeOrganization $ExchangeOrganization
    $Recipient = Invoke-ExchangeCommand -cmdlet Get-Recipient -ExchangeOrganization $ExchangeOrganization -string "-Identity $Identity -ErrorAction SilentlyContinue" -ErrorAction SilentlyContinue
    if ($Recipient.$RecipientAttributeToCheck -eq $RecipientAttributeValue) {
        Write-Log -Message "Checking $identity for value $RecipientAttributeValue in attribute $RecipientAttributeToCheck." -EntryType Succeeded  
        Write-Output -InputObject $true
    }
    elseif ($InitiateSynchronization) {
        Write-Log -Message "Initiating Directory Synchronization and Checking/Waiting for a maximum of $MaxSyncWaitMinutes minutes." -EntryType Notification
        $stopwatch = [Diagnostics.Stopwatch]::StartNew()
        $minutes = 0
        Start-DirectorySynchronization
        do {
            Start-Sleep -Seconds $SyncCheckInterval
            Connect-Exchange -ExchangeOrganization $ExchangeOrganization
            Write-Log -Message "Checking $identity for value $RecipientAttributeValue in attribute $RecipientAttributeToCheck." -EntryType Attempting
            $Recipient = Invoke-ExchangeCommand -cmdlet Get-Recipient -ExchangeOrganization $ExchangeOrganization -string "-Identity $Identity -ErrorAction SilentlyContinue" -ErrorAction SilentlyContinue
            #check if we have already waited the DeltaSyncExpectedMinutes.  If so, request a new directory synchronization
            if (($stopwatch.Elapsed.Minutes % $DeltaSyncExpectedMinutes -eq 0) -and ($stopwatch.Elapsed.Minutes -ne $minutes)) {
                $minutes = $stopwatch.Elapsed.Minutes
                Write-Log -Message "$minutes minutes of a maximum $MaxSyncWaitMinutes minutes elapsed. Initiating additional Directory Synchronization attempt." -EntryType Notification
                Start-DirectorySynchronization
            }
        }
        until ($Recipient.$RecipientAttributeToCheck -eq $RecipientAttributeValue -or $stopwatch.Elapsed.Minutes -ge $MaxSyncWaitMinutes)
        $stopwatch.Stop()
        if ($stopwatch.Elapsed.Minutes -ge $MaxSyncWaitMinutes) {
            Write-Log -Message 'Maximum Synchronization Wait Time Met or Exceeded' -EntryType Notification -ErrorLog
        }
        if ($Recipient.$RecipientAttributeToCheck -eq $RecipientAttributeValue) {
            Write-Log -Message "Checking $identity for value $RecipientAttributeValue in attribute $RecipientAttributeToCheck." -EntryType Succeeded
            Write-Output -InputObject $true
        }
        else {Write-Output -InputObject $false}
    }
    else {Write-Output -InputObject $false}
  }#Process
  End {}

    }
