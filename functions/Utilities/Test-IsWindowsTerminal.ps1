
#https://mikefrobbins.com/2024/05/16/detecting-windows-terminal-with-powershell/
function Test-IsWindowsTerminal {
    [CmdletBinding()]
    param ()

    # Check if PowerShell version is 5.1 or below, or if running on Windows
    if ($PSVersionTable.PSVersion.Major -le 5 -or $IsWindows -eq $true) {
        $currentPid = $PID

        # Loop through parent processes to check if Windows Terminal is in the hierarchy
        while ($currentPid) {
            try {
                $process = Get-CimInstance Win32_Process -Filter "ProcessId = $currentPid" -ErrorAction Stop -Verbose:$false
            } catch {
                # Return false if unable to get process information
                return $false
            }

            Write-Verbose -Message "ProcessName: $($process.Name), Id: $($process.ProcessId), ParentId: $($process.ParentProcessId)"

            # Check if the current process is Windows Terminal
            if ($process.Name -eq 'WindowsTerminal.exe') {
                return $true
            } else {
                # Move to the parent process
                $currentPid = $process.ParentProcessId
            }
        }

        # Return false if Windows Terminal is not found in the hierarchy
        return $false
    } else {
        Write-Verbose -Message 'Exiting due to non-Windows environment'
        return $false
    }
}
