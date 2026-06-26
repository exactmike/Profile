
function Optimize-Directory {
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -Path $_ -PathType container })]
        [string]$SourceDirectoryPath
        ,
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -Path $_ -PathType container })]
        [string]$TargetDirectoryPath
        ,
        [Parameter(Mandatory)]
        [ValidateSet('YearMonth')]
        [string]$Optimization
        ,
        [Parameter(Mandatory)]
        [ValidateSet('dateTaken', 'LastWriteTime')]
        [String]$DateProperty
        ,
        [switch]$DeleteSourceDirectory
        ,
        [switch]$RecurseSourceDirectory
        <#
        [switch]$outputItems
        #>
    )

    $SourceDirectoryPath = $(Get-Item -Path $SourceDirectoryPath).FullName
    Write-Information -Message "Source Directory Path: $SourceDirectoryPath"
    Write-Information -Message "Target Directory Path: $TargetDirectoryPath"

    $gciParams = @{
        Path    = $SourceDirectoryPath
        File    = $true
        Recurse = $RecurseSourceDirectory
    }

    $items = Get-ChildItem @gciParams
    Write-Information -MessageData "Found $($items.count) items in $SourceDirectoryPath"

    switch ($DateProperty) {
        'dateTaken' {
            $items = @(Add-MediaFileDateTakenAttribute -FilePath $items.FullName)
            $itemsWithDateTaken = @($items.where({ $null -ne $_.DateTaken }))
            $itemsWithNullDateTaken = @($items.where({ $null -eq $_.DateTaken }))
            if ($ItemsWithDateTaken.count -lt $items.count) {
                $message = "Skipping $($itemsWithNullDateTaken.count) out of $($items.count).  These have a null DateTaken attribute."
                Write-Information -Message $message
            }
        }
    }

    switch ($Optimization) {
        'YearMonth' {

            $itemsToProcessForOptimization = @(
                switch ($DateProperty) {
                    'dateTaken' {
                        $itemsWithDateTaken
                    }
                    'LastWriteTime' {
                        $items
                    }
                }
            )

            $years = @($itemsToProcessForOptimization |
                    Group-Object -Property @{e = { if ($null -eq $_.DateTaken) { $_.LastWriteTime.Year } else { $_.DateTaken.Year } } })

            $yearMonthGroups = @{}
            foreach ($y in $years) {
                $yearMonthGroups.$($y.Name) = @(
                    $y.Group |
                        Group-Object -Property @{e = { if ($null -eq $_.DateTaken) { $_.LastWriteTime.Month.tostring('00') } else { $_.DateTaken.Month.tostring('00') } } } -NoElement |
                        Select-Object -ExpandProperty Name
                )
            }

            $pathsRequired = foreach ($key in $yearMonthGroups.Keys) {
                $yearPath = Join-Path -Path $TargetDirectoryPath -ChildPath $key
                Write-Information -MessageData "Identified Required Path for Year $key : $yearPath"
                $yearPath
                foreach ($v in $YearMonthGroups.$key) {
                    $monthPath = Join-Path -Path $yearPath -ChildPath $v
                    Write-Information -MessageData "Identified Required Path for Month $v : $monthPath"
                    $monthPath
                }
            }

            Write-Information -MessageData "Count of Paths Required: $($PathsRequired.count)"
            Write-Information -MessageData $($PathsRequired -join ';')

            # Create Directories in Target

            $currentTargetDirectories = Get-ChildItem -Path $TargetDirectoryPath -Directory -Recurse | Group-Object -AsHashTable -Property FullName -AsString
            if ($null -eq $currentTargetDirectories) { $currentTargetDirectories = @{} }
            $pathsNotExisting = @($pathsRequired.where({ -not $currentTargetDirectories.ContainsKey($_) }))

            Write-Information -MessageData "Count of Paths Required But Not Existing: $($pathsNotExisting.count)"
            Write-Information -MessageData $($pathsNotExisting -join ';')

            foreach ($p in $pathsNotExisting) {
                try {
                    if ($PSCmdlet.ShouldProcess($p, 'New-Item')) {
                        Write-Information -MessageData "Create Path $p"
                        $null = New-Item -Path $p -ItemType Directory
                    }
                } catch {

                }
            }
        }
    }


    $itemsToMove = @(
        foreach ($i in $itemsToProcessForOptimization) {
            $newName = $i.$($DateProperty).ToString('yyyyMMddmmss') + '-' + $i.Name
            $targetItemPath = Join-Path $TargetDirectoryPath -ChildPath $($i.$($DateProperty).Year) -AdditionalChildPath $($i.$($DateProperty).Month.ToString('00')), $($newName)
            $i | Add-Member -MemberType NoteProperty -Name TargetItemPath -Value $TargetItemPath -PassThru
        })

    # Move Items to Directories
    $moveErrorsDetected = $false
    $moveErrors = New-GenericList

    foreach ($i in $itemsToMove) {
        try {
            $message = "Moving Item $($i.fullname) to $($i.TargetItemPath) with Move-Item"
            if ($PSCmdlet.ShouldProcess($message, $i.FullName, 'Move-Item')) {
                Write-Information -MessageData $message
                Move-Item -Path $i.FullName -Destination $i.TargetItemPath -ErrorAction Stop
            }
        } catch {
            $moveErrors.Add($_)
        }
    }

    if ($moveErrors.count -ge 1) {
        $moveErrorsDetected = $true
        Set-Variable -Scope Global -Name moveErrors -Value $moveErrors
        Write-Warning -Message 'Move Errors Detected.  Review $moveErrors variable.' -Verbose
    }

    #Delete Source Directory?
    if ($false -eq $MoveErrorsDetected -and $DeleteSourceDirectory) {
        $ItemsInSourceDirectoryPath = @(Get-ChildItem -Path $SourceDirectoryPath -Recurse -File)
        if ($ItemsInSourceDirectoryPath.Count -eq 0) {
            Remove-Item -Path $SourceDirectoryPath -Recurse
        } else {
            Write-Warning -Message "Source Directory $sourceDirectoryPath is not empty.  Removal of directory skipped."
        }
    }

}