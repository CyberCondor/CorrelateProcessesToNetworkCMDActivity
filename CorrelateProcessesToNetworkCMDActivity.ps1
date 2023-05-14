$NetworkConnections                   = Get-NetTCPConnection
$ProcessList                          = Get-WmiObject win32_process | select ProcessName,ExecutablePath,CommandLine,Handle,HandleCount,ProcessID,ParentName,ParentProcessId
$CorrelatedProcessesToNetworkActivity = [System.Collections.Generic.List[PSObject]]::New()

Write-Host "Processing...`n"
foreach($Process in $ProcessList){
    foreach($Process2 in $ProcessList){if($Process2.ProcessID -eq $Process.ParentProcessId){$Process.ParentName = $Process2.ProcessName}}
    foreach($NetworkConnection in $NetworkConnections){
        if(($Process.ProcessID -eq $NetworkConnection.OwningProcess)){
            $CorrelatedProcessesToNetworkActivity.add([PSCustomObject]@{
                ProcessName=$Process.ProcessName;
                PID=$Process.ProcessID;
                NetPID=$NetworkConnection.OwningProcess;
                ParentPID=$Process.ParentProcessId;
                ParentName=$Process.ParentName;
                LocalAddress=$NetworkConnection.LocalAddress;
                LocalPort=$NetworkConnection.LocalPort;
                RemotePort=$NetworkConnection.RemotePort;
                RemoteAddress=$NetworkConnection.RemoteAddress;
                State=$NetworkConnection.State;
                ExecutablePath=$Process.ExecutablePath;
                CommandLine=$Process.CommandLine;
                AppliedSetting=$NetworkConnection.AppliedSetting})
        }
    }
}

write-Output "---"
Write-Output "`nProcesses:"
$ProcessList | select ProcessName,ProcessID,ParentProcessId,ParentName,ExecutablePath,CommandLine | Sort ExecutablePath,CommandLine,ParentProcessId,ProcessID | ft

write-Output "---"
Write-Output "`nProcesses Found WITH Network Connections:"
$CorrelatedProcessesToNetworkActivity | select ProcessName,PID,ParentPID,ParentName,State,LocalAddress,LocalPort,RemoteAddress,RemotePort,AppliedSetting | sort RemotePort,State,RemoteAddress,PID,LocalPort,ProcessName,ParentName | ft

write-Output "---"
Write-Output "`nExecutablePath and CommandLine Activity of Processes Found WITH Network Connections:"
$CorrelatedProcessesToNetworkActivity | where{($_.CommandLine -ne $null) -and($_.ExecutablePath -ne $null)} | select ProcessName,PID,ParentPID,ParentName,CommandLine,ExecutablePath | sort ExecutablePath,CommandLine,PID | fl
