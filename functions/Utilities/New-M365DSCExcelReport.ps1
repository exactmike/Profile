function New-M365DSCExcelReport
{
    param
    (
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path -Path $_ -Type Leaf})]
        [System.String]
        $ConfigurationPath
        ,
        [Parameter()]
        [Switch]
        $IncludeComments
        ,
        [Parameter(Mandatory)]
        [System.String]
        [ValidateScript({Test-Path -Path $_ -Type Container})]
        $OutputFolderPath
    )


    Write-Verbose -Message "Loading file '$ConfigurationPath'"

    $fileContent = Get-Content $ConfigurationPath -Raw
    try
    {
        $startPosition = $fileContent.IndexOf(' -ModuleVersion')
        if ($startPosition -gt 0)
        {
            $endPosition = $fileContent.IndexOf("`r", $startPosition)
            $fileContent = $fileContent.Remove($startPosition, $endPosition - $startPosition)
        }
    }
    catch
    {
        Write-Verbose 'Error trying to remove Module Version'
    }

    if ($IncludeComments)
    {
        $parsedContent = ConvertTo-DSCObject -Content $fileContent -IncludeComments:$True
    }
    else
    {
        $parsedContent = ConvertTo-DSCObject -Content $fileContent
    }

    Write-Verbose -Message 'Convert DSC Objects (Ordered Dictionary) to PowerShell Objects'

    $parsedObjects = $parsedContent.foreach({New-Object -TypeName psobject -Property $_}) | Select-Object -Property * -ExcludeProperty Credential

    $groupedParsedObjects = @(
        $parsedObjects.foreach({
                $Current = $_
                switch -Wildcard ($Current.Resourcename)
                {
                    'AAD*'
                    {
                        $Current | Select-Object -Property *, @{n = 'ResourceGroup'; e={'Tenant'}}
                    }
                    'O365*'
                    {
                        $Current | Select-Object -Property *, @{n = 'ResourceGroup'; e={'Tenant'}}
                    }
                    'EXODataClassification'
                    {
                        $Current | Select-Object -Property *, @{n = 'ResourceGroup'; e={'Purview'}}
                        Break
                    }

                    'EXO*'
                    {
                        $Current | Select-Object -Property *, @{n = 'ResourceGroup'; e={'ExchangeOnline'}}
                    }
                    'SC*'
                    {
                        $Current | Select-Object -Property *, @{n = 'ResourceGroup'; e={'Purview'}}
                    }
                    'PPTenantIsolationSettings'
                    {
                        $Current | Select-Object -Property *, @{n = 'ResourceGroup'; e={'Tenant'}}
                    }
                    'SPO*'
                    {
                        $Current | Select-Object -Property *, @{n = 'ResourceGroup'; e={'SharePointOnline'}}
                    }
                    'ODSettings'
                    {
                        $Current | Select-Object -Property *, @{n = 'ResourceGroup'; e={'SharePointOnline'}}
                    }
                    'Teams*'
                    {
                        $Current | Select-Object -Property *, @{n = 'ResourceGroup'; e={'MicrosoftTeams'}}
                    }
                }
            })
    )

    $toReport =  @($groupedParsedObjects | Group-Object 'ResourceGroup')
    $exportParams = @{
        TableStyle = 'Medium18'
        AutoSize   = $true
    }

    $toReport.foreach({
            $dateStamp = Get-Date -Format 'yyyyMMddHHmm'
            $fileName = $($_.Name) + 'Config' + $dateStamp + '.xlsx'
            $exportParams.Path = Join-Path -Path $OutputFolderPath -ChildPath $fileName
            $resourceNameGroups = $_.Group | Group-Object ResourceName
            $resourceNameGroups.foreach({
                    $exportParams.WorksheetName = $_.Name
                    $mvProperties = $_.Group[0].psobject.Properties.where({$_.TypeNameOfValue -like '*`[`]'}).Name
                    $scalarProperties = $_.Group[0].psobject.Properties.where({$_.TypeNameOfValue -notlike '*`[`]'}).Name
                    $propertySet = Get-CSVExportPropertySet -MultiValuedAttributes $mvProperties -ScalarAttributes $scalarProperties
                    $_.Group | Select-Object -Property $propertySet | Export-Excel @ExportParams
                })
        })
}