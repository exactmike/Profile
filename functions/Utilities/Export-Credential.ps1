    Function Export-Credential {
        
    param(
        [string]$message
        ,
        [string]$username
    )
    if (-not $IsWindows) {
        throw [System.PlatformNotSupportedException]::new('Export-Credential requires Windows.')
    }
    $GetCredentialParams = @{}
    if ($message) {$GetCredentialParams.Message = $message}
    if ($username) {$GetCredentialParams.Username = $username}

    $credential = Get-Credential @GetCredentialParams

    $ExportUserName = $credential.UserName
    $ExportPassword = ConvertFrom-SecureString -Securestring $credential.Password

    $exportCredential = [pscustomobject]@{
        UserName = $ExportUserName
        Password = $ExportPassword
    }
    $exportCredential

    }
