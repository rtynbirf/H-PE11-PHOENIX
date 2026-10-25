# README-PATCHES — как применять патчи AUDIT-2026-10-26

База: `main @ e73aa8b8` (PHOENIX ALPHA 0.1). Все патчи в формате `diff -u`, применяются:

```bash
git checkout main && git pull
git apply --check patches/001-PHOENIX-CONTROL.cmd.patch   # сухой прогон
git apply          patches/001-PHOENIX-CONTROL.cmd.patch
git apply          patches/002-PHX-RUN.ps1.patch
git apply          patches/003-PHX-SETUP-COMPLETE.ps1.patch
git apply          patches/004-worklog.md.patch
cp patches/005-.gitattributes .gitattributes
cp patches/006-SECURITY-HEADER.ps1.template scripts/    # как шаблон для новых .ps1
```

| # | Патч | Чинит | Риск патча |
|---|------|-------|-----------|
| 001 | PHOENIX-CONTROL.cmd | Q-01: меню [2]–[7] падало (`-Profile` vs `-ProfileName`) | Нулевой: 6 точечных замен, count-верифицировано |
| 002 | PHX-RUN.ps1 | S-11: Invoke-Expression устранён; Q-02: Restore находит журнал; Q-20: бэкап-каталог детерминирован | Средний: изменена механика запуска — нужен smoke (ниже) |
| 003 | PHX-SETUP-COMPLETE.ps1 | S-01: принудительная смена пароля при первом входе | Низкий: блок с ЭВ.1-меткой, отказоустойчив |
| 004 | worklog.md | S-17: PAT-префикс замаскирован | Нулевой |
| 005 | .gitattributes (новый) | G-03: LFS для будущих бинарников | Низкий: действует на новые файлы; историю не переписывает |
| 006 | SECURITY-HEADER.ps1.template | S-06/Q-13: стандарт шапок + Assert-FileHash | Нулевой: шаблон |

## Smoke-чеклист после применения (pwsh 5.1, тестовая станция)

1. `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\deploy\PHX-RUN.ps1 -ProfileName Balanced -Mode Report` → лог на общем рабочем столе, метки [x]/[--], статус-строка «бэкап=…».
2. `PHOENIX-CONTROL.cmd` → пункт [2] (Report) и [4] (Apply Balanced на тест-учётке) → журнал применён, `PHX_TWEAKBACKUP_*` создан на Public Desktop.
3. Повторный запуск пункта [7] (Restore) → журнал найден автоматически, откат применён, сверка значений.
4. Секция 0 в STATUS.txt: метка `[x] пароль 6orman: смена при первом входе`.
5. Пересборка кита ALPHA → перегенерация `manifests/PHOENIX-ALPHA-0.1.SHA256` (Law 4) → коммит.

## После патчей — организационные шаги (не патчи)

- Отозвать текущий PAT (упомянут в worklog.md:119, срок до 2026-11-19) и `/tmp/phx_deploy_key`.
- ISO v2 → GitHub Release (3 ассета ≤2 ГБ) + удалить ветки iso_tmp_1..5 (G-01/G-02).
- Манифест ammo: версии+SHA256 всего арсенала (S-06), далее Assert-FileHash в ammo_dl*.
