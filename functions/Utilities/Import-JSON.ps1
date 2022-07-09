Function Import-JSON
{
    [cmdletbinding()]
    param
    (
        [parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('PSPath', 'FullName')]
        [ValidateScript( {Test-Path -Path $_})]
        [string[]]$FilePath
        ,
        [parameter()]
        [validateSet('Unicode', 'UTF7', 'UTF8', 'ASCII', 'UTF32', 'BigEndianUnicode', 'Default', 'OEM')]
        $Encoding
    )
    begin
    {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }
    process
    {
        foreach ($f in $FilePath)
        {
            $GetContentParams = @{
                Path = $f
                Raw  = $true
            }
            if ($null -ne $Encoding)
            {$GetContentParams.Encoding = $Encoding}
            try
            {
                $Content = Get-Content @GetContentParams
            }
            catch
            {
                $_
            }
            if ($null -eq $content -or $content.Length -lt 1)
            {
                throw("No content found in file $Path")
            }
            else
            {
                ConvertFrom-Json -InputObject $Content
            }
        }
    }
    end
    {

    }

}
