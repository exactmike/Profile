    Function Read-InputBoxDialog {
        
    # Show input box popup and return the value entered by the user.
    param(
        [string]$Message
        ,
        [Alias('WindowTitle')]
        [string]$Title
        ,
        [string]$DefaultText
    )

    $Script:UserInput = $null
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
    $Window.Title = $WindowTitle
    $Window.MinWidth = 250
    $Window.SizeToContent = 'WidthAndHeight'
    $window.WindowStartupLocation = 'CenterScreen'
    # Create a grid container with 3 rows, one for the message, one for the text box, and one for the buttons
    $Grid = New-Object Windows.Controls.Grid
    $FirstRow = New-Object Windows.Controls.RowDefinition
    $FirstRow.Height = 'Auto'
    $grid.RowDefinitions.Add($FirstRow)
    $SecondRow = New-Object Windows.Controls.RowDefinition
    $SecondRow.Height = 'Auto'
    $grid.RowDefinitions.Add($SecondRow)
    $ThirdRow = New-Object Windows.Controls.RowDefinition
    $ThirdRow.Height = 'Auto'
    $grid.RowDefinitions.Add($ThirdRow)
    $ColumnOne = New-Object Windows.Controls.ColumnDefinition
    $ColumnOne.Width = 'Auto'
    $grid.ColumnDefinitions.Add($ColumnOne)
    $ColumnTwo = New-Object Windows.Controls.ColumnDefinition
    $ColumnTwo.Width = 'Auto'
    $grid.ColumnDefinitions.Add($ColumnTwo)
    # Create a label for the message
    $label = New-Object Windows.Controls.Label
    $label.Content = $Message
    $label.Margin = '5,5,5,5'
    $label.HorizontalAlignment = 'Left'
    $label.Measure($wpfSize)
    #add the label to Row 1
    $label.SetValue([Windows.Controls.Grid]::RowProperty, 0)
    $label.SetValue([Windows.Controls.Grid]::ColumnSpanProperty, 2)
    $textbox = New-Object Windows.Controls.TextBox
    $textbox.name = 'InputBox'
    $textbox.Text = $DefaultText
    $textbox.Margin = '10,10,10,10'
    $textbox.MinWidth = 200
    $textbox.SetValue([Windows.Controls.Grid]::RowProperty, 1)
    $textbox.SetValue([Windows.Controls.Grid]::ColumnSpanProperty, 2)
    $OKButton = New-Object Windows.Controls.Button
    $OKButton.Name = 'OK'
    $OKButton.Content = 'OK'
    $OKButton.ToolTip = 'OK'
    $OKButton.HorizontalAlignment = 'Center'
    $OKButton.VerticalAlignment = 'Top'
    $OKButton.Add_Click( {
            [Object]$sender = $args[0]
            [Windows.RoutedEventArgs]$e = $args[1]
            $Script:UserInput = $textbox.text
            $Window.DialogResult = $true
            $Window.Close()
        })
    $OKButton.SetValue([Windows.Controls.Grid]::RowProperty, 2)
    $OKButton.SetValue([Windows.Controls.Grid]::ColumnProperty, 0)
    $OKButton.Margin = '5,5,5,5'
    $CancelButton = New-Object Windows.Controls.Button
    $CancelButton.Name = 'Cancel'
    $CancelButton.Content = 'Cancel'
    $CancelButton.ToolTip = 'Cancel'
    $CancelButton.HorizontalAlignment = 'Center'
    $CancelButton.VerticalAlignment = 'Top'
    $CancelButton.Margin = '5,5,5,5'
    $CancelButton.Measure($wpfSize)
    $CancelButton.Add_Click( {
            [Object]$sender = $args[0]
            [Windows.RoutedEventArgs]$e = $args[1]
            $Window.DialogResult = $false
            $Window.Close()
        })
    $CancelButton.SetValue([Windows.Controls.Grid]::RowProperty, 2)
    $CancelButton.SetValue([Windows.Controls.Grid]::ColumnProperty, 1)
    $CancelButton.Height = $CancelButton.DesiredSize.Height
    $CancelButton.Width = $CancelButton.DesiredSize.Width + 10
    $OKButton.Height = $CancelButton.DesiredSize.Height
    $OKButton.Width = $CancelButton.DesiredSize.Width + 10
    $Grid.AddChild($label)
    $Grid.AddChild($textbox)
    $Grid.AddChild($OKButton)
    $Grid.AddChild($CancelButton)
    $window.Content = $Grid
    if ($window.ShowDialog())
    {
        $Script:UserInput
    }

    }
