# =====================================================================
# H-PE11 // PHOENIX TWEAKPACK v1.0 (paste-and-run)
# База: перенос полного каталога PrimeBuild-pc/TweakHub v1.5.0 (аудит TH-AUDIT-1)
# Тренды: WinUtil 2026 (restore-point -> твики, Security-режим WU),
#         Atlas v0.5.0 (SysMain оставляем, 24H2/25H2), сообщество 2026
#         (NTI - смешанные результаты, HAGS - от GPU).
# Эмерджентное против TweakHub:
#   1) Бэкап ПЕРСИСТЕНТНЫЙ: JSON-журнал + .reg-экспорты рядом со скриптом
#      (восстановление возможно даже без этого пака, любым regedit).
#   2) Авто-решения по железу: SysMain/Prefetcher решаются по типу диска,
#      HAGS проверяет поддержку GPU, WSearch решается по диску.
#   3) Сервисный уровень телеметрии (DiagTrack/dmwappushservice/CEIP-задачи) -
#      TweakHub трогает только политики реестра.
#   4) MSI mode + interrupt affinity для GPU/NVMe (из UI TweakHub -> в пакет).
#   5) Режимы Report/Apply/Restore + метрики ЭВ.1 в стиле бомб-скриптов.
#   6) Разделение "запечь в эталон" vs "после деплоя" для конвейера PHOENIX.
# Закон: ЧЕЛОВЕК=СИСТЕМА=ЦЕЛОЕ. ЭВ.1: недоступно = НЕ сделано (метка [--]).
# Требования: Windows 11 24H2/25H2, консоль PowerShell ОТ АДМИНИСТРАТОРА.
# Как запускать: выделить ВСЁ, вставить в admin PS, Enter. Флаги править ДО вставки.
# =====================================================================

# ==== ФЛАГИ (править до вставки) ====
$PhxMode         = 'Report'  # 'Report' = только показать план | 'Apply' = применить | 'Restore' = восстановить из журнала
$PhxBackupDir    = ''        # пусто = рядом со скриптом\PHX_TWEAKBACKUP_<ts>; иначе укажи свой путь
$PhxCatCpu       = $true     # CPU-планирование и питание
$PhxCatNetwork   = $true     # Сеть: throttling, DO, NIC-пресет (moderation/EEE/green-ethernet off)
$PhxCatGaming    = $true     # Игра: GameDVR, FSE, GameMode, GameBar; HAGS - по поддержке GPU
$PhxCatResponsiv = $true     # Отзывчивость: меню, старт-задержка, end-task, мышь, анимации
$PhxCatMemory    = $true     # SysMain/Prefetcher - АВТО по типу диска (SSD/HDD), отключение - только флагом ниже
$PhxForceSysMainOff = $false # $true = принудительно вырубить SysMain+Prefetch (НЕ рекомендуется: см. Atlas v0.4.1+)
$PhxCatPrivacy   = $true     # Телеметрия/приватность: политики + СЕРВИСЫ (DiagTrack и др.)
$PhxCatUpdate    = $true     # Windows Update: Security-режим (фичи +365д, секьюрити +4д) - дефолт
$PhxCatPower     = $true     # Fast startup off (важно для BCD-экспериментов PHOENIX)
$PhxCatMisc      = $true     # Подробный BSOD, metadata с сети, драйвер-поиск (risk 5 - флаг)
$PhxNicLowLat    = $true     # NIC-пресет низкой задержки (InterruptModeration/EEE/GreenEthernet off)
$PhxMsiGpuNvme   = $false    # $true = MSI mode + мягкая affinity для GPU/NVMe (требует теста на станции!)
$PhxWSearchOff   = $false    # $true = отключить Windows Search (на SSD обычно НЕ надо)
$PhxAdvancedRisk = $false    # $true = разрешить твики risk 5 (SearchOrderConfig 0 и т.п.)
$PhxKeepMount    = $false    # зарезервировано (симметрия бомб-скриптам)
# =====================================================================

& {
  $ErrorActionPreference = 'Continue'
  $ts   = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
  $log  = "$env:USERPROFILE\Desktop\PHX_TWEAKPACK_$ts.log"
  if ([string]::IsNullOrWhiteSpace($PhxBackupDir)) {
    if ([string]::IsNullOrEmpty($PSScriptRoot)) { $bdir = "$env:USERPROFILE\Desktop\PHX_TWEAKBACKUP_$ts" }
    else { $bdir = Join-Path $PSScriptRoot "PHX_TWEAKBACKUP_$ts" }
  } else { $bdir = $PhxBackupDir }
  $script:PhxOk = 0; $script:PhxSkip = 0; $script:PhxRestored = 0
  $script:PhxEV1 = @()
  $journalPath = Join-Path $bdir 'phx_tweak_journal.json'

  function Write-Log([string]$msg) {
    $line = $msg
    Write-Host $line
    Add-Content -LiteralPath $log -Value $line -Encoding UTF8
  }
  function Set-EV1([string]$item, [bool]$done, [string]$note) {
    if ($done) { Write-Log ("  [x] " + $item + "  " + $note); $script:PhxOk++ }
    else {
      Write-Log ("  [--] " + $item + "  " + $note)
      $script:PhxEV1 += ($item + " :: " + $note)
      $script:PhxSkip++
    }
  }

  Write-Log ""
  Write-Log "== PHOENIX TWEAKPACK v1.0 // $ts =="
  Write-Log "Режим: $PhxMode | Бэкап-каталог: $bdir"

  # ---------- 0. Пре-чеки ----------
  $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
             ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  if (-not $isAdmin) {
    Write-Log "!! НЕТ ПРАВ АДМИНИСТРАТОРА."
    if ($PhxMode -ne 'Report') { Write-Log "!! Режим $PhxMode требует администратора - СТОП."; return }
    Write-Log "   Report продолжается (HKCU читается, HKLM будет помечен [--])."
  }
  New-Item -ItemType Directory -Path $bdir -Force | Out-Null

  $os = Get-CimInstance Win32_OperatingSystem
  $build = [int]($os.BuildNumber)
  $win11 = $build -ge 22000
  Set-EV1 'Windows 11 (build >= 22000)' $win11 "build $build"
  if (-not $win11) { Write-Log "!! Не Windows 11 - стоп."; return }

  # Тип системного диска: NVMe/SSD/HDD (для авто-решений SysMain/Prefetch/WSearch)
  $sysDisk = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq (Get-Partition -DriveLetter $env:SystemDrive[0] -ErrorAction SilentlyContinue).DiskNumber } | Select-Object -First 1
  if (-not $sysDisk) { $sysDisk = Get-PhysicalDisk | Sort-Object Size -Descending | Select-Object -First 1 }
  $busType = if ($sysDisk) { $sysDisk.BusType } else { 'Unknown' }   # NVMe / SATA / ...
  $medType = if ($sysDisk) { $sysDisk.MediaType } else { 'Unspecified' } # SSD / HDD
  $isSsd = ($medType -eq 'SSD') -or ($busType -eq 'NVMe')
  Write-Log ("Системный диск: " + $busType + "/" + $medType + " -> SSD-класс: " + $isSsd)

  # ---------- 1. Механика: бэкап до записи (персистентный журнал + .reg) ----------
  $script:Journal = New-Object System.Collections.Generic.List[object]
  function Get-PhxValue([string]$Path, [string]$Name) {
    try { return (Get-ItemPropertyValue -LiteralPath $Path -Name $Name -ErrorAction Stop) } catch { return $null }
  }
  function Backup-PhxValue([string]$Path, [string]$Name) {
    # Запоминаем ОРИГИНАЛ до первой записи. absent = значения не было (restore удалит).
    $existing = $null
    $kind = $null
    try {
      $k = Get-Item -LiteralPath $Path -ErrorAction Stop
      $existing = $k.GetValue($Name)
      if ($null -ne $existing) { $kind = $k.GetValueKind($Name) }
    } catch { $existing = $null }
    $rec = @{ Path = $Path; Name = $Name; Old = $existing; Kind = $kind; WasPresent = ($null -ne $existing) }
    $script:Journal.Add($rec) | Out-Null
    return $rec
  }
  function Set-PhxValue([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord') {
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    Backup-PhxValue $Path $Name | Out-Null
    try {
      New-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
      return $true
    } catch { Write-Log ("  !! сбой записи " + $Path + "\" + $Name + ": " + $_.Exception.Message); return $false }
  }
  function Save-PhxJournal {
    $json = $script:Journal | ConvertTo-Json -Depth 4
    Set-Content -LiteralPath $journalPath -Value $json -Encoding UTF8
    Write-Log ("Журнал бэкапа: " + $journalPath + " (" + $script:Journal.Count + " значений)")
  }

  # Персистентный .reg-экспорт ДЛЯ ВСЕГО списка целей ДО применения (двойная страховка)
  function Export-PhxReg {
    # Каждый ключ цели целиком экспортируется reg.exe ДО применения (двойная страховка к журналу)
    $regDir = Join-Path $bdir 'reg_export'
    New-Item -ItemType Directory -Path $regDir -Force | Out-Null
    $n = 0
    foreach ($t in $script:Targets) {
      if ($t.Svc -or $t.Task) { continue }
      $regPath = $t.Path -replace '^HKLM:\\','HKLM\' -replace '^HKCU:\\','HKCU\'
      $file = Join-Path $regDir (($regPath -replace '[\\:]','_') + '.reg')
      & reg.exe export $regPath $file /y 2>$null | Out-Null
      if ($LASTEXITCODE -eq 0) { $n++ }
    }
    Set-Content -LiteralPath (Join-Path $bdir 'README.txt') -Value @('PHX TWEAKPACK pre-export (до применения)','Каждый .reg - состояние ЦЕЛОГО ключа ДО применения твиков.','Восстановление: reg import <файл.reg> или двойной клик.') -Encoding UTF8
    Set-EV1 'PRE-экспорт .reg ключей до применения' ($n -gt 0) ("reg_export: " + $n + " ключей")
  }

  # ---------- 2. Каталог целей (перенос TweakHub v1.5.0 + эмерджентные) ----------
  # Поля: Path, Name, Value, Type, Risk, Src, Cat, Note
  # Src: TH = перенос из TweakHub, TH+ = перенос с улучшением, PHX = своё эмерджентное, WU = тренд WinUtil
  $script:Targets = @(
    # --- CPU / планирование (категория TweakHub: CPU) ---
    @{ Cat='cpu'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl'; Name='Win32PrioritySeparation'; Value=0x26; Type='DWord'; Risk=3; Src='TH';   Note='форс-квант на передний план (26h = short/fixed/foreground-boost)' },
    @{ Cat='cpu'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'; Name='DisableWpbtExecution'; Value=1; Type='DWord'; Risk=4; Src='TH'; Note='отключить WPBT-исполнение (OEM-код в ACPI)' },
    # --- Сеть (TweakHub: Network; NTI оставлен advanced - тесты сообщества 2026 смешанные) ---
    @{ Cat='net'; Path='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name='NetworkThrottlingIndex'; Value=[int]-1; Type='DWord'; Risk=3; Src='TH'; Note='снять network-throttle (0xFFFFFFFF); эффект от системы к системе' },
    @{ Cat='net'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization'; Name='DOPercentageMaxBackgroundBandwidth'; Value=30; Type='DWord'; Risk=2; Src='TH'; Note='DO фоновая загрузка <= 30%' },
    @{ Cat='net'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization'; Name='DODownloadMode'; Value=1; Type='DWord'; Risk=2; Src='PHX'; Note='DO mode 1 (только LAN) - лимит p2p-раздачи' },
    # --- Игра (TweakHub: Gaming) ---
    @{ Cat='game'; Path='HKCU:\System\GameConfigStore'; Name='GameDVR_FSEBehaviorMode'; Value=2; Type='DWord'; Risk=1; Src='TH'; Note='полноэкранный режим без оптимизаций' },
    @{ Cat='game'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR'; Name='AppCaptureEnabled'; Value=0; Type='DWord'; Risk=1; Src='TH'; Note='GameDVR capture off' },
    @{ Cat='game'; Path='HKCU:\SOFTWARE\Microsoft\GameBar'; Name='AllowAutoGameMode'; Value=1; Type='DWord'; Risk=1; Src='PHX'; Note='GameMode auto on (оставляем, Atlas-стиль: гейм-моду держим)' },
    @{ Cat='game'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR'; Name='AllowGameDVR'; Value=0; Type='DWord'; Risk=2; Src='TH+;WU'; Note='политика GameDVR off (у TH только HKCU)' },
    # HwSchMode (HAGS) добавляется ТОЛЬКО при поддержке GPU - см. детекцию в секции 3
    # --- Отзывчивость (TweakHub: System Responsiveness / Visual) ---
    @{ Cat='resp'; Path='HKCU:\Control Panel\Desktop'; Name='MenuShowDelay'; Value='0'; Type='String'; Risk=1; Src='TH'; Note='меню без задержки' },
    @{ Cat='resp'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize'; Name='StartupDelayInMSec'; Value=0; Type='DWord'; Risk=1; Src='TH'; Note='убрать старт-задержку запуска' },
    @{ Cat='resp'; Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings'; Name='TaskbarEndTask'; Value=1; Type='DWord'; Risk=1; Src='TH'; Note='End Task в правой кнопке таскбара' },
    @{ Cat='resp'; Path='HKCU:\Control Panel\Desktop\WindowMetrics'; Name='MinAnimate'; Value='0'; Type='String'; Risk=1; Src='TH'; Note='минимизация без анимации' },
    @{ Cat='resp'; Path='HKCU:\Control Panel\Mouse'; Name='MouseSpeed'; Value='0'; Type='String'; Risk=1; Src='TH'; Note='акселерация мыши off (1/3)' },
    @{ Cat='resp'; Path='HKCU:\Control Panel\Mouse'; Name='MouseThreshold1'; Value='0'; Type='String'; Risk=1; Src='TH'; Note='акселерация мыши off (2/3)' },
    @{ Cat='resp'; Path='HKCU:\Control Panel\Mouse'; Name='MouseThreshold2'; Value='0'; Type='String'; Risk=1; Src='TH'; Note='акселерация мыши off (3/3)' },
    @{ Cat='resp'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'; Name='EnableTransparency'; Value=0; Type='DWord'; Risk=1; Src='TH'; Note='прозрачность off (опция вкуса)' },
    @{ Cat='resp'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'; Name='VisualFXSetting'; Value=2; Type='DWord'; Risk=1; Src='TH'; Note='визуальные эффекты -> максимум производительности' },
    # --- Приватность/телеметрия: политики (TweakHub: Privacy) ---
    @{ Cat='priv'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; Name='AllowTelemetry'; Value=0; Type='DWord'; Risk=3; Src='TH'; Note='на Pro -> минимум (1); 0 = только Enterprise/Edu' },
    @{ Cat='priv'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name='EnableActivityFeed'; Value=0; Type='DWord'; Risk=3; Src='TH'; Note='история активностей off' },
    @{ Cat='priv'; Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo'; Name='Enabled'; Value=0; Type='DWord'; Risk=2; Src='TH'; Note='рекламный ID off' },
    @{ Cat='priv'; Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy'; Name='TailoredExperiencesWithDiagnosticDataEnabled'; Value=0; Type='DWord'; Risk=2; Src='TH'; Note='персонализация по диагностике off' },
    @{ Cat='priv'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name='DisableWindowsConsumerFeatures'; Value=1; Type='DWord'; Risk=2; Src='TH'; Note='consumer-контент/спонсируемые приложения off' },
    @{ Cat='priv'; Path='HKCU:\Software\Policies\Microsoft\Windows\Explorer'; Name='DisableSearchBoxSuggestions'; Value=1; Type='DWord'; Risk=1; Src='TH'; Note='Bing-подсказки в поиске off' },
    @{ Cat='priv'; Path='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name='SettingsPageVisibility'; Value='hide:aicomponents'; Type='String'; Risk=4; Src='TH'; Note='спрятать страницу AI-компонентов' },
    # --- Приватность: СЕРВИСНЫЙ уровень (эмерджентное - у TweakHub нет) ---
    @{ Cat='priv'; Svc='DiagTrack'; StartType='Disabled'; Risk=2; Src='PHX'; Note='Connected User Experiences and Telemetry - главный сборщик' },
    @{ Cat='priv'; Svc='dmwappushservice'; StartType='Disabled'; Risk=2; Src='PHX'; Note='WAP Push Message Routing - канал телеметрии' },
    @{ Cat='priv'; Svc='diagnosticshub.standardcollector.service'; StartType='Manual'; Risk=3; Src='PHX'; Note='Diagnostic Hub - в ручной режим' },
    @{ Cat='priv'; Task='\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser'; Action='Disable'; Risk=2; Src='PHX'; Note='CEIP-оценщик совместимости' },
    @{ Cat='priv'; Task='\Microsoft\Windows\Application Experience\ProgramDataUpdater'; Action='Disable'; Risk=2; Src='PHX'; Note='CEIP-сбор программных данных' },
    @{ Cat='priv'; Task='\Microsoft\Windows\Customer Experience Improvement Program\Consolidator'; Action='Disable'; Risk=2; Src='PHX'; Note='CEIP Consolidator' },
    @{ Cat='priv'; Task='\Microsoft\Windows\Feedback\Siuf\DmClient'; Action='Disable'; Risk=2; Src='PHX'; Note='канал фидбека' },
    # --- Windows Update (тренд WinUtil: Security-режим умнее полного отключения) ---
    @{ Cat='wu'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'; Name='NoAutoRebootWithLoggedOnUsers'; Value=1; Type='DWord'; Risk=1; Src='WU'; Note='без авто-ребута под юзером' },
    @{ Cat='wu'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'; Name='DeferFeatureUpdates'; Value=1; Type='DWord'; Risk=2; Src='WU;TH'; Note='фич-апдейты задерживаем' },
    @{ Cat='wu'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'; Name='DeferFeatureUpdatesPeriodInDays'; Value=365; Type='DWord'; Risk=2; Src='WU'; Note='фичи +365 дней (WinUtil 2026)' },
    @{ Cat='wu'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'; Name='DeferQualityUpdates'; Value=1; Type='DWord'; Risk=2; Src='WU'; Note='секьюрити задерживаем' },
    @{ Cat='wu'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'; Name='DeferQualityUpdatesPeriodInDays'; Value=4; Type='DWord'; Risk=2; Src='WU'; Note='секьюрити +4 дня (пропустить плохие патчи)' },
    @{ Cat='wu'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'; Name='ExcludeWUDriversInQualityUpdate'; Value=1; Type='DWord'; Risk=3; Src='TH'; Note='драйверы из WU не тянуть (драйверы ставим сами)' },
    # --- Питание (TweakHub: Advanced/fast startup; согласуется с BCD-линией PHOENIX) ---
    @{ Cat='pow'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power'; Name='HiberbootEnabled'; Value=0; Type='DWord'; Risk=2; Src='TH'; Note='fast startup off - чистый cold boot (важно для BCD/двухсистем)' },
    # --- Misc (TweakHub: Advanced) ---
    @{ Cat='misc'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'; Name='DisplayParameters'; Value=1; Type='DWord'; Risk=1; Src='TH'; Note='подробный BSOD-экран' },
    @{ Cat='misc'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata'; Name='PreventDeviceMetadataFromNetwork'; Value=1; Type='DWord'; Risk=3; Src='TH'; Note='метаданные устройств не с сети' }
  )
  # Условные цели: добавляются после детекций
  if ($PhxAdvancedRisk) {
    $script:Targets += @{ Cat='misc'; Path='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching'; Name='SearchOrderConfig'; Value=0; Type='DWord'; Risk=5; Src='TH'; Note='НЕ искать драйверы в WU вовсе (risk 5: могут остаться без драйверов)' }
  }
  if ($PhxWSearchOff) {
    $script:Targets += @{ Cat='misc'; Svc='WSearch'; StartType='Disabled'; Risk=3; Src='TH'; Note='Windows Search off (флаг PhxWSearchOff)' }
  }

  # ---------- 3. Детекции (эмерджентное: авто-решения по железу) ----------
  Write-Log ""
  Write-Log "== ДЕТЕКЦИИ =="
  # HAGS: поддержка HwSchMode - дискретка GTX 10xx+/RDNA+ или iGPU Intel Xe/Arc. Утилитарно: ищем NVIDIA/AMD/Intel по PCI.
  $gpuOk = $false; $gpuName = ''
  try {
    $gpus = Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name
    foreach ($g in $gpus) {
      $gpuName = $g
      if     ($g -match 'NVIDIA' -and $g -match 'GTX 1[0-9]|RTX|MX [2-9]') { $gpuOk = $true }
      elseif ($g -match 'Radeon RX|Ryzen .* Graphics|680M|780M|890M')       { $gpuOk = $true }
      elseif ($g -match 'Intel.*(UHD 7[3-9]0|Iris Xe|Arc)')                 { $gpuOk = $true }
    }
  } catch {}
  Write-Log ("GPU: " + $gpuName + " -> HAGS поддержан: " + $gpuOk)
  if ($PhxCatGaming) {
    if ($gpuOk) {
      $script:Targets += @{ Cat='game'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'; Name='HwSchMode'; Value=2; Type='DWord'; Risk=2; Src='TH'; Note='HAGS on (GPU поддержан по детекции)' }
      Set-EV1 'HAGS (HwSchMode=2)' $true ('добавлен в план: ' + $gpuName)
    } else {
      Set-EV1 'HAGS (HwSchMode=2)' $false ('GPU не распознан как поддерживающий: ' + $gpuName + ' - тфик ИСКЛЮЧЁН из плана')
    }
  }

  # Memory-категория: авто-решение по диску (тренд Atlas v0.4.1+: SysMain ОСТАВЛЯЮТ)
  Write-Log ""
  Write-Log "== ПАМЯТЬ: авто-решение по типу диска =="
  if ($PhxForceSysMainOff) {
    $script:Targets += @{ Cat='mem'; Svc='SysMain'; StartType='Disabled'; Risk=3; Src='TH'; Note='SysMain off (принудительно, флаг PhxForceSysMainOff)' }
    $script:Targets += @{ Cat='mem'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'; Name='EnablePrefetcher'; Value=0; Type='DWord'; Risk=3; Src='TH'; Note='prefetcher off (принудительно)' }
    Set-EV1 'SysMain+Prefetcher' $true 'выключены принудительно (НЕ рекомендуется)'
  } elseif ($isSsd) {
    Set-EV1 'SysMain+Prefetcher' $true ('оставлены ВКЛ (SSD/NVMe; тренд Atlas) - отключение опционально флагом')
  } else {
    Set-EV1 'SysMain+Prefetcher' $true 'оставлены ВКЛ (HDD: prefetch жизненно важен)'
  }

  # ---------- 4. Power-слой через powercfg (перенос TweakHub PowerService) ----------
  function Invoke-PhxPower {
    Write-Log ""
    Write-Log "== POWER (powercfg, перенос TH PowerService) =="
    # GUID выдираем regex'ом - вывод powercfg локализован (ru/en), сам GUID всегда латиница
    $raw = (powercfg /getactivescheme) | Out-String
    $m = [regex]::Match($raw, '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}')
    if (-not $m.Success) { Set-EV1 'powercfg active scheme' $false 'не удалось вытащить GUID (вывод ниже)'; Write-Log $raw; return }
    $scheme = $m.Value
    & powercfg /export (Join-Path $bdir 'power_scheme_before.pow') $scheme 2>$null
    Set-EV1 'PRE-экспорт активной схемы питания' (Test-Path (Join-Path $bdir 'power_scheme_before.pow')) 'power_scheme_before.pow'
    # PROCTHROTTLEMIN 100 (AC): CPU-минимум 100% = "disable CPU throttling" из TH
    powercfg /setacvalueindex $scheme SUB_PROCESSOR PROCTHROTTLEMIN 100 2>$null
    Set-EV1 'CPU min state AC = 100%' ($LASTEXITCODE -eq 0) 'PROCTHROTTLEMIN (TH: disable_cpu_throttling)'
    # CPMINCORES 100 (AC): парковка ядер off = "disable core parking" из TH
    powercfg /setacvalueindex $scheme SUB_PROCESSOR CPMINCORES 100 2>$null
    Set-EV1 'Core parking min cores = 100%' ($LASTEXITCODE -eq 0) 'CPMINCORES (TH: disable_core_parking)'
    powercfg /setactive $scheme 2>$null
    Set-EV1 'powercfg применён и план переактивирован' ($LASTEXITCODE -eq 0) $scheme
  }

  # ---------- 5. NIC-пресет низкой задержки (перенос TH NetworkAdapterService) ----------
  function Invoke-PhxNic {
    Write-Log ""
    Write-Log "== NIC: пресет низкой задержки (перенос TH) =="
    $sets = @(
      @('*InterruptModeration','0'), ('*EEE','0'), ('EEELinkAdvertisement','0'), ('ULPMode','0'), ('SipsEnabled','0'),
      ('AdvancedEEE','0'), ('EnableGreenEthernet','0'), ('GigaLite','0'), ('PowerSavingMode','0'),
      ('*FlowControl','0'), ('*ReceiveBuffers','512'), ('*TransmitBuffers','512')
    )
    $adapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' }
    if (-not $adapters) { Set-EV1 'NIC пресет' $false 'адаптеры не найдены'; return }
    foreach ($a in $adapters) {
      $applied = 0; $skipped = 0
      foreach ($kv in $sets) {
        $cur = Get-NetAdapterAdvancedProperty -Name $a.Name -DisplayName $kv[0] -ErrorAction SilentlyContinue
        if ($cur) {
          try { Set-NetAdapterAdvancedProperty -Name $a.Name -DisplayName $kv[0] -RegistryValue $kv[1] -ErrorAction Stop; $applied++ }
          catch { $skipped++ }
        } else { $skipped++ }
      }
      Set-EV1 ("NIC " + $a.Name) ($applied -gt 0) ("применено " + $applied + ", не поддержано " + $skipped)
    }
  }

  # ---------- 6. MSI mode / affinity GPU+NVMe (перенос TH InterruptService) ----------
  function Invoke-PhxMsi {
    Write-Log ""
    Write-Log "== MSI mode: GPU/NVMe (перенос TH InterruptService) =="
    $devs = Get-PnpDevice -PresentOnly | Where-Object { $_.Class -in @('Display','SCSIAdapter') -or ($_.Class -eq 'DiskDrive' -and $_.InstanceId -match 'VEN_NVME|NVME') }
    if (-not $devs) { Set-EV1 'MSI: цели' $false 'GPU/NVMe не найдены'; return }
    foreach ($d in $devs) {
      $id = $d.InstanceId
      $base = "HKLM:\SYSTEM\CurrentControlSet\Enum\$id\Device Parameters\Interrupt Management"
      $msiKey = "$base\MessageSignaledInterruptProperties"
      if (-not (Test-Path $msiKey)) { New-Item -Path $msiKey -Force | Out-Null }
      $cur = Get-PhxValue $msiKey 'MSISupported'
      Backup-PhxValue $msiKey 'MSISupported' | Out-Null
      New-ItemProperty -LiteralPath $msiKey -Name 'MSISupported' -Value 1 -PropertyType DWord -Force | Out-Null
      Set-EV1 ("MSI " + $d.FriendlyName) $true ("было MSISupported=" + $(if ($null -ne $cur) { $cur } else { 'absent' }) + " -> 1 (вступит после ребута)")
    }
    Write-Log "ВНИМАНИЕ: MSI-изменения подхватятся ТОЛЬКО после перезагрузки. Проверь DPC-латентность до/после."
  }

  # ---------- 7. Report / Apply / Restore ----------
  function Show-PhxReport {
    Write-Log ""
    Write-Log ("== REPORT: план изменений (" + $script:Targets.Count + " позиций) ==")
    $i = 0
    foreach ($t in $script:Targets) {
      $i++
      if ($t.Svc) {
        $cur = (Get-Service -Name $t.Svc -ErrorAction SilentlyContinue)
        $curS = if ($cur) { $cur.StartType.ToString() } else { 'ABSENT' }
        Write-Log ("  {0,3}. [svc ] {1}: {2} -> {3} | risk {4} | {5} | {6}" -f $i, $t.Svc, $curS, $t.StartType, $t.Risk, $t.Src, $t.Note)
      } elseif ($t.Task) {
        $task = Get-ScheduledTask -TaskPath ((Split-Path $t.Task) + '\') -TaskName (Split-Path $t.Task -Leaf) -ErrorAction SilentlyContinue
        $curS = if ($task) { $task.State.ToString() } else { 'ABSENT' }
        Write-Log ("  {0,3}. [task] {1}: {2} -> Disabled | risk {3} | {4} | {5}" -f $i, $t.Task, $curS, $t.Risk, $t.Src, $t.Note)
      } else {
        $cur = Get-PhxValue $t.Path $t.Name
        $curS = if ($null -eq $cur) { 'absent' } else { $cur }
        Write-Log ("  {0,3}. [reg ] {1}\{2}: {3} -> {4} | risk {5} | {6} | {7}" -f $i, $t.Path, $t.Name, $curS, $t.Value, $t.Risk, $t.Src, $t.Note)
      }
    }
    $regN = ($script:Targets | Where-Object { -not $_.Svc -and -not $_.Task }).Count
    $svcN = ($script:Targets | Where-Object { $_.Svc }).Count
    $tskN = ($script:Targets | Where-Object { $_.Task }).Count
    Write-Log ("Итого: reg " + $regN + " | сервисы " + $svcN + " | задачи " + $tskN)
    Write-Log "Режим Report - НИЧЕГО не изменено. Для применения: \$PhxMode='Apply' и повторить вставку."
  }

  function Invoke-PhxApply {
    Write-Log ""
    Write-Log ("== APPLY: применение (" + $script:Targets.Count + " позиций) ==")
    # Сначала PRE-экспорт всех reg-целей (двойная страховка против журнала)
    Export-PhxReg
    $cat = ''
    foreach ($t in $script:Targets) {
      if ($t.Cat -ne $cat) { $cat = $t.Cat; Write-Log ("-- " + $cat.ToUpper() + " --") }
      if ($t.Svc) {
        $svc = Get-Service -Name $t.Svc -ErrorAction SilentlyContinue
        if ($svc) {
          try { Set-Service -Name $t.Svc -StartupType $t.StartType -ErrorAction Stop; Set-EV1 ("svc " + $t.Svc) $true ($svc.StartType.ToString() + " -> " + $t.StartType) }
          catch { Set-EV1 ("svc " + $t.Svc) $false $_.Exception.Message }
        } else { Set-EV1 ("svc " + $t.Svc) $false 'служба отсутствует' }
        continue
      }
      if ($t.Task) {
        $tp = (Split-Path $t.Task) + '\'; $tn = Split-Path $t.Task -Leaf
        $task = Get-ScheduledTask -TaskPath $tp -TaskName $tn -ErrorAction SilentlyContinue
        if ($task) {
          try { Disable-ScheduledTask -TaskPath $tp -TaskName $tn -ErrorAction Stop | Out-Null; Set-EV1 ("task " + $tn) $true 'disabled' }
          catch { Set-EV1 ("task " + $tn) $false $_.Exception.Message }
        } else { Set-EV1 ("task " + $tn) $false 'задача отсутствует' }
        continue
      }
      $ok = Set-PhxValue $t.Path $t.Name $t.Value $t.Type
      Set-EV1 ("reg " + (Split-Path $t.Path -Leaf) + '\' + $t.Name) $ok ("-> " + $t.Value + " (risk " + $t.Risk + ")")
    }
    Invoke-PhxPower
    if ($PhxNicLowLat)  { Invoke-PhxNic }
    if ($PhxMsiGpuNvme) { Invoke-PhxMsi }
    Save-PhxJournal
  }

  function Invoke-PhxRestore {
    Write-Log ""
    Write-Log "== RESTORE из журнала =="
    if (-not (Test-Path $journalPath)) { Write-Log "!! Журнал не найден: $journalPath"; return }
    $j = Get-Content -LiteralPath $journalPath -Raw | ConvertFrom-Json
    foreach ($r in $j) {
      try {
        if ($r.WasPresent) {
          New-ItemProperty -LiteralPath $r.Path -Name $r.Name -Value $r.Old -PropertyType $r.Kind -Force | Out-Null
          $script:PhxRestored++
        } else {
          Remove-ItemProperty -LiteralPath $r.Path -Name $r.Name -ErrorAction SilentlyContinue
          $script:PhxRestored++
        }
      } catch { Write-Log ("  !! не восстановлено " + $r.Path + "\" + $r.Name + ": " + $_.Exception.Message) }
    }
    Write-Log ("Восстановлено значений: " + $script:PhxRestored + " из " + $j.Count)
    Write-Log "Сервисы/задачи/мощность/NIC-пресет восстанавливаются вручную (см. TWEAK-MATRIX.md и reg_export/*.reg)."
  }

  # ---------- 8. Диспетчер режимов + итог ----------
  switch ($PhxMode) {
    'Report'  { Show-PhxReport }
    'Apply'   { Invoke-PhxApply }
    'Restore' { Invoke-PhxRestore }
    default   { Write-Log "!! Неизвестный режим: $PhxMode (Report|Apply|Restore)" }
  }

  Write-Log ""
  Write-Log "== ИТОГ PHOENIX TWEAKPACK =="
  Write-Log ("  [x] применено: " + $script:PhxOk + " | [--] пропущено: " + $script:PhxSkip + " | восстановлено: " + $script:PhxRestored)
  if ($script:PhxEV1.Count -gt 0) {
    Write-Log "Список ЭВ.1 (недоступно = НЕ сделано):"
    foreach ($e in $script:PhxEV1) { Write-Log ("    - " + $e) }
  }
  Write-Log ("Журнал: " + $log)
  Write-Log ("Бэкап:  " + $bdir)
}
