Function Export-JSON
{
    [cmdletbinding()]
    param
    (
        [parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('PSPath', 'FullName')]
        [string]$FilePath
        ,
        [parameter()]
        [validateSet('Unicode', 'UTF7', 'UTF8', 'ASCII', 'UTF32', 'BigEndianUnicode', 'Default', 'OEM')]
        $Encoding
        ,
        [parameter(ValueFromPipeline)]
        [psobject]$InputObject
        ,
        [switch]$Compress
    )

    $ConvertParams = @{
        InputObject = $InputObject
        Compress    = $Compress
    }
    ConvertTo-Json @ConvertParams | Out-File -FilePath $FilePath -Encoding $Encoding



}
