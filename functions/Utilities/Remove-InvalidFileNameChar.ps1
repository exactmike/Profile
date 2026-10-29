# Original Source - https://stackoverflow.com/a/23067832
# Posted by Ansgar Wiechers, modified by community. See post 'Timeline' for change history
# Retrieved 2026-09-04, License - CC BY-SA 3.0

function Remove-InvalidFileNameChar {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [String]$Name
    )

    $invalidChars = [IO.Path]::GetInvalidFileNameChars() -join ''
    $re = '[{0}]' -f [RegEx]::Escape($invalidChars)
    ($Name -replace $re)
}
