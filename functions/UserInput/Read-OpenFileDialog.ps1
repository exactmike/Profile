    Function Read-OpenFileDialog {
        
    [cmdletbinding()]
    param(
        [string]$WindowTitle
        ,
        [string]$InitialDirectory
        ,
        [string]$Filter = 'All files (*.*)|*.*'
        ,
        [switch]$AllowMultiSelect
    )
    Add-Type -AssemblyName System.Windows.Forms
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = $WindowTitle
    if ($PSBoundParameters.ContainsKey('InitialDirectory')) { $openFileDialog.InitialDirectory = $InitialDirectory }
    $openFileDialog.Filter = $Filter
    if ($AllowMultiSelect) { $openFileDialog.MultiSelect = $true }
    $openFileDialog.ShowHelp = $true
    # Without this line the ShowDialog() function may hang depending on system configuration and running from console vs. ISE.
    $result = $openFileDialog.ShowDialog()
    switch ($Result)
    {
        'OK'
        {
            if ($AllowMultiSelect)
            {
                $openFileDialog.Filenames
            }
            else
            {
                $openFileDialog.Filename
            }
        }
        'Cancel'
        {
        }
    }
    $openFileDialog.Dispose()
    Remove-Variable -Name openFileDialog

    }
