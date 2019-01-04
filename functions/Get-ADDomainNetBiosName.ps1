    Function Get-ADDomainNetBiosName {
        
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline, Mandatory)]
        [string[]]$DNSRoot
    )
    #If necessary, create the script:ADDomainDNSRootToNetBiosNameHash
    if (-not (Test-Path variable:script:ADDomainDNSRootToNetBiosNameHash))
    {
        $script:ADDomainDNSRootToNetBiosNameHash = @{}
    }
    #Lookup the NetBIOSName for the domain in the script:ADDomainDNSRootToNetBiosNameHash
    if ($script:ADDomainDNSRootToNetBiosNameHash.containskey($DNSRoot))
    {
        $NetBiosName = $script:ADDomainDNSRootToNetBiosNameHash.$DNSRoot
    }
    #or lookup the NetBIOSName from AD and add it to the script:ADDomainDNSRootToNetBiosNameHash
    else
    {
        try
        {
            $message = "Look up $DNSRoot NetBIOSName for the first time."
            Write-Log -Message $message -EntryType Attempting
            $NetBiosName = Get-ADDomain -Identity $DNSRoot -ErrorAction Stop | Select-Object -ExpandProperty NetBIOSName
            $script:ADDomainDNSRootToNetBiosNameHash.$DNSRoot = $NetBiosName
            Write-Log -Message $message -EntryType Succeeded
        }
        catch
        {
            $myerror = $_
            Write-Log -Message $message -EntryType Failed -Verbose -ErrorLog
            Write-Log -Message $myerror.tostring() -ErrorLog
            $PSCmdlet.ThrowTerminatingError($myerror)
        }
    }
    #Return the NetBIOSName
    Write-Output $NetBiosName

    }
