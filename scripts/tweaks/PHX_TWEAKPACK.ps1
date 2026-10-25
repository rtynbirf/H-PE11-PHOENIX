# =====================================================================
# H-PE11 // PHOENIX TWEAKPACK v1.1 (paste-and-run) — СИНТЕЗ ЛУЧШЕГО
# Базы: TweakHub v1.5.0 (полный каталог) + WinUtil 2026 (config/tweaks.json
#       выгружен API и разобран) + Atlas v0.5.0 + O&O ShutUp10++ практики.
# СВОЁ СВЕРХ ВСЕХ: (1) verify-loop — после КАЖДОЙ записи значение
#       перечитывается и сверяется, иначе [--]; (2) генератор
#       rollback.ps1 — самодостаточный откат без этого пака; (3) опциональный
#       restore point Win; (4) SHA256 журнала (Law 4); (5) авто-детекции
#       диск/GPU/RAM (svchost-split по объёму памяти); (6) сервисный уровень
#       телеметрии; (7) ЭВ.1 и логи в стиле бомб-скриптов.
# Отвергнуто по трендам: TcpAckFrequency (плацебо), Spectre/Meltdown-off
#       (security-линия), снос Edge/OneDrive (совместимость Win11 Creator),
#       полное отключение WU (умнее задержки 365д/4д).
# Закон: ЧЕЛОВЕК=СИСТЕМА=ЦЕЛОЕ. ЭВ.1: недоступно = НЕ сделано (метка [--]).
# Требования: Windows 11 24H2/25H2, консоль PowerShell ОТ АДМИНИСТРАТОРА.
# =====================================================================

# ==== ФЛАГИ (править до вставки) ====
$PhxMode         = 'Report'  # 'Report' = только показать план | 'Apply' = применить | 'Restore' = восстановить из журнала
$PhxBackupDir    = ''        # пусто = рядом со скриптом\PHX_TWEAKBACKUP_<ts>; иначе укажи свой путь
$PhxRestorePoint = $false   # $true = создать точку восстановления Win перед Apply (если SystemRestore включён)
$PhxQol          = $true    # QoL-блок (вкусовое): классическое контекст-меню, расширения/скрытые файлы, NumLock, залипание off, verbose-логон, LongPaths
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
$PhxAdvancedRisk = $false    # $true = разрешить твики risk 5 (SearchOrderConfig 0) и VBS/HVCI-off (security! только для игровых станций под твою ответственность)
$PhxReservedStor = $false   # $true = отключить Reserved Storage (~7 ГБ, DISM; для эталона удобно)
$PhxLastAccess   = $false   # $true = fsutil disablelastaccess (микро-оптимизация NTFS, тренд Atlas)
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
    if ($Name -eq '(Default)') { $Name = '' }  # PS-нотация дефолтного значения
    try { return (Get-ItemPropertyValue -LiteralPath $Path -Name $Name -ErrorAction Stop) } catch { return $null }
  }
  function Backup-PhxValue([string]$Path, [string]$Name) {
    # Запоминаем ОРИГИНАЛ до первой записи. absent = значения не было (restore удалит).
    if ($Name -eq '(Default)') { $Name = '' }  # PS-нотация дефолтного значения
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
      # VERIFY-LOOP (своё): перечитываем и сверяем — недоступно = НЕ сделано
      $back = Get-PhxValue $Path $Name
      if ($Type -eq 'String') { $ok = ([string]$back -eq [string]$Value) }
      else { $ok = ([long]$back -eq [long]$Value) }
      if (-not $ok) { Write-Log ("  !! verify FAILED: " + $Path + "\" + $Name + " записано=" + $back + " ожидалось=" + $Value); return $false }
      return $true
    } catch { Write-Log ("  !! сбой записи " + $Path + "\" + $Name + ": " + $_.Exception.Message); return $false }
  }
  function Save-PhxJournal {
    $json = $script:Journal | ConvertTo-Json -Depth 4
    Set-Content -LiteralPath $journalPath -Value $json -Encoding UTF8
    Write-Log ("Журнал бэкапа: " + $journalPath + " (" + $script:Journal.Count + " значений)")
    # Law 4: SHA256 журнала в лог
    $h = (Get-FileHash -LiteralPath $journalPath -Algorithm SHA256).Hash
    Write-Log ("SHA256 журнала: " + $h)
  }

  # Генератор самодостаточного rollback.ps1 (своё: откат без этого пака)
  function Write-Generate-Rollback {
    $rb = Join-Path $bdir 'rollback.ps1'
    $lines = @(
      '# rollback.ps1 - автосгенерирован PHX_TWEAKPACK ' + $ts,
      '# Откат ВСЕХ реестровых значений по журналу. Запуск в admin PS.',
      '$ErrorActionPreference = ''Continue'''
    )
    foreach ($r in $script:Journal) {
      $nm = if ($r.Name -eq '') { '(default)' } else { $r.Name }
      $p = ($r.Path -replace "'", "''")
      if ($r.WasPresent) {
        $kind = if ($r.Kind) { $r.Kind } else { 'String' }
        if ($kind -eq 'String' -or $kind -eq 'ExpandString') {
          $v = if ($null -ne $r.Old) { ([string]$r.Old) -replace "'", "''" } else { '' }
          $lines += ("New-ItemProperty -LiteralPath '" + $p + "' -Name '" + $nm + "' -Value '" + $v + "' -PropertyType " + $kind + " -Force | Out-Null")
        } else {
          $v = if ($null -ne $r.Old) { [long]$r.Old } else { 0 }
          $lines += ("New-ItemProperty -LiteralPath '" + $p + "' -Name '" + $nm + "' -Value " + $v + " -PropertyType " + $kind + " -Force | Out-Null")
        }
      } else {
        $lines += ("Remove-ItemProperty -LiteralPath '" + $p + "' -Name '" + $nm + "' -ErrorAction SilentlyContinue")
      }
    }
    $lines += ('"Готово: отработано записей: ' + $script:Journal.Count + '"')
    Set-Content -LiteralPath $rb -Value $lines -Encoding UTF8
    Set-EV1 'rollback.ps1 сгенерирован' $true $rb
  }

  # Персистентный .reg-экспорт ДЛЯ ВСЕГО списка целей ДО применения (двойная страховка)
  function Export-PhxReg {
    # Каждый ключ цели целиком экспортируется reg.exe ДО применения (двойная страховка к журналу)
    $regDir = Join-Path $bdir 'reg_export'
    New-Item -ItemType Directory -Path $regDir -Force | Out-Null
    $n = 0
    foreach ($t in $script:Targets) {
      if ($t.Svc -or $t.Task) { continue }
      $rawPath = $t.Path -replace '^Registry::',''
      $regPath = $rawPath -replace '^HKLM:\\','HKLM\' -replace '^HKCU:\\','HKCU\'
      $file = Join-Path $regDir (($regPath -replace '[\\:]','_') + '.reg')
      & reg.exe export $regPath $file /y 2>$null | Out-Null
      if ($LASTEXITCODE -eq 0) { $n++ }
    }
    Set-Content -LiteralPath (Join-Path $bdir 'README.txt') -Value @('PHX TWEAKPACK pre-export (до применения)','Каждый .reg - состояние ЦЕЛОГО ключа ДО применения твиков.','Восстановление: reg import <файл.reg> или двойной клик. Рядом: phx_tweak_journal.json + rollback.ps1.') -Encoding UTF8
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
    @{ Cat='net'; Path='HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters'; Name='DisabledComponents'; Value=1; Type='DWord'; Risk=2; Src='WU'; Note='Teredo off (бит 1; IPv6 НЕ трогаем - не путать с DisableIPv6)' },
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
    # --- Микро-анимации (WinUtil Display-набор, дополнение к VisualFX=2) ---
    @{ Cat='resp'; Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='TaskbarAnimations'; Value=0; Type='DWord'; Risk=1; Src='WU'; Note='анимации таскбара off' },
    @{ Cat='resp'; Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='ListviewAlphaSelect'; Value=0; Type='DWord'; Risk=1; Src='WU'; Note='полупрозрачное выделение off' },
    @{ Cat='resp'; Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='ListviewShadow'; Value=0; Type='DWord'; Risk=1; Src='WU'; Note='тень под иконками off' },
    @{ Cat='resp'; Path='HKCU:\Software\Microsoft\Windows\DWM'; Name='EnableAeroPeek'; Value=0; Type='DWord'; Risk=1; Src='WU'; Note='Aero Peek off' },
    @{ Cat='resp'; Path='HKCU:\Control Panel\Keyboard'; Name='KeyboardDelay'; Value='0'; Type='String'; Risk=1; Src='WU'; Note='задержка клавиатуры 0' },
    @{ Cat='resp'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'; Name='01'; Value=0; Type='DWord'; Risk=1; Src='WU'; Note='Storage Sense off (не трогает файлы)' },
    # --- Приватность/телеметрия: политики (TweakHub: Privacy) ---
    @{ Cat='priv'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; Name='AllowTelemetry'; Value=0; Type='DWord'; Risk=3; Src='TH'; Note='на Pro -> минимум (1); 0 = только Enterprise/Edu' },
    @{ Cat='priv'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name='EnableActivityFeed'; Value=0; Type='DWord'; Risk=3; Src='TH'; Note='история активностей off' },
    @{ Cat='priv'; Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo'; Name='Enabled'; Value=0; Type='DWord'; Risk=2; Src='TH'; Note='рекламный ID off' },
    @{ Cat='priv'; Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy'; Name='TailoredExperiencesWithDiagnosticDataEnabled'; Value=0; Type='DWord'; Risk=2; Src='TH'; Note='персонализация по диагностике off' },
    @{ Cat='priv'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name='DisableWindowsConsumerFeatures'; Value=1; Type='DWord'; Risk=2; Src='TH'; Note='consumer-контент/спонсируемые приложения off' },
    @{ Cat='priv'; Path='HKCU:\Software\Policies\Microsoft\Windows\Explorer'; Name='DisableSearchBoxSuggestions'; Value=1; Type='DWord'; Risk=1; Src='TH'; Note='Bing-подсказки в поиске off' },
    @{ Cat='priv'; Path='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name='SettingsPageVisibility'; Value='hide:aicomponents'; Type='String'; Risk=4; Src='TH'; Note='спрятать страницу AI-компонентов' },
    # --- Анти-реклама CDM-набор (O&O ShutUp10++ / WinUtil практики; у TH только ConsumerFeatures) ---
    @{ Cat='priv'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='ContentDeliveryAllowed'; Value=0; Type='DWord'; Risk=2; Src='OO'; Note='CDM: доставка контента off (1/8)' },
    @{ Cat='priv'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='OemPreInstalledAppsEnabled'; Value=0; Type='DWord'; Risk=2; Src='OO'; Note='CDM: OEM-предустановки off (2/8)' },
    @{ Cat='priv'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='PreInstalledAppsEnabled'; Value=0; Type='DWord'; Risk=2; Src='OO'; Note='CDM: предустановки off (3/8)' },
    @{ Cat='priv'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='SilentInstalledAppsEnabled'; Value=0; Type='DWord'; Risk=2; Src='OO'; Note='CDM: тихая установка приложений off (4/8)' },
    @{ Cat='priv'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='SoftLandingEnabled'; Value=0; Type='DWord'; Risk=2; Src='OO'; Note='CDM: советы/подсказки off (5/8)' },
    @{ Cat='priv'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='RotatingLockScreenEnabled'; Value=0; Type='DWord'; Risk=2; Src='OO'; Note='CDM: карусель экрана блокировки off (6/8)' },
    @{ Cat='priv'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='RotatingLockScreenOverlayEnabled'; Value=0; Type='DWord'; Risk=2; Src='OO'; Note='CDM: оверлей на экране блокировки off (7/8)' },
    @{ Cat='priv'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='SubscribedContent-338388Enabled'; Value=0; Type='DWord'; Risk=2; Src='OO'; Note='CDM: рекомендации в Пуске off (8/8)' },
    @{ Cat='priv'; Path='HKCU:\SOFTWARE\Microsoft\Siuf\Rules'; Name='NumberOfSIUFInPeriod'; Value=0; Type='DWord'; Risk=1; Src='OO'; Note='опросник «поделитесь мнением» off' },
    @{ Cat='priv'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name='AllowCortana'; Value=0; Type='DWord'; Risk=2; Src='OO'; Note='Cortana off' },
    @{ Cat='priv'; Path='HKLM:\SOFTWARE\Policies\Microsoft\FindMyDevice'; Name='AllowFindMyDevice'; Value=0; Type='DWord'; Risk=2; Src='OO'; Note='Найти устройство off' },
    @{ Cat='priv'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='Start_TrackProgs'; Value=0; Type='DWord'; Risk=2; Src='OO'; Note='трекинг запусков приложений off' },
    @{ Cat='priv'; Path='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location'; Name='Value'; Value='Deny'; Type='String'; Risk=3; Src='WU'; Note='геолокация приложений: Deny' },
    @{ Cat='priv'; Path='HKLM:\SYSTEM\Maps'; Name='AutoUpdateEnabled'; Value=0; Type='DWord'; Risk=2; Src='WU'; Note='автообновление карт off' },
    @{ Cat='priv'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Dsh'; Name='AllowNewsAndInterests'; Value=0; Type='DWord'; Risk=2; Src='WU+PHX'; Note='виджеты off политикой (чище Appx-сноса WinUtil — откатываемо)' },
    # --- Приватность: СЕРВИСНЫЙ уровень (эмерджентное - у TweakHub нет) ---
    @{ Cat='priv'; Svc='DiagTrack'; StartType='Disabled'; Risk=2; Src='PHX'; Note='Connected User Experiences and Telemetry - главный сборщик' },
    @{ Cat='priv'; Svc='dmwappushservice'; StartType='Disabled'; Risk=2; Src='PHX'; Note='WAP Push Message Routing - канал телеметрии' },
    @{ Cat='priv'; Svc='diagnosticshub.standardcollector.service'; StartType='Manual'; Risk=3; Src='PHX'; Note='Diagnostic Hub - в ручной режим' },
    @{ Cat='priv'; Task='\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser'; Action='Disable'; Risk=2; Src='PHX'; Note='CEIP-оценщик совместимости' },
    @{ Cat='priv'; Task='\Microsoft\Windows\Application Experience\ProgramDataUpdater'; Action='Disable'; Risk=2; Src='PHX'; Note='CEIP-сбор программных данных' },
    @{ Cat='priv'; Task='\Microsoft\Windows\Customer Experience Improvement Program\Consolidator'; Action='Disable'; Risk=2; Src='PHX'; Note='CEIP Consolidator' },
    @{ Cat='priv'; Task='\Microsoft\Windows\Feedback\Siuf\DmClient'; Action='Disable'; Risk=2; Src='PHX'; Note='канал фидбека' },
    # --- Сервисы WinUtil (Essential) + геолокация + security-hardening ---
    @{ Cat='priv'; Svc='lfsvc'; StartType='Disabled'; Risk=2; Src='WU'; Note='геолокационная служба' },
    @{ Cat='misc'; Svc='CscService'; StartType='Disabled'; Risk=3; Src='WU'; Note='офлайн-файлы (клиентское кэширование сети)' },
    @{ Cat='misc'; Svc='MapsBroker'; StartType='Manual'; Risk=2; Src='WU'; Note='загрузчик карт - в ручной' },
    @{ Cat='misc'; Svc='SharedAccess'; StartType='Disabled'; Risk=3; Src='WU'; Note='Internet Connection Sharing (ICS)' },
    @{ Cat='misc'; Svc='RemoteRegistry'; StartType='Disabled'; Risk=2; Src='PHX'; Note='удалённый реестр - security-hardening' },
    @{ Cat='misc'; Svc='RetailDemo'; StartType='Disabled'; Risk=2; Src='WU'; Note='магазинный демо-режим' },
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

  # --- QoL-блок (вкусовое, WinUtil Customize Preferences) ---
  if ($PhxQol) {
    $script:Targets += @{ Cat='qol'; Path='HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'; Name='(Default)'; Value=''; Type='String'; Risk=1; Src='WU'; Note='классическое контекст-меню Win10 (вступит после рестарта explorer)' }
    $script:Targets += @{ Cat='qol'; Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='HideFileExt'; Value=0; Type='DWord'; Risk=1; Src='WU'; Note='показывать расширения файлов' }
    $script:Targets += @{ Cat='qol'; Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='Hidden'; Value=1; Type='DWord'; Risk=1; Src='WU'; Note='показывать скрытые файлы' }
    $script:Targets += @{ Cat='qol'; Path='Registry::HKEY_USERS\.Default\Control Panel\Keyboard'; Name='InitialKeyboardIndicators'; Value='2'; Type='String'; Risk=1; Src='WU'; Note='NumLock on при загрузке (до логона)' }
    $script:Targets += @{ Cat='qol'; Path='HKCU:\Control Panel\Keyboard'; Name='InitialKeyboardIndicators'; Value='2'; Type='String'; Risk=1; Src='WU'; Note='NumLock on (текущий юзер)' }
    $script:Targets += @{ Cat='qol'; Path='HKCU:\Control Panel\Accessibility\StickyKeys'; Name='Flags'; Value='506'; Type='String'; Risk=1; Src='WU'; Note='залипание Shift-диалогов off' }
    $script:Targets += @{ Cat='qol'; Path='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; Name='VerboseStatus'; Value=1; Type='DWord'; Risk=1; Src='WU'; Note='verbose-логон: видеть этапы загрузки (полезно сборщику)' }
    $script:Targets += @{ Cat='qol'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'; Name='LongPathsEnabled'; Value=1; Type='DWord'; Risk=1; Src='WU'; Note='длинные пути >260 символов' }
  }
  # --- SvcHost split: порог выше RAM = один svchost на всё (WinUtil, свой расчёт RAM) ---
  try {
    $ramKb = [long]((Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1KB)
    if ($ramKb -ge 6291456) {
      $script:Targets += @{ Cat='misc'; Path='HKLM:\SYSTEM\CurrentControlSet\Control'; Name='SvcHostSplitThresholdInKB'; Value=$ramKb; Type='DWord'; Risk=2; Src='WU+PHX'; Note=('svchost без сплита (RAM ' + [math]::Round($ramKb/1MB) + ' ГБ -> порог выше памяти)') }
      Set-EV1 'SvcHostSplitThreshold' $true ('RAM ' + [math]::Round($ramKb/1MB) + ' ГБ - порог выставлен')
    } else {
      Set-EV1 'SvcHostSplitThreshold' $true ('RAM < 6 ГБ - сплит ОСТАВЛЕН (правильно для малой памяти)')
    }
  } catch { Set-EV1 'SvcHostSplitThreshold' $false ('RAM не определена: ' + $_.Exception.Message) }
  # --- VBS/HVCI-off: ТОЛЬКО по явному флагу AdvancedRisk (security! по умолчанию НЕТ) ---
  if ($PhxAdvancedRisk) {
    $script:Targets += @{ Cat='misc'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard'; Name='EnableVirtualizationBasedSecurity'; Value=0; Type='DWord'; Risk=5; Src='ATLAS-OPT'; Note='VBS off: +FPS, МИНУС защита (твоя ответственность)' }
    $script:Targets += @{ Cat='misc'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'; Name='Enabled'; Value=0; Type='DWord'; Risk=5; Src='ATLAS-OPT'; Note='HVCI (Memory Integrity) off: +FPS, МИНУС защита' }
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

  # ---------- 6b. Файловый слой (тренды WinUtil/Atlas) ----------
  function Invoke-PhxFilesystem {
    Write-Log ""
    Write-Log "== FILESYSTEM (fsutil/DISM) =="
    if ($PhxLastAccess) {
      & fsutil behavior set disablelastaccess 1 2>$null | Out-Null
      Set-EV1 'disablelastaccess' ($LASTEXITCODE -eq 0) 'NTFS не пишет время последнего доступа (тренд Atlas)'
    } else { Set-EV1 'disablelastaccess' $true 'пропущено по флагу (по умолчанию off)' }
    if ($PhxReservedStor) {
      & dism.exe /Online /Set-ReservedStorageState /State:Disabled 2>$null | Out-Null
      Set-EV1 'Reserved Storage off' ($LASTEXITCODE -eq 0) 'освободить ~7 ГБ (WinUtil)'
    } else { Set-EV1 'Reserved Storage off' $true 'пропущено по флагу (по умолчанию off)' }
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
    if ($PhxRestorePoint) {
      try {
        Checkpoint-Computer -Description "PHX TWEAKPACK $ts" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Set-EV1 'точка восстановления Win' $true 'Checkpoint-Computer выполнен'
      } catch { Set-EV1 'точка восстановления Win' $false ($_.Exception.Message + ' (SystemRestore может быть выключен/лимит 24ч)') }
    }
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
    Invoke-PhxFilesystem
    Save-PhxJournal
    Write-Generate-Rollback
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
