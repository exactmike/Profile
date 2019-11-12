    Function Export-ADSyncConnectorChanges {
        
    [cmdletbinding()]
    param
    (
        $commandfolderpath = 'D:\Program Files\Microsoft Azure AD Sync\Bin'
        ,
        [parameter()]
        $tempFileStorageFolder = 'D:\Temp'
        ,
        [parameter(Mandatory)]
        #[validateSet(#make dynamic parameter)]
        [string]$connector
        ,
        [parameter()]
        [validateSet('Disconnectors','ImportErrors','ExportErrors','PendingImports','PendingExports')]
        [string]$ChangeType
        ,
        $OutputFileName
    )

    $firstcommand = 'csexport.exe'
    $firstcommandfullpath = Join-Path $commandfolderpath $firstcommand
    $xmlfilePath = Join-Path -Path $tempFileStorageFolder -ChildPath ([IO.Path]::GetRandomFileName())
    $filterString = $(
        switch ($ChangeType)
        {
            'Disconnectors'
            {"/f:s"}
            'ImportErrors'
            {"/f:i"}
            'ExportErrors'
            {"/f:e"}
            'PendingImports'
            {"/f:m"}
            'PendingExports'
            {"/f:x"}
        }
    )
    $SecondCommand = 'CSExportAnalyzer.exe'
    $SecondCommandFullPath = Join-Path -Path $commandfolderpath $SecondCommand
    $OutputFileFullPath = Join-Path $tempFileStorageFolder $OutputFileName
    $SecondCommandFullString = "'"
    #Run First Command
    & $firstcommandfullpath $connector $xmlfilepath $filterstring
    #Run Second Command
    & $SecondCommandFullPath $xmlfilePath > $OutputFileFullPath
    Remove-Item $xmlfilePath -Force
    Write-Verbose -Message "output file: $OutputFileFullPath" -Verbose 

    }
