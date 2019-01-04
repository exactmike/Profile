    Function Read-Choice {
        
    [cmdletbinding()]
    param(
        [string]$Title = [string]::Empty
        ,
        [string]$Message
        ,
        [Parameter(Mandatory, ParameterSetName = 'StringChoices')]
        [ValidateNotNullOrEmpty()]
        [alias('StringChoices')]
        [String[]]$Choices
        ,
        [Parameter(Mandatory, ParameterSetName = 'ObjectChoices')]
        [ValidateNotNullOrEmpty()]
        [alias('ObjectChoices')]
        [psobject[]]$ChoiceObjects
        ,
        [int]$DefaultChoice = -1
        ,
        [Parameter(ParameterSetName = 'StringChoices')]
        [switch]$Numbered
        ,
        [switch]$Vertical
        ,
        [switch]$ReturnChoice
    )
    #Region ProcessChoices
    #Prepare the PossibleChoices objects
    switch ($PSCmdlet.ParameterSetName)
    {
        'StringChoices'
        #Create the Choice Objects
        {
            if ($Numbered)
            {
                $choiceCount = 0
                $ChoiceObjects = @(
                    foreach ($choice in $Choices)
                    {
                        $choiceCount++
                        [PSCustomObject]@{
                            Enumerator = $choiceCount
                            Choice     = $choice
                        }
                    }
                )
            }
            else
            {
                [char[]]$choiceEnumerators = @()
                $ChoiceObjects = @(
                    foreach ($choice in $Choices)
                    {
                        $Enumerator = $null
                        foreach ($char in $choice.ToCharArray())
                        {
                            if ($char -notin $choiceEnumerators -and $char -match '[a-zA-Z]' )
                            {
                                $Enumerator = $char
                                $choiceEnumerators += $Enumerator
                                break
                            }
                        }
                        if ($null -eq $Enumerator)
                        {
                            $EnumeratorError = New-ErrorRecord -Exception System.Management.Automation.RuntimeException -ErrorId 0 -ErrorCategory InvalidData -TargetObject $choice -Message 'Unable to determine an enumerator'
                            $PSCmdlet.ThrowTerminatingError($EnumeratorError)
                        }
                        else
                        {
                            [PSCustomObject]@{
                                Enumerator = $Enumerator
                                Choice     = $choice
                            }
                        }
                    }
                )
            }
        }
        'ObjectChoices'
        #Validate the Choice Objects using the first object as a representative
        {
            if ($null -eq $ChoiceObjects[0].Enumerator -or $null -eq $ChoiceObjects[0].Choice)
            {
                $ChoiceObjectError = New-ErrorRecord -Exception System.Management.Automation.RuntimeException -ErrorId 1 -ErrorCategory InvalidData -TargetObject $ChoiceObjects[0] -Message 'Choice Object(s) do not include the required enumerator and/or choice properties'
                $PSCmdlet.ThrowTerminatingError($ChoiceObjectError)
            }
        }
    }#Switch
    $possiblechoices = @(
        $ChoiceObjects | ForEach-Object {
            $Enumerator = $_.Enumerator
            $Choice = $_.Choice
            $Description = if (-not [string]::IsNullOrWhiteSpace($_.Description)) {$_.Description} else {$_.Choice}
            $ChoiceWithEnumerator =
            if ($Numbered)
            {
                "_$Enumerator $($Choice)"
            }
            else
            {
                $index = $choice.IndexOf($Enumerator)
                if ($index -eq -1)
                {
                    "_$Enumerator $($Choice)"
                }
                else
                {
                    $choice.insert($index, '_')
                }
            }
            [pscustomobject]@{
                ChoiceText           = $Choice
                ChoiceWithEnumerator = $ChoiceWithEnumerator
                Description          = $Description
            }
        }
    )
    $Script:UserChoice = $null
    #EndRegion ProcessChoices
    #Region Layout
    if ($Vertical)
    {
        $layout = 'Vertical'
    }
    else
    {
        $layout = 'Horizontal'
    }
    #EndRegion Layout
    #Region BuildWPFWindow
    # Add required assembly
    Add-Type -AssemblyName WindowsBase
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName PresentationFramework
    # Create a Size Object
    $wpfSize = new-object System.Windows.Size
    $wpfSize.Height = [double]::PositiveInfinity
    $wpfSize.Width = [double]::PositiveInfinity
    # Create a Window
    $Window = New-Object Windows.Window
    $Window.Title = $Title
    $Window.SizeToContent = 'WidthAndHeight'
    $window.WindowStartupLocation = 'CenterScreen'
    # Create a grid container with x rows, one for the message, x for the buttons
    $Grid = New-Object Windows.Controls.Grid
    $FirstRow = New-Object Windows.Controls.RowDefinition
    $FirstRow.Height = 'Auto'
    $grid.RowDefinitions.Add($FirstRow)
    # Create a label for the message
    $label = New-Object Windows.Controls.Label
    $label.Content = $Message
    $label.Margin = '5,5,5,5'
    $label.HorizontalAlignment = 'Left'
    $label.Measure($wpfSize)
    #add the label to Row 1
    $label.SetValue([Windows.Controls.Grid]::RowProperty, 0)
    #prepare for button sizing
    $buttonHeights = @()
    $buttonWidths = @()
    if ($layout -eq 'Horizontal') {$label.SetValue([Windows.Controls.Grid]::ColumnSpanProperty, $($choices.Count))}
    elseif ($layout -eq 'Vertical') {$buttonWidths += $label.DesiredSize.Width}
    #create the buttons and add them to the grid
    $buttonIndex = 0
    foreach ($pc in $possiblechoices)
    {
        # Create a button to get running Processes
        Set-Variable -Name "buttonControl$buttonIndex" -Value (New-Object Windows.Controls.Button) -Scope local
        $tempButton = Get-Variable -Name "buttonControl$buttonIndex" -ValueOnly
        $tempButton.Name = "Choice$buttonIndex"
        $tempButton.Content = $pc.ChoiceWithEnumerator
        $tempButton.Tooltip = $pc.Description
        $tempButton.HorizontalAlignment = 'Center'
        $tempButton.VerticalAlignment = 'Top'
        # Add an event on the Get Processes button
        $tempButton.Add_Click( {
                [Object]$sender = $args[0]
                [Windows.RoutedEventArgs]$e = $args[1]
                $Script:UserChoice = $sender.content.tostring()
                $Window.DialogResult = $true
                $Window.Close()
            })
        switch ($layout)
        {
            'Vertical'
            {
                #Create additional row for each button
                $Row = New-Object Windows.Controls.RowDefinition
                $Row.Height = 'Auto'
                $grid.RowDefinitions.Add($Row)
                $RowIndex = $buttonIndex + 1
                $tempButton.SetValue([Windows.Controls.Grid]::RowProperty, $RowIndex)
            }
            'Horizontal'
            {
                #Create additional row for the buttons
                $Row = New-Object Windows.Controls.RowDefinition
                $Row.Height = 'Auto'
                $grid.RowDefinitions.Add($Row)
                $RowIndex = 1
                $tempButton.SetValue([Windows.Controls.Grid]::RowProperty, $RowIndex)
                #create additional column for each button
                $Column = New-Object Windows.Controls.ColumnDefinition
                $Column.Width = 'Auto'
                $grid.ColumnDefinitions.Add($Column)
                $ColumnIndex = $buttonIndex
                $tempButton.SetValue([Windows.Controls.Grid]::ColumnProperty, $ColumnIndex)
            }
        }
        $tempButton.MinHeight = 10
        $tempButton.Margin = '5,5,5,5'
        $tempButton.Measure($wpfSize)
        $buttonheights += $tempButton.desiredSize.Height
        $buttonwidths += $tempButton.desiredSize.Width
        $buttonIndex++
    }
    $buttonHeight = ($buttonHeights | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum)
    Write-Verbose -Message "Button Height is $buttonHeight"
    $buttonWidth = ($buttonWidths| Measure-Object -Maximum | Select-Object -ExpandProperty Maximum) + 10
    Write-Verbose -Message "Button Width is $buttonWidth"
    $buttons = Get-Variable -Name 'buttonControl*' -Scope local -ValueOnly
    $buttonIndex = 0
    foreach ($button in $buttons)
    {
        $button.Height = $buttonHeight
        $button.Width = $buttonWidth
        $grid.AddChild($button)
        if ($buttonIndex -eq $DefaultChoice)
        {
            $null = $button.focus()
        }
        $buttonIndex++
    }
    # Add the elements to the relevant parent control
    $Grid.AddChild($label)
    $window.Content = $Grid
    #EndRegion BuildWPFWindow
    # Show the window

    if ($window.ShowDialog())
    {
        if ($ReturnChoice)
        {
            $cindex = Get-ArrayIndexForValue -array $possiblechoices -value $Script:UserChoice -property ChoiceWithEnumerator
            $possiblechoices[$cindex].ChoiceText
        }
        else
        {
            Get-ArrayIndexForValue -array $possiblechoices -value $Script:UserChoice -property ChoiceWithEnumerator
        }
    }

    }
