Function Get-StringHash
{
<#
.SYNOPSIS
    Gets the hash value of a string

.DESCRIPTION
    Gets the hash value of a string

.PARAMETER String
    String to get the hash from

.PARAMETER AlgorithmName
    Type of hash algorithm to use. Default is SHA1

.EXAMPLE
    C:\PS> Get-StringHash "This is my string"
    Gets the SHA1 hash of the string

.EXAMPLE
    C:\PS> Get-StringHash -AlgorithmName "MD5" -String "This is my string"
    Gets the MD5 hash of the string

.EXAMPLE
    C:\PS> "This is my string" | Get-StringHash
    We can pass a string throught the pipeline

.EXAMPLE
    Get-Content "c:\temp\hello_world.txt" | Get-StringHash

.NOTE
    Adapted by ThatExactMike (https://www.thatexactmike.com) from http://dbadailystuff.com/2013/03/11/get-hash-a-powershell-hash-function/ with the intent of only providing string hashing functionality since Get-FileHash is now a native cmdlet in Microsoft.PowerShell.Utility
#>
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
        $md5StringBuilder = New-Object System.Text.StringBuilder
        $ue = New-Object System.Text.UTF8Encoding
        $hashAlgorithm.ComputeHash($ue.GetBytes($String)) | ForEach-Object { [void] $md5StringBuilder.Append($_.ToString("x2")) }
        $md5StringBuilder.ToString()
    }
}
