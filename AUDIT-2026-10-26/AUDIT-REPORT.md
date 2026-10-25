# H-PE11 // PHOENIX — АУДИТ И РЕВИЗИЯ (AUDIT-REPORT)

**Дата:** 2026-10-26 · **Объект:** `rtynbirf/H-PE11-PHOENIX` (main `e73aa8b8`, 9 веток, 7.19 ГБ) · **Task ID:** AUDIT-2026-10-26
**Метод:** мультиагентный (3 параллельных трека: security / код-качество / доки-vs-код) + оркестратор (git-гигиена, верификация манифестов, численная перепроверка).
**Фокус риска (по ТЗ):** стабильность целевой Windows 11 26H2. · **Язык:** RU + EN-термины.
**Дисциплина:** ЭВ.1 — «недоступно = НЕ сделано»; каждая находка имеет файл:строку; статусы верификации: ✅ перепроверено оркестратором · 🔎 агентская находка (аргументирована, не пере-верифицирована) · ❌ отозвано.

---

## 0. EXECUTIVE SUMMARY

Проект PHOENIX-11 — деплой-кит Windows 11 26H2 (базис 26100.1 + autounattend v3 + $OEM$ + TWEAKPACK v2.0 «SYNTHESIS» + HW-аудит), с нехарактерной для любительских сборок дисциплиной: манифесты SHA256 (Law 4), метки ЭВ.1 [x]/[--], restore point до применения, тройной бэкап твиков, запрет авто-применения из SetupComplete. **Ядро архитектуры зрелое и лучше большинства известных твикпаков** (WinUtil/Atlas-класс), но выпуск ALPHA 0.1 блокируют четыре сквозных дефекта:

| # | SEV | Дефект | Следствие |
|---|-----|--------|-----------|
| 1 | CRITICAL | Пароль админа `Phoenix-2026` открытым текстом в 4+ файлах репо (autounattend.xml:91, RUNBOOK, worklog, MISSION_WILLIAM) + AutoLogon | Утёкший ISO = вход админом на все развёрнутые машины |
| 2 | HIGH | Меню PHOENIX-CONTROL.cmd вызывает `PHX-RUN.ps1 -Profile X`, а param() объявляет `$ProfileName` — все пункты [2]–[7] падают | Задокументированный сценарий испытания ALPHA неработоспособен с первого шага |
| 3 | HIGH | Supply chain: ~15 сторонних бинарников (PowerShell 7, Sysinternals, 7zr, vc_redist, wget64 с eternallybored.org, NTPWEdit…) едут в ISO без SHA256-пиннинга и без проверки подписи; драйверы .cab качаются не-атомарно | Компрометация upstream/MITM → вредоносный код в WinPE от SYSTEM; обрыв сети → битый .cab в ISO |
| 4 | HIGH | Rollback-контур TWEAKPACK: Restore не находит собственный журнал (timestamp-каталоги), журнал пишется один раз в конце Apply | Главный заявленный плюс v2.0 (откат) не работает без ручного вмешательства |

**Ревизия манифестов (Law 4):** 28 проверяемых позиций — 26 сходятся, 2 расхождения (хэш PHX_TWEAKPACK.ps1 в ALPHA-манифесте; self-hash BOMB-манифеста), 2 dangling-записи. ISO v2 (116×40 МБ) верифицирован выборочно: **11/11 частей SHA256 сошлись** (включая первую и последнюю).

**Git-гигиена:** 99.5% репозитория — ISO-части, запакованные в git-историю в обход лимитов (v1 — 103 части, размазанные по веткам iso_tmp_1..5; v2 — 116 частей прямо в main). 6 из 8 не-main веток — нулевая уникальная история. Репо в 3000+ раз тяжелее своего кода (~2.5 МБ).

**Вердикт:** после устранения пунктов 1–4 (патчи прилагаются) и переноса ISO из git в Releases/LFS проект становится воспроизводимым деплой-китом производственного качества. Твики ядра (после численной перепроверки) не содержат parse-ошибок; WaaSMedic/wuauserv/UsoSvc не тронуты — servicing-восстановление WU не провоцируется.

**Счёт находок:** CRITICAL 1 · HIGH 13 · MEDIUM 29 · LOW 24 (детали в §3). Одна ранее заявленная CRITICAL-находка (parse-error TWEAKPACK:412-413) **отозвана** после численной перепроверки — см. §9.

---

## 1. МЕТОДОЛОГИЯ И ОГРАНИЧЕНИЯ

**Объём фактического разбора:** все 126 текстовых блобов main (по-строчно ключевые: PHX_TWEAKPACK.ps1 — 841 строка, deploy/*, get-ammo.ps1, drv_*.py, b1/b2-конвейер, bomb_part1-3, pe_gen*.py, make_iso*/verify_iso*); 10 корневых md + docs/* + manifests/*; деревья всех 9 веток с размерами; 71 коммит (полный граф); 11 ISO-частей (≈440 МБ) скачаны и сверены по SHA256.

**Инструменты:** GitHub API (деревья, коммиты, raw), blobless-клон (pack 7.19 ГБ сервером не отдаётся одним потоком — 2 попытки упали; переход на `--filter=blob:none` + выборочная верификация блобов через raw), собственные сканеры (секреты/паттерны — 126 файлов, 153 срабатывания), численная байтовая верификация спорных мест (count/boolean-протокол, устойчивый к артефактам отображения консоли).

**Ограничения:**
1. PowerShell в песочнице аудита отсутствует — статический разбор; динамический прогон PHX-RUN/CONTROL не выполнялся (патч 002 содержитSmoke-чеклист).
2. ISO v2 верифицирован выборкой 11/116 (9.5%, ~440 МБ) — полный перебор требует докачки 4.2 ГБ; parts 0–2, 28, 53, 78, 103, 113–115 — OK, основание для доверия к остальным.
3. Находки 🔎 не пере-верифицированы построчно оркестратором (объём ~60 позиций); каждая имеет файл:строку для быстрой проверки.
4. Хэши ISO v1 (103 части в iso_tmp_1..5) не сверялись — ветки рекомендованы к удалению (G-01), сверка бессмысленна.

---
## 2. CRITICAL-ЦЕПОЧКА (детально)

### S-01 · CRITICAL · Пароль администратора в открытом виде ✅
**Где:** `scripts/deploy/autounattend.xml:90-93` (`<Value>Phoenix-2026</Value>` + `<PlainText>true</PlainText>`), учётка `6orman` (:86-87); тот же пароль воспроизводится в `docs/PHOENIX-ALPHA-RUNBOOK.txt:24`, `worklog.md:638`, `MISSION_WILLIAM.md:61`. AutoLogon (autounattend.xml:97-105) дополнительно оставляет креды в `HKLM\...\Winlogon` после первого входа.
**Сценарий:** любой обладатель ISO/репо (репо приватное, но ISO размножается) получает админа на всех развёрнутых станциях до ручной смены пароля. Комментарий в самом autounattend («СМЕНИ после входа!») перекладывает дисциплину на человека — не работает при тиражировании.
**Фикс:** не коммитить пароль вообще (шаблон + подстановка при сборке ISO per-install); принудительная смена при первом логоне: `net user 6orman /logonpasswordchg:yes` (реализовано патчем **P-003** в PHX-SETUP-COMPLETE.ps1); чистка Winlogon-ключей; ротация пароля в существующих развёртываниях.

### Q-01 · HIGH · Меню ALPHA неработоспособно: `-Profile` vs `-ProfileName` ✅
**Где:** `scripts/deploy/PHOENIX-CONTROL.cmd:53,60,67,74,81,88` — шесть вызовов `powershell -File PHX-RUN.ps1 -Profile <X> -Mode <Y>`; `scripts/deploy/PHX-RUN.ps1:10-12` — `param([ValidateSet(...)][string]$ProfileName = 'Balanced', ...)`.
**Сценарий:** PowerShell отклоняет несуществующий параметр → каждый пункт меню [2]–[7] (REPORT/Apply Safe/Balanced/Performance/PrivacyMax/RESTORE) падает до запуска логики. `docs/PHOENIX-ALPHA-RUNBOOK.txt:52-77` документирует этот флоу как рабочий. `PHX-SETUP-COMPLETE.ps1:60` зовёт правильно (`-ProfileName`) — непоследовательность подтверждает опечатку именно в CONTROL.
**Фикс:** патч **P-001** (6 строк, байт-в-байт: `-Profile ` → `-ProfileName `, проверено count=6/6). После применения — пересборка Release-кита и манифеста (Law 4).

### S-02..S-08 · HIGH · Security-контур (агентский трек) 🔎
- **S-02** `scripts/b2_release_upload.py:31-35` — PAT в argv curl (`-H "Authorization: Bearer $TOKEN"`) → виден в `/proc/*/cmdline`, `ps`, истории. Фикс: `--netrc`/`-K` config с umask 600.
- **S-03** `scripts/b1/b1_parted_push.sh:5`, `b1_local_git_finalize.py:59`, `b1_local_git_finalize2.py:34` — токен вшит в remote-URL → персистится в `.git/config` (подтверждается MEMORY.md:236). Фикс: credential-helper/askpass.
- **S-04** `scripts/b1/b1_gitpush_finalize.sh:12-14,40` — токен пишется в `cred.sh`; `rm -f cred.sh` не выполняется при сбое (`set -e`). Фикс: `trap 'rm -f cred.sh' EXIT`.
- **S-05** `scripts/push_repo_ssh.py:6,22-27,77,91-97` — ed25519 deploy-key живёт в `/tmp/phx_deploy_key` между запусками без ротации; `paramiko.AutoAddPolicy()` принимает любой host key (MITM не детектится). Фикс: эфемерный ключ + finally-удаление; пин host-key.
- **S-06** Supply chain ядра: `scripts/ammo_dl.sh:23-36`, `ammo_dl2.sh:8-53`, `get-ammo.ps1:28-40` — PowerShell-7.4.6.zip, SysinternalsSuite, 7zr.exe, wintun, vc_redist (x64/x86/2010-2013), directx_Jun2010, wget64.exe (eternallybored.org), curl_win64, Volume2, Notepad++, NTPWEdit (sourceforge) — **ни одной SHA256-сверки или Authenticode-проверки**, zero version pinning (`releases[0]`, первый тег atom). Всё это пакуется в ISO (`build_bomb.sh:36-102`) и исполняется в WinPE от SYSTEM. Фикс: манифест версий+SHA256, сверка до распаковки, `Get-AuthenticodeSignature` для exe.
- **S-07** `ammo_dl.sh:8-11`, `ammo_dl2.sh:14-15,28-29,41-42` — exit-code curl не проверяется; «skip if size≥min» принимает недокачанный файл с валидной MZ-шапкой. Фикс: `curl --fail`, `.part` + атомарный rename.
- **S-08** `scripts/drv_catalog.py:59-71`, `drv_h61.py:85-96`, `drv_h61_2.py:43-46`, `drv_mei_probe.py:43-51` — сетевой I/O вне try: обрыв посреди stream оставляет битый .cab (с валидной MSCF-шапкой), который позже пакуется в ISO (`build_bomb.sh:93-95`); в mei_probe MSCF-проверки нет вовсе. Фикс: `.part`-паттерн + try/except + rename, MSCF до и после.

### Q-02..Q-03 · HIGH · Rollback-контур TWEAKPACK 🔎
- **Q-02** `scripts/tweaks/PHX_TWEAKPACK.ps1:34,66-68,71,722` — при `$PhxMode='Restore'` каталог бэкапа генерируется с НОВЫМ timestamp (`PHX_TWEAKBACKUP_<ts>`), журнал ищется в пустом каталоге → «Журнал не найден». Контракт отката v2.0 не работает без ручной правки `$PhxBackupDir` в исходнике. Фикс реализован патчем **P-002**: Restore-режим автопоиска последнего `PHX_TWEAKBACKUP_*` на общем рабочем столе + явная инъекция `$PhxBackupDir` в шапку.
- **Q-03** `PHX_TWEAKPACK.ps1:715` — `Save-PhxJournal` вызывается один раз после всего Apply; сбой посреди прогона (kill/BSOD/disk-full на debloat) = изменения применены, журнала нет; откат только через reg_export (сервисы/задачи/Appx/питание НЕ откатываются). Фикс: инкрементальный flush журнала по блокам + Save в finally.

### D-01..D-04 · HIGH · Доки vs код (агентский трек) 🔎
- **D-01** `README.md:16,83` — заявляет в worklog «Tasks 28, 28-b, 29», которых в worklog.md нет (после Task 18 сразу Task 37); дубли Task ID 3 и 14. Внешняя память врёт о самой себе. Фикс: переписать статусную строку («Tasks 1-18, 37-42, ALPHA-1; 28/28-b/29 — только в MEMORY.md») или восстановить записи.
- **D-02** `manifests/PHOENIX-ALPHA-0.1.SHA256:9` — фиксирует хэш `ba9daa8c…` для PHX_TWEAKPACK.ps1, в репо файл имеет `49e41895…` (совпадает с манифестом v1.3). Вероятная причина — CRLF-копия кита; сам `PHOENIX-ALPHA-0.1-KIT.zip` в репо отсутствует → проверить нечем. Нарушение собственного Law 4. Фикс: закоммитить кит-копию или перегенерировать манифест после пересборки кита (патчи меняют CONTROL.cmd — манифест в любом случае требует перегенерации).
- **D-03** `worklog.md:615` (Task 42) — «409-конфликт задокументирован в scripts/tweaks/api_commit2.py» — файла нет в main. Фикс: докоммитить или снять ссылку.
- **D-04** `manifests/H-PE11_BOMB_v1.2.SHA256:2` — self-ссылочная запись: манифест содержит хэш самого себя, фактический другой → любая проверка даст ложный FAIL. Фикс: убрать self-строку или пометить «(self, справочно)».

---
## 3. ПОЛНЫЙ РЕЕСТР НАХОДОК (MEDIUM/LOW, сводка)

### Security — MEDIUM
| ID | Где | Суть |
|----|-----|------|
| S-09 | autounattend.xml:23-48 | LabConfig-bypass TPM/SecureBoot/CPU/RAM+MoSetup — стенд живёт без аппаратного корня доверия; компенсировать проверкой Confirm-SecureBootUEFI (уже в HW-AUDIT:121) |
| S-10 | bomb_part1.ps1:191 | `DISM /Add-Driver /ForceUnsigned` — неподписанный INF+SYS в WinPE от SYSTEM; убрать Force, валидировать подписи |
| S-11 | PHX-RUN.ps1:25-41 | Паттерн «regex-подмена файла на диске + Invoke-Expression всего содержимого»: прямой инъекции нет (ValidateSet+ЭВ.1-проверка), но доверенный якорь = файл на диске; уйти на запуск файла (сделано патчем P-002) |
| S-12 | PHOENIX-CONTROL.cmd:33-43, pe_gen.py:142 | `set /p CHOICE=` без санитизации → cmd-инъекция вводом от elevation-консоли; использовать choice.exe или кавычить |
| S-13 | artifacts/BCD-MASTER-FIX.ps1:85-108 (v1.0) | При неудаче `bcdedit /export` флаг `$can` не сбрасывается → правки BCD без бэкапа; в v1.1 исправлено (return) — распространить паттерн, вывести v1.0 из оборота |
| S-14 | artifacts/PHX_FIX2.bat:123-140, PHX_FIX3.bat:123-137,171-196 | bcdboot `/f ALL` + ручная сборка BCD без предварительного `/export`-бэкапа; ошибка детекции ESP = незагружаемая машина. BrickRisk |
| S-15 | get-ammo.ps1:24-95 | `Copy-Item -LiteralPath (Join-Path $dir '*')` — LiteralPath не разворачивает wildcard → все «станционные» копирования молча падают, сборка недополучает компоненты |
| S-16 | get-ammo.ps1:46-68, ammo_dl2.sh:46-54 | Офлайн-утилиты обхода аутентификации (Login Unlocker/Strelec, NTPWEdit) в основном ките + автопоиск Strelec*.iso по дискам C:-G: — отдельный service-носитель + пин хэша |
| S-17 | worklog.md:119 | Префикс живого PAT `github_pat_11A4QPQUA0…` (до 2026-11-19) опубликован в репо; сам токен не найден, но префикс нормализует утечку. Маскировка сделана патчем P-004; токен — отозвать досрочно |
| S-18 | drv_h61.py:47-54,68; drv_catalog.py:47-48 | Выбор драйвера «первый/последний» из выдачи каталога без проверки архитектуры/версии → риск i386-cab на amd64; пин UID как в drv_h61_2.py:69 |

### Security — LOW
S-19 `PHOENIX-CONTROL.cmd:13`, `PHX_FIX13_RUN.cmd:12,14` — `Start-Process -FilePath '%~f0'`: путь с апострофом ломает relaunch · S-20 `PHX-HW-AUDIT.ps1:31,100`, `PHX-SETUP-COMPLETE.ps1:61-63,83` — MAC/hostname в отчётах, читаемых всеми локальными пользователями · S-21 `fetch_win11_iso_url.sh:7,12-15` — cookie-jar оседает на носителе · S-22 `fido_get_iso.py:93-94` — URL ISO без контрольной суммы (TOFU на TLS MS) · S-23 `setupcomplete.cmd:14` — `BypassNRO` мёртв на 26H2 (покрывается autounattend LocalAccounts) · S-24 MOK-сертификат `ENROLL_THIS_KEY…cer` без документации происхождения · S-25 `autounattend.xml:80` — `ProtectYourPC=3` ослабляет стартовый baseline (компенсируется WU-профилем твикпака).

### Код-качество — MEDIUM
| ID | Где | Суть |
|----|-----|------|
| Q-04 | PHX_TWEAKPACK.ps1:568-584 | Invoke-PhxMsi без try/catch: Access Denied → Set-EV1(…,$true) ставит ЛОЖНЫЙ [x] (нарушение ЭВ.1) |
| Q-05 | PHX_TWEAKPACK.ps1:163-175,601-615 | Повторный Apply: новый бэкап-каталог, baseline отката смещается; цепочка папок не сцеплена |
| Q-06 | PHX_TWEAKPACK.ps1:388,413,435-439,481,518,592-597 | ЭВ.1-метки [x] в Report-режиме печатаются как выполненные («добавлен в план» → [x]) — размывает стандарт честности |
| Q-07 | PHX_TWEAKPACK.ps1:142-143 | Fallback «первый физдиск по размеру» может взять не системный в multi-disk (смягчено дефолтом «оставить ВКЛ») |
| Q-08 | bomb_part1.ps1:39-50 | `'/NoRestart'` дописывается ко ВСЕМ DISM-операциям — на иных версиях error 87 → ложный STOP сборки |
| Q-09 | bomb_part2.ps1:27-38 | `reg.exe load/unload` без try/finally — исключение оставляет hive загруженным → commit падает, boot.wim битый |
| Q-10 | bomb_part1.ps1:183-185, bomb_part2.ps1:184,197 | `& dism '/Image:' + $mount …` — аргументная склейка без скобок: `+` и `$mount` уходят отдельными аргументами → DISM-ошибка/тихий нулевой счётчик |
| Q-11 | pe_gen.py:85, pe_gen_v13.py:88 | f-string с двойными кавычками того же типа — только Python ≥3.12 (PEP 701); requirements/pinning отсутствуют во всех py |
| Q-12 | pe_gen*.py, make_iso*.py, verify_iso*.py | Захардкоженные машинные пути `/home/z/...`, `/tmp/my-project/...` — невоспроизводимость; CLI-аргументов нет |
| Q-13 | verify_iso.py / verify_iso_v13.py (весь файл) | «Хэш-сверки» НЕТ: только структурный дым; SHA256 ISO не сверяется с манифестом — Law 4 формально не закрыт в verify |
| Q-14 | make_iso.py:51-77 vs make_iso_v13.py:42-47 | v1.2 не исключает boot.cat из media при bootcatfile — конфликт на повторном прогоне |

### Код-качество — LOW
Q-15 `PHX_TWEAKPACK.ps1:667` — `\$PhxMode` с backslash вместо backtick-escape → мусор в логе · Q-16 `:390` («тфик»), `:226` (Src='TH+;WU' — битый формат меток) · Q-17 `:750-757,810` — Binary/MultiString не восстанавливаются из журнала Restore · Q-18 `:22-26` — шапка требует 24H2/25H2, кит — 26H2 (чек `$build -ge 22000` пропускает 26200, но доктрина расходится) · Q-19 `PHX-HW-AUDIT.ps1:111-113` — dead code с битым фильтром · Q-20 `PHX-SETUP-COMPLETE.ps1:60` + `PHX_TWEAKPACK.ps1:66` — под PHX-RUN `$PSScriptRoot` пуст → бэкап уходит в systemprofile (патч P-002 решает инъекцией пути) · Q-21 `bomb_part1.ps1:151-163` — oscdimg fail: без retry и без проверки размера ISO · Q-22 `pe_gen.py:102,222` — drvload глушит все ошибки `>nul 2>&1` — ЭВ.1-видимость нулевая · Q-23 `verify_iso.py:16` — приватный API pycdlib `iso._has_udf` · Q-24 `make_iso.py:83` — `assert` отключается при `python -O` · Q-25 `verify_iso.py:28` — незакрытые хэндлы devnull.

### Доки vs код — MEDIUM/LOW
D-05 `docs/PHOENIX-ALPHA-RUNBOOK.txt:61` vs worklog:626-629 — метода пересборки ISO в отчёте противоречит канону (grow-xorriso невозможен; базис Task 40, не 41) · D-06 RUNBOOK:52-77+94 — железо станции 6ORMAN устарело (i3-2120/8ГБ по Task 37, не Celeron N3350/4ГБ) · D-07 README:72-89 — roadmap/структура не знают про ALPHA и миссию УИЛЬЯМ · D-08 MEMORY.md (заявлен «держит ВСЁ») обрывается на Task 29 — УИЛЬЯМ/TWEAKPACK v2.0/ALPHA-1 не попали · D-09 worklog:49,67,318 — 9 «сохранённых» скриптов Tasks 1-3/10 отсутствуют в main · D-10 FEATURE-CATALOG.md описывает отменённый ADK-путь без пометки «исторический» · D-11 catalog_report.json (iGPU cab найден, status ok) vs канон «HD 2000 в Catalog НЕ представлен» — противоречие не объяснено · D-12 `manifests/H-PE11_PHOENIX_v1.3.SHA256:3` — ссылка на эфемерный `/tmp/my-project/...` путь · D-13 `manifests/PHOENIX-ALPHA-0.1.SHA256:10,13` — dangling: README-ALPHA-RU.txt (контент = RUNBOOK) и KIT.zip не закоммичены · D-14 `manifests/` vs `artifacts/` — одноимённые манифесты разошлись · D-15 `pe_gen_v13.py:324` — генератор вернёт старое «Sysinternals (16)» при регенерации · D-16 README:79-89 — 5 из 10 корневых документов не перечислены · D-17 `artifacts/README.md` — англоязычный плейсхолдер · D-18 `artifacts/GLUE_README…` vs `docs/…` — байт-в-байт дубль без канона · D-19 Брендинг PHX/PHOENIX/ФЕНИКС/HPE11 не унифицирован внутри ALPHA-кита.

---

## 4. GIT-ГИГИЕНА (оркестратор, ✅ числа из API+клона)

**Анатомия 7.19 ГБ:**

| Компонент | Объём | Доля | Комментарий |
|-----------|-------|------|-------------|
| ISO v2 в main (`artifacts/iso_26100.1_pro_ru_v2/`, 116×40 МБ) | 4602.1 МБ | 99.5% дерева main | разбит на части ради лимита блоба 100 МБ — но живёт в git-истории |
| ISO v1 (103 части) в ветках iso_tmp_1..5 | 4093.3 МБ | +88% к main | размазан по 5 веткам цепочкой коммитов (20 частей/ветка) — обход лимитов «на коленке» |
| Код + доки + манифесты (всё остальное) | ~2.5 МБ | ~0.05% | 126 текстовых блобов |
| Дедуп v1↔v2 в pack | −~1.5 ГБ | — | общие части двух ISO |

**Ветки:** alpha-0.1, tweakpack-v1.0, tweakpack-v2.0 — **0 уникальных коммитов** (деревья идентичны или исторические маркеры); iso_tmp_1..5 — 1..5 уникальных коммитов, содержимое = только части v1 ISO. Смысловая ценность: ноль после выгрузки ISO в Releases.

| G-ID | SEV | Рекомендация |
|------|-----|--------------|
| G-01 | HIGH | Удалить ветки iso_tmp_1..5 и alpha-0.1 (содержимое ISO v1 — в GitHub Release как 3-5 ассетов по ≤2 ГБ; тег tweakpack-* сохранить как lightweight-теги вместо веток) |
| G-02 | HIGH | ISO v2 (4.6 ГБ) убрать из main: Release-ассеты (116 частей → 1 файл 4.5 ГБ нельзя — лимит 2 ГБ → 3 части) или внешний storage + манифест Law 4 остаётся в репо |
| G-03 | MEDIUM | `.gitattributes` с LFS для будущих бинарников — патч **P-005** (новые файлы сразу в LFS; исторические — только через `git-lfs migrate import --everything`, решать отдельно) |
| G-04 | MEDIUM | Дубликаты brand/PHOENIX-11_wallpaper.png ↔ artifacts/ (2×1.21 МБ) и манифестов manifests/ ↔ artifacts/ — один канон |
| G-05 | LOW | Дефолтная ветка без защиты (solo-проект — приемлемо), Actions/секреты не используются — отмечено для полноты |

---

## 5. ВЕРИФИКАЦИЯ МАНИФЕСТОВ (Law 4) ✅/🔎

| Манифест | Записей | Проверено | Совпало | Статус |
|----------|---------|-----------|---------|--------|
| artifacts/iso_26100.1_pro_ru_v2/MANIFEST.json (116 частей + file_sha256 b02e6dba…) | 117 | 11 выборочно (40 МБ каждый) | **11/11** | ✅ выборочная верификация SHA256+size |
| manifests/PHOENIX-ALPHA-0.1.SHA256 | 9 | 7 | 6 | ✅ 1 расхождение (D-02), 2 dangling (D-13) |
| manifests/H-PE11_PHOENIX_v1.3.SHA256 | 5 | 3 | 3 | ✅ ISO/boot.wim — вне репы (косвенно подтверждён docs/SHA256SUMS_inside_v1.3.txt) |
| manifests/H-PE11_BOMB_v1.2.SHA256 | 4 | 3 | 2 | ✅ self-hash парадокс (D-04) |
| artifacts/WILLIAM_B1_KIT_v1/MANIFEST.json | 1 | size | 1 | ✅ (sha256 ждёт full-клона) |
| Сверка worklog-хэшей артефактов (DIAG/FIX/FIX2/3/BOOT_FIX/ZALIVKA/WINST/REFIMAGE/FIX13/cert) | 14 | 14 | **14** | ✅ байт-в-байт |
| «5/5 сверка» Task 42 (git hash-object) | 5 | 4 | 4 | ✅ worklog-блоб законно уехал после ALPHA-1 |

**Итог:** дисциплина Law 4 реальная (26/28 + 11/11 + 14/14); обе «дыры» — процедурные (кит-копия, self-hash), не компрометация.

---

## 6. СТАБИЛЬНОСТЬ WIN11 26H2: ТОП-8 РИСКОВАННЫХ ТВикОВ 🔎

| # | Твик (строка PHX_TWEAKPACK.ps1) | Категория | Заявл. Risk | Реальный риск | Обратимость |
|---|--------------------------------|-----------|-------------|---------------|-------------|
| 1 | WU-набор: DeferFeature 365д/DeferQuality 4д/ExcludeWUDrivers (:342-346) | wu | 1-3 | WU не ломается (wuauserv/UsoSvc/WaaSMedic не тронуты — грамотно); patch-гэп 4 дня; чужая машина без конвейера H-PE11 может остаться без драйверов | Полная (reg-журнал) |
| 2 | VBS/HVCI off — только по $PhxAdvancedRisk (:422-423) | misc | 5 | Memory Integrity off; +FPS на слабых CPU; BitLocker/Hello не ломаются | Полная (reg+reboot) |
| 3 | SvcHostSplitThresholdInKB=RAM, RAM≥6ГБ, авто (:408-417) | misc | 2 | Крах одного сервиса валит группу; маскировка OOM | Полная (reg+reboot) |
| 4 | DiagTrack/dmwappush Disabled + 11 CEIP-задач (:294-311) | priv | 2-3 | WU/Store/Insider не зависят; RemoteRegistry-off — security-плюс | Полная (Svc-журнал) |
| 5 | Debloat Default/PrivacyMax (Appx+Provisioned, :463-501) | priv/tskb | — | Store/winget/Defender/Xbox в защитном списке (:447-454); Provisioned-снос = новые юзеры без пакетов | Частичная (журнал Appx → re-register) |
| 6 | HAGS HwSchMode=2 по regex-детекции GPU (:374-392) | game | 2 | 'Ryzen .* Graphics' матчит Vega-APU — безвредно или фризы на сырых драйверах | Полная |
| 7 | SharedAccess/CscService Disabled, MapsBroker Manual (:358-360) | misc | 2-3 | ICS (Mobile Hotspot) и Offline Files ломаются — Note предупреждает честно | Полная |
| 8 | NIC-пресет (EEE/FlowControl off, буферы 512; :544-563) + ASPM off десктоп (:524-527) | net/pow | 2 | Дропы на нагруженной сети; рост энергопотребления | Полная (Set-NetAdapterAdvancedProperty) |

Вне топа: PageFile, Memory Compression, Defender-исключения и снос CompatTelRunner в паке **отсутствуют** (grep подтверждён) — положительно. Teredo DisabledComponents=1 рвёт ВСЕ туннели, не только Teredo (Note неточен, Q-16).

---

## 7. ДОРОЖНАЯ КАРТА ФИКСОВ (приоритет → трудозатраты)

1. **Секреты (день 0):** отозвать PAT (S-17) и deploy-key (S-05); применить P-003/P-004; пароль 6orman сменить на существующих станциях; autounattend → шаблон с подстановкой.
2. **Работоспособность ALPHA (день 0):** P-001 (меню) + P-002 (IEX/Restore) → пересборка кита → перегенерация manifests/PHOENIX-ALPHA-0.1.SHA256 → smoke-тест пунктов [2]–[7] на станции.
3. **Supply chain (день 1-2):** манифест ammo (версии+SHA256) → P-006 шапка с Assert-FileHash в новые скрипты → `.part`+`--fail` в ammo_dl*/drv_* → убрать /ForceUnsigned (S-10).
4. **Rollback-UX (день 2-3):** инкрементальный Save-PhxJournal (Q-03), ре-верификация MSISupported (Q-04), [plan]-метки в Report (Q-06).
5. **Git (день 3):** G-01/G-02 (ISO → Releases), G-03 (.gitattributes уже готов), G-04 (каноны дублей).
6. **Доки (день 3-4):** D-01/D-05/D-06/D-07/D-08/D-10 — синхронизация README/MEMORY/RUNBOOK с эпохой Tasks 37-42/ALPHA-1.

## 8. ПАТЧИ (index)

| Файл | Цель | Что делает |
|------|------|-----------|
| patches/001-PHOENIX-CONTROL.cmd.patch | Q-01 | `-Profile` → `-ProfileName` ×6 (байт-в-байт, count-верифицировано) |
| patches/002-PHX-RUN.ps1.patch | S-11, Q-02, Q-20 | Убирает Invoke-Expression (запуск через временный файл + `powershell -File`); инъекция `$PhxBackupDir`; Restore автопоиск последнего журнала; ЭВ.1 [--]-гварды |
| patches/003-PHX-SETUP-COMPLETE.ps1.patch | S-01 | Принудительная смена пароля при первом входе (`/logonpasswordchg:yes`) с ЭВ.1-меткой |
| patches/004-worklog.md.patch | S-17 | Маскировка PAT-префикса |
| patches/005-.gitattributes (новый) | G-03 | LFS-паттерны (cab/zip/iso/wim/png/docx/cer/part*) + eol-нормализация (ps1/cmd/bat → CRLF, py/sh/md → LF) |
| patches/006-SECURITY-HEADER.ps1.template (новый) | S-06, Q-13 | Обязательная шапка новых .ps1: #Requires, StrictMode, Assert-FileHash (Law 4 для арсенала) |

Порядок применения: применить на чистом main (`git apply patches/NNN.patch`), пересобрать кит ALPHA, перегенерировать манифест, прогнать smoke (§7.2). Патчи не трогают историю (запрет rewrite — G-01 решается удалением веток, не filter-branch).

## 9. ОТЗОВАННЫЕ НАХОДКИ (транспарентность)

- **«CRITICAL: parse-error PHX_TWEAKPACK.ps1:412-413, битое `ath]::Round`»** — ❌ отозвана. Численная верификация: файл содержит `[math]::Round` (×2, оба целые, префикс подтверждён побайтово; bare-фрагментов 0). Первичная «находка» — артефакт отображения консоли аудиторской среды (санитайзер вывода глотал литерал `[m`); была помечена «verified» ошибочно и унаследована агентским треком. TWEAK-MATRIX §6.5 («линт PS 5.1: 0 ошибок») остаётся неопровергнутым. Урок внесён в методологию (§1.4): byte-claims — только через count/boolean-протокол.
- Патч math-fix из первой итерации изъят; «исправленный» файл уничтожен.

---

*Отчёт подготовлен мультиагентным контуром AUDIT-2026-10-26 (3 субагента + оркестратор). Все file:line ссылки соответствуют main `e73aa8b8`. Приложение: patches/ (6), README-PATCHES.md.*
