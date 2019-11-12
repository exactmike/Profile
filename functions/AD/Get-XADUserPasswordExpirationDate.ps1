    Function Get-XADUserPasswordExpirationDate {
        

    Param ([Parameter(Mandatory, Position = 0, ValueFromPipeline, HelpMessage = 'Identity of the Account')]

        $accountIdentity)

    PROCESS
    {

        $accountObj = Get-ADUser -Identity $accountIdentity -Properties PasswordExpired, PasswordNeverExpires, PasswordLastSet

        if ($accountObj.PasswordExpired)
        {

            Write-Output -InputObject $('Password of account: ' + $accountObj.Name + ' already expired!')

        }
        else
        {

            if ($accountObj.PasswordNeverExpires)
            {

                Write-Output -InputObject $('Password of account: ' + $accountObj.Name + ' is set to never expires!')

            }
            else
            {

                $passwordSetDate = $accountObj.PasswordLastSet

                if ($passwordSetDate -eq $null)
                {

                    Write-Output -InputObject $('Password of account: ' + $accountObj.Name + ' has never been set!')

                }
                else
                {

                    $maxPasswordAgeTimeSpan = $null

                    $dfl = (get-addomain).DomainMode

                    if ($dfl -ge 3)
                    {

                        ## Greater than Windows2008 domain functional level

                        $accountFGPP = Get-ADUserResultantPasswordPolicy $accountObj

                        if ($accountFGPP -ne $null)
                        {

                            $maxPasswordAgeTimeSpan = $accountFGPP.MaxPasswordAge

                        }
                        else
                        {

                            $maxPasswordAgeTimeSpan = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge

                        }

                    }
                    else
                    {

                        $maxPasswordAgeTimeSpan = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge

                    }

                    if ($maxPasswordAgeTimeSpan -eq $null -or $maxPasswordAgeTimeSpan.TotalMilliseconds -eq 0)
                    {

                        Write-Output -InputObject $('MaxPasswordAge is not set for the domain or is set to zero!')

                    }
                    else
                    {

                        Write-Output -InputObject $('Password of account: ' + $accountObj.Name + ' expires on: ' + ($passwordSetDate + $maxPasswordAgeTimeSpan))

                    }

                }

            }

        }

    }


    }
