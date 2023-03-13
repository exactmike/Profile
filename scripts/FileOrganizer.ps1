function Add-MediaFileDateTaken
{
    [cmdletbinding()]
    param(
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        [string[]]$FilePath
    )
    begin
    {
        $ShellExp = New-Object -ComObject Shell.Application
    }
    process
    {
        foreach ($i in $FilePath)
        {
            $item = Get-Item -Path $i
            $itemdirectory = $ShellExp.NameSpace($item.DirectoryName)
            $itemfile = $itemdirectory.ParseName($item.name)
            $datetaken = $null
            switch ($item.Extension)
            {
                '.mov'
                {
                    $datetakenstring = ($itemdirectory.GetDetailsOf($itemfile, 208) -replace "`u{200e}") -replace "`u{200f}"
                }
                '.avi'
                {
                    $datetakenstring = ($itemdirectory.GetDetailsOf($itemfile, 208) -replace "`u{200e}") -replace "`u{200f}"
                }
                '.jpg'
                {
                    $datetakenstring = ($itemdirectory.GetDetailsOf($itemfile, 12) -replace "`u{200e}") -replace "`u{200f}"
                }
            }

            if (-not [string]::IsNullOrEmpty($datetakenstring))
            {$dateTaken = $datetakenstring | Get-Date}
            Add-Member -InputObject $item -MemberType NoteProperty -Name DateTaken -Value $Datetaken -TypeName datetime -PassThru
        }
    }

}
function Optimize-Directory
{
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [ValidateScript({Test-Path -Path $_ -PathType container })]
        [string]$SourceDirectoryPath
        ,
        [ValidateScript({Test-Path -Path $_ -PathType container })]
        [string]$TargetDirectoryPath
        ,
        [parameter(Mandatory)]
        [validateset('YearMonth')]
        [string]$Optimization
        ,
        [validateset('dateTaken','LastWriteTime')]
        [string[]]$dateProperty
        ,
        [switch]$DeleteSourceDirectory
        ,
        [switch]$RecurseSourceDirectory
        <#         ,
        [switch]$outputItems
        #>
    )

    $SourceDirectoryPath = $(Get-Item -Path $SourceDirectoryPath).FullName
    Write-Verbose -Message "Source Directory Path: $SourceDirectoryPath"
    Write-Verbose -Message "Target Directory Path: $TargetDirectoryPath"

    $gciParams = @{
        Path    = $SourceDirectoryPath
        File    = $true
        Recurse = $RecurseSourceDirectory
    }

    $items = @(Get-ChildItem @gciParams)

    switch ($dateProperty)
    {
        'dateTaken' # Get the dateTaken value and add it to the object as a new attribute
        {
            $items = @(Add-MediaFileDateTaken -FilePath $items.FullName)
            $ItemsToProcess = @($items.where({$null -ne $_.DateTaken}))
            $ItemsWithNullDateTaken = @($items.where({$null -eq $_.DateTaken}))
            if ($ItemsWithDateTaken.count -lt $items.count)
            {
                Write-Warning -Message "Out of $($items.count) total items, $($ItemsWithNullDateTaken.count) do not have a valid DateTaken value and will not be processed."
            }
        }
        'LastWriteTime'
        {
            $ItemsToProcess = $items
        }
    }

    switch ($Optimization)
    {
        'YearMonth'
        {
            switch ($dateProperty)
            {
                'dateTaken'
                {
                    $years = @($ItemsToProcess | Group-Object -Property @{e = {if ($null -eq $_.DateTaken) {$_.LastWriteTime.Year} else {$_.DateTaken.Year}}})
                    $YearMonthGroups = @{}
                    foreach ($y in $years)
                    {
                        $YearMonthGroups.$($y.Name)=@(
                            $y.Group | Group-Object -Property @{e = {if ($null -eq $_.DateTaken) {$_.LastWriteTime.Month.tostring('00')} else {$_.DateTaken.Month.tostring('00')}}} -NoElement | Select-Object -ExpandProperty Name
                        )
                    }
                }
                'LastWriteTime'
                {
                    $years = @($ItemsToProcess | Group-Object -Property @{e = {$_.LastWriteTime.Year}})
                    $YearMonthGroups = @{}
                    foreach ($y in $years)
                    {
                        $YearMonthGroups.$($y.Name)=@(
                            $y.Group | Group-Object -Property @{e = {$_.LastWriteTime.Month.tostring('00')}} -NoElement | Select-Object -ExpandProperty Name
                        )
                    }
                }
            }

            $PathsRequired = foreach ($key in $YearMonthGroups.Keys)
            {
                $Path = Join-Path -Path $TargetDirectoryPath -ChildPath $key
                $Path
                foreach ($v in $YearMonthGroups.$key)
                {
                    Join-Path -Path $Path -ChildPath $v
                }
            }
            # Return $YearMonthGroups


            Write-Verbose -Message "Count of Paths Required: $($PathsRequired.count)"
            Write-Verbose -Message $($PathsRequired -join ';')

            # Create Directories in Target

            $TargetDirectories = Get-ChildItem -Path $TargetDirectoryPath -Directory -Recurse
            $PathsNotExisting = @($PathsRequired.where({$_ -notin $TargetDirectories.FullName}))

            Write-Verbose -Message "Count of Paths Required But Not Existing: $($PathsNotExisting.count)"
            Write-Verbose -Message $($PathsNotExisting -join ';')

            foreach ($p in $PathsNotExisting)
            {
                Write-Verbose -Message "Create Path $p"
                $null = New-Item -Path $p -ItemType Directory
            }

            # Prepare to Move Items to Directories

            $itemsToMove = @(
                foreach ($i in $ItemsToProcess)
                {
                    switch ($dateProperty)
                    {
                        'dateTaken'
                        {
                            $newName = $i.DateTaken.ToString('yyyyMMddmmss') + '-' + $i.Name
                            $TargetItemPath = Join-Path $TargetDirectoryPath -ChildPath $($i.DateTaken.Year) -AdditionalChildPath $($i.DateTaken.Month.ToString('00')),$($newName)
                        }
                        'LastWriteTime'
                        {
                            $newName = $i.LastWriteTime.ToString('yyyyMMddmmss') + '-' + $i.Name
                            $TargetItemPath = Join-Path $TargetDirectoryPath -ChildPath $($i.LastWriteTime.Year) -AdditionalChildPath $($i.LastWriteTime.Month.ToString('00')),$($newName)
                        }
                    }

                    $i | Add-Member -MemberType NoteProperty -Name TargetItemPath -Value $TargetItemPath -PassThru
                }
            )

            if ($itemsToMove.count -ge 1)
            {
                Write-Information -MessageData "Count of Items to Move:  $($itemsToMove.Count)"
                Write-Information -MessageData $($ItemsToMove.TargetItemPath -join ' | ')
            }
            else {Write-Information -MessageData "There are 0 Items to Move"}


            # Move Items to Directories
            $MoveErrorsDetected = $false
            $MoveErrors = [System.Collections.ArrayList]::new()


            foreach ($i in $itemsToMove)
            {
                Write-Verbose "Moving Item $($i.fullname) to $($i.TargetItemPath)"
                try
                {
                    Move-Item -Path $i.FullName -Destination $i.TargetItemPath -ErrorAction Stop
                }
                catch
                {
                    [void]$MoveErrors.Add($_)
                }
            }

            if ($MoveErrors.count -ge 1)
            {
                $MoveErrorsDetected = $true
                Set-Variable -Scope Global -Name MoveErrors -Value $MoveErrors
                Write-Warning -Message 'Move Errors Detected.  Review $MoveErrors variable.' -Verbose
            }

            #Delete Source Directory?
            if ($false -eq $MoveErrorsDetected -and $DeleteSourceDirectory)
            {
                $ItemsInSourceDirectoryPath = @(Get-ChildItem -Path $SourceDirectoryPath -Recurse -File)
                if ($ItemsInSourceDirectoryPath.Count -eq 0)
                {
                    Remove-Item -Path $SourceDirectoryPath -Recurse
                }
                else
                {
                    Write-Warning -Message "Source Directory $sourceDirectoryPath is not empty.  Removal of directory skipped."
                }
            }
        }
    }
}