    Function Convert-SecureStringToString {
        
    <#
            .SYNOPSIS
            Decrypts System.Security.SecureString object that were created by the user running the function.  Does NOT decrypt SecureString Objects created by another user.
            .DESCRIPTION
            Decrypts System.Security.SecureString object that were created by the user running the function.  Does NOT decrypt SecureString Objects created by another user.
            .PARAMETER SecureString
            Required parameter accepts a System.Security.SecureString object from the pipeline or by direct usage of the parameter.  Accepts multiple inputs.
            .EXAMPLE
            Decrypt-SecureString -SecureString $SecureString
            .EXAMPLE
            $SecureString1,$SecureString2 | Decrypt-SecureString
            .LINK
            This function is based on the code found at the following location:
            http://blogs.msdn.com/b/timid/archive/2009/09/09/powershell-one-liner-decrypt-securestring.aspx
            .INPUTS
            System.Security.SecureString
            .OUTPUTS
            System.String
        #>

    [cmdletbinding()]
    param (
        [parameter(ValueFromPipeline = $True)]
        [securestring[]]$SecureString
    )

    BEGIN {}
    PROCESS
    {
        foreach ($ss in $SecureString)
        {
            if ($ss -is 'SecureString')
            {[Runtime.InteropServices.marshal]::PtrToStringAuto([Runtime.InteropServices.marshal]::SecureStringToBSTR($ss))}
        }
    }
    END {}

    }
