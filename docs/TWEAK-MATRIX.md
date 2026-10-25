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

---

## 5. v1.1 — СИНТЕЗ (октябрь 2026): лучшее от всех + своё

База синтеза: выгрузка config/tweaks.json WinUtil (API, 69 КБ разобран), практики O&O ShutUp10++,
позиция Atlas, полный каталог TweakHub. Источники в поле Src каждой позиции пака:
TH=TweakHub, WU=WinUtil, OO=ShutUp10++, ATLAS-OPT=опция Atlas, PHX=своё.

| Что добавлено в v1.1 | Откуда | Зачем |
|---|---|---|
| CDM-набор из 8 значений ContentDeliveryManager | O&O ShutUp10++ | у TH только ConsumerFeatures; это режет ВСЮ рекламу/тихие установки/карусель локскрина |
| NumberOfSIUFInPeriod=0 (опросники), Cortana off, FindMyDevice off, Start_TrackProgs=0 | O&O ShutUp10++ | закрыть остатки телеметрии-фидбека |
| Геолокация: lfsvc off, ConsentStore location Deny, карты AutoUpdate off | WinUtil Location | приватность уровня сервисов |
| Сервисы: CscService off, MapsBroker Manual, SharedAccess (ICS) off, RetailDemo off, RemoteRegistry off | WinUtil Services + своё (RemoteRegistry — security-hardening) | фоновая нагрузка + закрыть удалённый доступ к реестру |
| SvcHostSplitThresholdInKB >= RAM | WinUtil, свой расчёт по Win32_PhysicalMemory | один svchost вместо десятков; на <6 ГБ НЕ применяем (там сплит полезен) |
| Teredo off (бит 1 Tcpip6 DisabledComponents) | WinUtil | латентность; IPv6 сознательно НЕ выключаем |
| Микро-анимации: TaskbarAnimations/ListviewAlphaSelect/ListviewShadow/AeroPeek/KeyboardDelay/StorageSense 01=0 | WinUtil Display | дополнение к VisualFX=2 |
| QoL-блок (флаг): классическое контекст-меню, расширения/скрытые файлы, NumLock при загрузке (HKU\.Default + HKCU), залипание off, verbose-логон, LongPaths | WinUtil Customize | вкус сборщика; verbose-логон ещё и диагностика |
| Reserved Storage off / disablelastaccess | WinUtil / Atlas | по флагам, по умолчанию off |
| VBS/HVCI off | опция Atlas | ТОЛЬКО с $PhxAdvancedRisk, помечено «МИНУС защита» — против нашего дефолта, выбор за Хозяином |
| Виджеты off политикой Dsh AllowNewsAndInterests | WinUtil + PHX-вариант | чище Appx-сноса WinUtil: откатываемо, пакет не сносим |

### Своё в v1.1 — то, чего нет НИ У КОГО из четырёх:

1. **Verify-loop**: после каждой записи значение перечитывается и сверяется; не совпало — [--] и видно в логе. TweakHub/WinUtil/Atlas пишут вслепую.
2. **rollback.ps1-генератор**: рядом с журналом пишется самодостаточный скрипт отката — откат даже без пака, без знания PS.
3. **Тройное резервирование**: JSON-журнал + целые ключи reg_export/*.reg + опциональная точка восстановления Win (флаг).
4. **SHA256 журнала** в логе (Law 4) — целостность артефакта отслеживается.
5. **Авто-детекции решают вместо человека**: диск (SysMain), GPU (HAGS), RAM (svchost) — у WinUtil это ручные галки в разных местах, у TH — ручные тумблеры без проверки железа.
6. **Report-режим** — сухой прогон со списком ЭВ.1 до любых изменений.
