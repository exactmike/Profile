
<#PSScriptInfo
.VERSION 0.1.0
.GUID ebf6eee6-612c-4dd4-a577-a3e66c48a447
.AUTHOR ThatExactMike
.COMPANYNAME Exact Solutions
.COPYRIGHT 2019
.TAGS Security Passwords
.LICENSEURI https://raw.githubusercontent.com/exactmike/Profile/master/license
.PROJECTURI https://github.com/exactmike/Profile/blob/master/functions/Test-ForPwnedPassword.ps1
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
.PRIVATEDATA
.DESCRIPTION
 Connects to the API at https://api.pwnedpasswords.com/ and sends the first 5 characters of the password's SHA1 hash to see if the password has been found in a breach.
#>
<#
.SYNOPSIS
Connects to the API at https://api.pwnedpasswords.com/ and sends the first 5 characters of the password's SHA1 hash to see if the password has been found in a breach.

.DESCRIPTION
Connects to the API at https://api.pwnedpasswords.com/ and sends the first 5 characters of the password's SHA1 hash to see if the password has been found in a breach.

Additional information about the API is available here: https://haveibeenpwned.com/API/v2#PwnedPasswords.
WARNING: Be aware that when using this function with the password parameter set the password submitted is accessed in memory as a plain text string on the local machine where this function is run.
If you wish to avoid this, use the Hash parameter / parameter set providing your own SHA1 hash of any password(s) you wish to test against the API.

.PARAMETER Password
A secure string version of the password you wish to test. There are many ways to obtain a SecureString, for example, Get-Credential, ConvertTo-SecureString, or Read-Host (as shown in one of the examples).
If no value is provided for this parameter and the hash parameter is not used PowerShell will prompt for a value.
NOTE: If you are running this function in a remote session on a non-windows machine you must provide a value for the Password parameter rather than letting the function prompt you for a value.  This is because SecureString cannot be passed between local and remote on non-windows systems at this time.

.PARAMETER Hash
A SHA1 hash of the password you wish to test.

.EXAMPLE
$Password = Read-Host -AsSecureString
Test-ForPwnedPassword -Password $Password

True

Tests the password hash for the submitted password to see if it is present in the API's data set as a breached password.

.EXAMPLE
Test-ForPwnedPassword -Hash 9cd277f71f1a9d77eccb441836bdea6f1b5c2685

Tests the password hash for the password 'Micro$oft' to see if it is present in the API's data set as a breached password.

.EXAMPLE
Test-ForPwnedPassword

Prompts for a password and tests the password hash to see if it is present in the API's data set as a breached password.

.NOTES
    AUTHOR : Mike Campbell
    DATE : 2019-04-05
    Version: 0.1.0

    Adapted from the work of https://sqldbawithabeard.com/2017/08/09/using-powershell-to-check-if-your-password-has-been-in-a-breach/
    Indebted to @TroyHunt on Twitter for the services hosted at https://haveibeenpwned.com/
#>
function Test-ForPwnedPassword
{
    [CmdletBinding(DefaultParameterSetName = 'Password')]
    Param
    (
        [Parameter(Mandatory,ValueFromPipeline,ParameterSetName = 'Password')]
        [ValidateNotNullOrEmpty()]
        [SecureString]$Password
        ,
        [Parameter(Mandatory,ValueFromPipeline,ParameterSetName = 'Hash')]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(5,[int]::MaxValue)]
        [String]$Hash
        ,
        [Parameter()]
        [switch]$IncludeInstanceCount
    )
    begin
    {
        Function Get-StringHash
        {
            param(
                [parameter(Position = 1, ValueFromPipeline)]
                [String]$String
                ,
                [parameter()]
                [ValidateSet('MD5','SHA1','SHA256','SHA384','SHA512')]
                $AlgorithmName = "SHA1"
            )
            Begin
            {
                $hashAlgorithm = [System.Security.Cryptography.HashAlgorithm]::Create($AlgorithmName)
            }
            Process
            {
                $md5StringBuilder = [System.Text.StringBuilder]::new()
                $ue = [System.Text.UTF8Encoding]::new()
                $hashAlgorithm.ComputeHash($ue.GetBytes($String)).foreach({[void] $md5StringBuilder.Append($_.ToString("x2"))})
                $md5StringBuilder.ToString()
            }
        }
    }
    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'Password'
            {
                $TempCred = [system.management.automation.pscredential]::new('User',$Password)
                $Private:pass = $TempCred.GetNetworkCredential().Password
                $Hash = Get-StringHash -AlgorithmName SHA1 -String $Private:pass
                $Private:pass = $null
                Remove-Variable -Name pass -Force -Scope Private
            }
            Default
            {}
        }
        $HashPrefix = $Hash.Substring(0,5)
        $URI = 'https://api.pwnedpasswords.com/range/' + $HashPrefix
        #Force TLS 1.2
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        try
        {
            $Response = Invoke-RestMethod -Uri $URI
        }
        catch
        {
            Throw($_)
        }
        $Match = $(
            $Response.split("`n").foreach(
                {
                    [PSCustomObject]@{
                        Hash = [string]$HashPrefix + [string]$($_.split(':')[0])
                        InstanceCount = $($_.split(':')[1]).trim()
                    }
                }
            ).where({$_.Hash -eq $Hash})
        )
        switch ($null -eq $Match)
        {
            #if Match is $null then the password was NOT found via the API
            $true
            {
                switch ($true -eq $IncludeInstanceCount)
                {
                    $true
                    {
                        [PSCustomObject]@{
                            FoundInPwnedPasswordsAPI = $false
                            InstanceCount = 0
                        }
                    }
                    $false
                    {
                        $false
                    }
                }
            }
            #if Match is not $null then the password WAS found via the API
            $false
            {
                switch ($true -eq $IncludeInstanceCount)
                {
                    $true
                    {
                        [PSCustomObject]@{
                            FoundInPwnedPasswordsAPI = $true
                            InstanceCount = $Match.InstanceCount
                        }
                    }
                    $false
                    {
                        $true
                    }
                }
            }
        }
    }
}
