    Function Get-Checksum {
        
    Param (
        [parameter(Mandatory = $True)]
        [ValidateScript( {Test-Path -path $_ -PathType Leaf})]
        [string]$File
        ,
        [ValidateSet('sha1', 'md5')]
        [string]$Algorithm = 'sha1'
    )
    $FileObject = Get-Item -Path $File
    $fs = new-object System.IO.FileStream $($FileObject.FullName), 'Open'
    $algo = [type]"System.Security.Cryptography.$Algorithm"
    $crypto = $algo::Create()
    $hash = [BitConverter]::ToString($crypto.ComputeHash($fs)).Replace('-', '')
    $fs.Close()
    $hash

    }
