# Teste rápido - executa em 10 segundos
$TestDir = "$env:TEMP\TestHidden"
if (-not (Test-Path $TestDir)) { New-Item -ItemType Directory -Path $TestDir -Force | Out-Null }

$TestScript = @'
# Script de teste
$logFile = "$env:TEMP\TestHidden\test.log"
"Executado em: $(Get-Date)" | Out-File $logFile -Append
whoami | Out-File $logFile -Append
"---" | Out-File $logFile -Append
'@

$TestScriptPath = "$TestDir\test.ps1"
$TestScript | Out-File $TestScriptPath -Encoding UTF8

# Criar tarefa para executar em 10 segundos
$TestTaskName = "TestTask_$(Get-Random)"
$TestAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -File `"$TestScriptPath`""
$TestTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(10)

Register-ScheduledTask -TaskName $TestTaskName -Action $TestAction -Trigger $TestTrigger -Description "Tarefa de teste" -Force

Write-Host "Tarefa de teste criada: $TestTaskName" -ForegroundColor Green
Write-Host "Executará em 10 segundos..." -ForegroundColor Yellow
Write-Host "Verifique o log em: $env:TEMP\TestHidden\test.log" -ForegroundColor Cyan

# Limpar após teste (opcional)
Start-Sleep 15
Unregister-ScheduledTask -TaskName $TestTaskName -Confirm:$false
