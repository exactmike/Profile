Function Get-FileChecksum
{

    Param (
        [parameter(Mandatory = $True)]
        [ValidateScript( { Test-Path -path $_ -PathType Leaf })]
        [string]$Path
        ,
        [ValidateSet('sha1', 'md5', 'sha512')]
        [string]$Algorithm
    )
    $FileObject = Get-Item -Path $Path
    $fs = [System.IO.FileStream]::new($($FileObject.FullName), 'Open' )
    $algo = [type]"System.Security.Cryptography.$Algorithm"
    $crypto = $algo::Create()
    $hash = [BitConverter]::ToString($crypto.ComputeHash($fs)).Replace('-', '')
    $fs.Close()
    $hash

}
