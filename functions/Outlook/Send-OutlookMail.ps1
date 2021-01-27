Function Send-OutlookMail
{
    [cmdletbinding()]
    param(
        [parameter()]
        [string]$Subject
        ,
        [parameter()]
        $Body
        ,
        [parameter()]
        [switch]$BodyAsHtml
        ,
        [parameter()]
        [string[]]$Attachment
        ,
        [parameter()]
        [string[]]$To
        ,
        [parameter()]
        [string[]]$BCC
        ,
        [parameter()]
        [string[]]$CC
        ,
        [parameter()]
        [alias('SendOnBehalf')]
        [string]$SendAS #the Actual 'Send As' or 'SendOnBehalf' will depend on the permissions held by the sending account.
        ,
        [parameter()]
        [validateset('Normal', 'High', 'Low')]
        [string]$Priority
    )
    Begin
    {
        try
        {
            $outlook = [Runtime.Interopservices.Marshal]::GetActiveObject('Outlook.Application')
            $script:outlookWasAlreadyRunning = $true
        }
        catch
        {
            try
            {
                $Outlook = New-Object -ComObject Outlook.Application
                $script:outlookWasAlreadyRunning = $false
            }
            catch
            {
                Write-Error "You must exit Outlook first."
            }
        }
    }
    Process
    {
        $Mail = $Outlook.CreateItem(0)
        $To.ForEach( {
                $null = $Mail.Recipients.add($_)
            })
        $CC.ForEach( {
                $Recip = $Mail.Recipients.add($_)
                $Recip.Type = 2
            })
        $BCC.ForEach( {
                $Recip = $Mail.Recipients.add($_)
                $Recip.Type = 3
            })
        $Mail.Subject = $Subject
        switch ($BodyAsHtml)
        {
            $true
            {
                $Mail.htmlBody = $Body
            }
            $false
            {
                $mail.Body = $Body
            }
        }
        $attachment.foreach( {
                $a = $Mail.Attachments.add($_)
                $filename = Split-Path -Path $_ -Leaf
                $a.PropertyAccessor.SetProperty("http://schemas.microsoft.com/mapi/proptag/0x3712001F", $filename)
            })

        if ($PSBoundParameters.ContainsKey('Priority'))
        {
            switch ($Priority)
            {
                'Normal'
                { $Mail.Importance = 1 }
                'High'
                { $Mail.Importance = 2 }
                'Low'
                { $Mail.Importance = 0 }
            }
        }
        if (-not [string]::IsNullOrWhiteSpace($SendAs))
        {
            $mail.SentOnBehalfOfName = $SendAs
        }

        $Mail.Send()
    }
    End
    {
        #if ($outlookWasAlreadyRunning -eq $false)
        #{
        #    $Outlook.Quit()
        #}
        #$null = [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Outlook)
        #$Outlook = $null
    }
}