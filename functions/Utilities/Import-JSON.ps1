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
            Write-Verbose -Message "Processing path $f"
            $GetContentParams = @{
                Path = $f
                Raw  = $true
            }
            if ($null -ne $Encoding)
            {$GetContentParams.Encoding = $Encoding}
            try
            {
                $content = Get-Content @GetContentParams
            }
            catch
            {
                $_
            }
            if ($null -eq $content -or $content.Length -lt 1)
            {
                throw("No content found in file $f")
            }
            else
            {
                ConvertFrom-Json -InputObject $content
            }
        }
    }
    end
    {

    }

}
