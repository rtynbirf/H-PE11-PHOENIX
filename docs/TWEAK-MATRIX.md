# H-PE11 // TWEAK-MATRIX: PHOENIX TWEAKPACK против TweakHub / WinUtil / Atlas

Закон: ЧЕЛОВЕК = СИСТЕМА = ЦЕЛОЕ. ЭВ.1: недоступно = НЕ сделано (метка `[--]`).
Дата: 2026-10-25. База сравнения: TweakHub v1.5.0 (24c0a6b, аудит TH-AUDIT-1),
WinUtil 2026 (christitus.com/winutil-in-2026), Atlas v0.5.0 (21.10.2025, 24H2/25H2).

## 1. Что откуда в PHX_TWEAKPACK.ps1

Категория | Твик | Источник | Статус в PHX
---|---|---|---|---
cpu | Win32PrioritySeparation 0x26 | TweakHub | перенос [x]
cpu | DisableWpbtExecution 1 | TweakHub | перенос [x]
net | NetworkThrottlingIndex -1 | TweakHub | перенос, помечен «эффект от системы к системе» (тренд-тесты 2026 смешанные) [x]
net | DOPercentageMaxBackgroundBandwidth 30 | TweakHub | перенос [x]
net | DODownloadMode 1 | PHX | своё эмерджентное [x]
net | NIC-пресет (InterruptModeration/EEE/GreenEthernet/FlowControl/буферы) | TweakHub (NetworkAdapterService) | перенос из UI в пакет [x]
game | GameDVR_FSEBehaviorMode 2, AppCaptureEnabled 0 | TweakHub | перенос [x]
game | AllowGameDVR 0 (HKLM-политика) | TweakHub+WinUtil | перенос с улучшением: TH ставит только HKCU [x]
game | AllowAutoGameMode 1 | PHX | своё: GameMode ДЕРЖИМ (позиция Atlas) [x]
game | HwSchMode 2 (HAGS) | TweakHub | перенос с улучшением: гейт по детекции GPU, иначе ИСКЛЮЧЁН [--] если GPU не распознан
resp | MenuShowDelay 0, StartupDelayInMSec 0, TaskbarEndTask 1, MinAnimate 0, мышь (полная тройка), прозрачность/визуальные эффекты | TweakHub | перенос [x]
mem | SysMain/Prefetcher | TweakHub (off-твики) | ПЕРЕРАБОТАНО: по умолчанию НЕ трогаем; авто-решение по типу диска; принудительный off только флагом $PhxForceSysMainOff (позиция Atlas v0.4.1+: SysMain держат) [x]
priv | AllowTelemetry 0, EnableActivityFeed 0, AdvertisingInfo 0, TailoredExperiences 0, DisableWindowsConsumerFeatures 1, DisableSearchBoxSuggestions 1, SettingsPageVisibility hide:aicomponents | TweakHub | перенос [x]
priv | DiagTrack/dmwappushservice Disabled, diagnosticshub Manual, CEIP-задачи (Compatibility Appraiser, ProgramDataUpdater, Consolidator, Siuf DmClient) | PHX | своё эмерджентное: СЕРВИСНЫЙ уровень, у TH только политики [x]
wu | Security-режим (фичи +365д, секьюрити +4д, без авто-ребута) | WinUtil 2026 | тренд-перенос [x]
wu | ExcludeWUDriversInQualityUpdate 1 | TweakHub | перенос (наш конвейер сам катает драйверы) [x]
pow | HiberbootEnabled 0 (fast startup off) | TweakHub | перенос, согласовано с BCD-линией H-PE11 [x]
misc | DisplayParameters 1 (подробный BSOD), PreventDeviceMetadataFromNetwork 1 | TweakHub | перенос [x]
misc | SearchOrderConfig 0 | TweakHub | перенос ТОЛЬКО при флаге $PhxAdvancedRisk (risk 5) [--] по умолчанию
misc | WSearch Disabled | TweakHub | только флагом $PhxWSearchOff [--] по умолчанию
msi | MSI mode GPU/NVMe | TweakHub (InterruptService) | перенос из UI в пакет, опция $PhxMsiGpuNvme [--] по умолчанию
power | PROCTHROTTLEMIN 100, CPMINCORES 100 (AC) | TweakHub (PowerService) | перенос через powercfg, локалезависимый разбор заменён regex-GUID [x]

## 2. Чего сознательно НЕ взяли и почему

| Пункт | Кто | Почему отвергнут |
|---|---|---|
| TcpAckFrequency/TCPNoDelay | гайды 2010-х (в TH тоже нет) | плацебо/риск на современном стеке Win11; latency закрываем NIC-пресетом + NTI |
| Полное отключение WU | TH-пресет Disabled | тренд WinUtil 2026: умнее задержки 365д/4д; полное отключение только для изолированных машин |
| Off по умолчанию для SysMain/Prefetcher | TH (risk 3) | Atlas v0.4.1+ вернул SysMain «для отзывчивости»; на HDD prefetch критичен; решаем по детекции диска |
| Игнорирование GPU при HAGS | TH ставит безусловно | сообщество 2026: HAGS зависит от GPU; у нас гейт по детекции |
| UI-оболочка поверх твиков | TweakHub целиком | нам нужен paste-and-run в стиль бомб-скриптов H-PE11, без .NET 10 рантайма в эталоне |

## 3. Чем PHX-пак сильнее TweakHub (эмерджентное)

1. Персистентный бэкап: JSON-журнал + ЦЕЛЫЕ ключи reg_export/*.reg + power_scheme_before.pow — восстановление возможно даже без нашего пака, любым regedit. TH держит бэкап в своём AppData и восстанавливает только собой.
2. Авто-решения по железу: тип диска (SysMain/Prefetch/WSearch), поддержка GPU (HAGS), адаптеры (NIC-пресет только Up).
3. Сервисно-планировочный уровень телеметрии (DiagTrack, dmwappushservice, CEIP-задачи) — TH ограничивается политиками реестра.
4. Режим Report — сухой прогон: показывает текущее -> целевое, НИЧЕГО не трогая; Apply пишет журнал до изменений; Restore возвращает по журналу.
5. Метрики ЭВ.1 и лог на рабочий стол — единый стандарт честности с бомб-скриптами H-PE11: недоступно = НЕ сделано.
6. Разделение «запечь в эталон» vs «после деплоя»: HKLM/сервисы/WU/питание — в эталон (секции 16-17 Task'ов), HKCU-блок — после первого логона (copyprofile их не переносит).

## 4. Куда встраивать в конвейер PHOENIX

| Этап | Режим пака | Флаги |
|---|---|---|
| Эталон в ВМ, перед sysprep | Apply | все категории, HKLM-часть; флаги Advanced/Msi/Search по месту |
| После деплоя, первый логон | Apply | HKCU-часть (resp-категория) от имени пользователя |
| Диагностика чужой станции | Report | ничего не меняет, лог показывает план |
| Откат | Restore | по журналу последнего Apply + reg_export/*.reg |
