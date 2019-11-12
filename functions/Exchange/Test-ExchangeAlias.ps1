    Function Test-ExchangeAlias {
        
    [cmdletbinding()]
    param(
        [string]$Alias
        ,
        [string[]]$ExemptObjectGUIDs
        ,
        [switch]$ReturnConflicts
        ,
        [parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession]$ExchangeSession
    )

    #Test the Alias
    $ReturnedObjects = @(
        try
        {
            invoke-command -Session $ExchangeSession -ScriptBlock {Get-Recipient -identity $using:Alias -ErrorAction Stop} -ErrorAction Stop
            Write-Verbose -Message "Existing object(s) Found for Alias $Alias"
        }
        catch
        {
            if ($_.categoryinfo -like '*ManagementObjectNotFoundException*')
            {
                Write-Verbose -Message "No existing object(s) Found for Alias $Alias"
            }
            else
            {
                throw($_)
            }
        }
    )
    if ($ReturnedObjects.Count -ge 1)
    {
        $ConflictingGUIDs = @($ReturnedObjects | ForEach-Object {$_.guid.guid} | Where-Object {$_ -notin $ExemptObjectGUIDs})
        if ($ConflictingGUIDs.count -gt 0)
        {
            if ($ReturnConflicts)
            {
                Return $ConflictingGUIDs
            }
            else
            {
                $false
            }
        }
        else
        {
            $true
        }
    }
    else
    {
        $true
    }

    }
