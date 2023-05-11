$tasklist = Get-Process
$netstats = Get-NetTCPConnection
$CommandLine = Get-WmiObject win32_process | select CommandLine,ProcessID
$FreshStats = @()
$TasksWithoutNetworkStats = @()
$TasksWithCommandLineActivity = @()
$RemoteAddresses = @()
Write-Host "Processing...`n"
foreach($task in $tasklist){
    $TaskFoundWithNetworkStat = $false
    foreach($Command in $CommandLine){
        foreach($netstat in $netstats){
            if(($task.Id -eq $netstat.OwningProcess) -and ($task.Id -eq $Command.ProcessID)){
                $TaskFoundWithNetworkStat = $true
                $FreshStats += New-Object PSObject -Property @{
                    ProcessName=$task.ProcessName;
                    Handles=$task.Handles;
                    ProcessID=$task.Id;
                    NetProcessID=$netstat.OwningProcess;
                    LocalAddress=$netstat.LocalAddress;
                    LocalPort=$netstat.LocalPort;
                    RemoteAddress=$netstat.RemoteAddress;
                    RemotePort=$netstat.RemotePort;
                    State=$netstat.State;
                    Path=$Task.Path;
                    CommandLine=$Command.CommandLine}
            }
        }
    }
    if($TaskFoundWithNetworkStat -eq $false){$TasksWithoutNetworkStats += $Task | Select ID,ProcessName,Path}
}
foreach($FreshStat in $FreshStats){
    if($FreshStat.CommandLine -ne $null){
        $TasksWithCommandLineActivity += $FreshStat | select ProcessID,ProcessName,CommandLine
    }
}
foreach($RemoteAddress in $FreshStats){
    if(($RemoteAddress.RemoteAddress -ne "::") -and ($RemoteAddress.RemoteAddress -ne "127.0.0.1") -and ($RemoteAddress.RemoteAddress -ne "0.0.0.0")){
        $RemoteAddresses += $RemoteAddress
    }
}

Write-Output "`nTasks Found WITHOUT Network Stats:"
$TasksWithoutNetworkStats | sort Path,Id,ProcessName | ft -AutoSize

write-Output "---"
Write-Output "`nTasks Found WITH Network Stats:"
$FreshStats | select ProcessName,ProcessID,State,LocalAddress,LocalPort,RemoteAddress,RemotePort,Handles | sort ProcessName | ft

write-Output "---"
Write-Output "`nPath of Tasks Found WITH Network Stats:"
$FreshStats | select ProcessName,ProcessID,Path | sort Path,ProcessId,ProcessName | ft

write-Output "---"
Write-Output "`nTasks With CommandLine Activity:"
$TasksWithCommandLineActivity | sort CommandLine | fl

write-Output "---"
Write-Output "`nRemote Addresses:"
$RemoteAddresses | select ProcessName,RemoteAddress,RemotePort,LocalAddress,LocalPort,ProcessID,NetProcessID,Handles,State,Path,CommandLine | sort ProcessID | fl
$RemoteAddresses | select RemoteAddress,ProcessName,ProcessID | ft