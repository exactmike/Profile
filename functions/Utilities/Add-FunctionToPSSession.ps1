    Function Add-FunctionToPSSession {
        
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string[]]$FunctionNames
        ,
        [parameter(ParameterSetName = 'SessionID', Mandatory, ValuefromPipelineByPropertyName)]
        [int]$ID
        ,
        [parameter(ParameterSetName = 'SessionName', Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Name
        ,
        [parameter(ParameterSetName = 'SessionObject', Mandatory, ValueFromPipeline)]
        [Management.Automation.Runspaces.PSSession]$PSSession
        ,
        [switch]$Refresh
    )
    Write-Warning -Message "The Add-FunctionToPSSession should probably be updated to use AST for safer/more reliable operation.  Use with Caution." -Verbose
    #Find the session
    $GetPSSessionParams = @{
        ErrorAction = 'Stop'
    }
    switch ($PSCmdlet.ParameterSetName)
    {
        'SessionID'
        {
            $GetPSSessionParams.ID = $ID
            $PSSession = Get-PSSession @GetPSSessionParams
        }
        'SessionName'
        {
            $GetPSSessionParams.Name = $Name
            $PSSession = Get-PSSession @GetPSSessionParams
        }
        'SessionObject'
        {
            #nothing required here
        }
    }
    #Verify the session availability
    if (-not $PSSession.Availability -eq 'Available')
    {
        throw "Availability Status for PSSession $($PSSession.Name) is $($PSSession.Availability).  It must be Available."
    }
    #Verify if the functions already exist in the PSSession unless Refresh
    foreach ($FN in $FunctionNames)
    {
        $script = "Get-Command -Name '$FN' -ErrorAction SilentlyContinue"
        $scriptblock = [scriptblock]::Create($script)
        $remoteFunction = Invoke-Command -Session $PSSession -ScriptBlock $scriptblock -ErrorAction SilentlyContinue
        if ($null -ne $remoteFunction.CommandType -and -not $Refresh)
        {
            $FunctionNames = $FunctionNames | Where-Object -FilterScript {$_ -ne $FN}
        }
    }
    Write-Verbose -Message "Functions remaining: $($FunctionNames -join ',')"
    #Verify the local function availiability
    $Functions = @(
        foreach ($FN in $FunctionNames)
        {
            Get-Command -ErrorAction Stop -Name $FN -CommandType Function
        }
    )
    #build functions text to initialize in PsSession
    $FunctionsText = ''
    foreach ($Function in $Functions)
    {
        $FunctionText = 'function ' + $Function.Name + "`r`n {`r`n" + $Function.Definition + "`r`n}`r`n"
        $FunctionsText = $FunctionsText + $FunctionText
    }
    #convert functions text to scriptblock
    $ScriptBlock = [scriptblock]::Create($FunctionsText)
    Invoke-Command -Session $PSSession -ScriptBlock $ScriptBlock -ErrorAction Stop

    }
