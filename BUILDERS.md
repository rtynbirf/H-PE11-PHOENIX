# BUILDERS — каталог сборщиков (WinPE-сборки и десктопные сборки Windows)

> Родственный документ: **HEROES.md** — там герои-инструменты (wimlib, pycdlib, Volume², Ventoy...).
> Здесь — АВТОРЫ СБОРОК (люди/ники, которые лепят целые сборки Windows и WinPE).

Запрос Хозяина (после Task 30): «НЕТ СПИСОК СБОРЩИКОВ СБОРОК ГДЕ? СМОУКБЛАХБЛАХ ОТГОВСКИ КОТОСФТ И ТД И ТП».
Опознание по памяти Хозяина: СМОУКБЛАХБЛАХ = **SmokieBlahBlah**, ОТГОВСКИ = **OVGorskiy®**, КОТОСФТ = **KottoSOFT**.
Все три подтверждены веб-разведкой (2026-10-25).

## I. WinPE / спасательные сборки (наш жанр)

| # | Автор | Продукт | Статус | Примечание |
|---|-------|---------|--------|------------|
| 1 | **Sergei Strelec (Стрелец)** | WinPE 11-10-8 x86/x64/Native | [+] жив, обновляется | Последний релиз 2026.10.21; MInstAll, драйверпаки; **базис ФЕНИКС-11**; sergegstrelec.name / .ru |
| 2 | **Xemom1** | **2k10 Live** | [+] классика | WAIK-PE, сотни HDD/DOS-утилит; его wim-загрузчики используют другие сборщики (в т.ч. KottoSOFT) |
| 3 | **OVGorskiy®** | WinPE 11-10-8-7 x86/x64 «2 выпуска» | [+] жив | forum.ovgorskiy.ru, активная гостевая (посты «6 days ago»); плюс десктоп-сборки (см. II) |
| 4 | **ChrisR** | **Win10XPE** | [+] жив | Не готовая сборка, а КОНСТРУКТОР WinPE (наследник WinBuilder); GitHub ChrisRfr/Win10XPE; поддержка Kyhi; на нём лепят свои PE энтузиасты |
| 5 | **PhoenixPE team** | **PhoenixPE** | [+] жив | Конструктор PE на движке PEBakery (новое поколение, быстрые билды); GitHub PhoenixPE/PhoenixPE; имя резонирует с нашим ФЕНИКСОМ |
| 6 | **Gandalf** | Gandalf Win10PE x64 | [+] жив | windowsmatters.com; база Win11 24H2 (26100.1742); англоязычный; нужно ≥2 ГБ RAM |
| 7 | **Bob.Omb** | Bob.Omb's Rounded WinPE | [+] жив | Англ., очень широкий набор для техников; ≥2 ГБ RAM |
| 8 | **Hiren's BootCD PE** | Hiren's BootCD PE x64 | [+] жив | Возрождённая классика на Win10-PE; легковесный |
| 9 | **Jayro** | **Medicat USB** | [+] жив | Мегамультибор-тулкит на базе WinPE; тяжёлый (20+ ГБ) |
| 10 | **yurkesha** | (Y)PE HDD tools edition | [−] архив | Старая гвардия winpe.ru, WIM-сборка |
| 11 | **TechAdmin** | WinPE4 TechAdmin | [−] архив | winpe.ru, UEFI-эпоха 2013-х |
| 12 | **Lopatkin** | Компакт-сборки Win + PE | [−] полумёртв | Лёгкие сборки для слабого железа; сайт/активность угасли |

## II. Сборщики десктопных Windows (то, что вспомнил Хозяин)

| # | Автор | Продукты | Статус | Примечание |
|---|-------|----------|--------|------------|
| 13 | **SmokieBlahBlah** | Win7 SP1 x64 **24in1** ±Office; Win10 **32in1** (x86/x64) + LTSC ±Office 2019; ru-en 16in1 | [−] затих ~2021-2022, раздачи живы | Рутрекер-легенда; аккуратные мульти-редакции с Office и без; archive.org хранит релизы |
| 14 | **OVGorskiy®** | Win7 Ultimate 7DB; Win10 IoT/LTSB/LTSC; **Win11 Ru 25H2 4in1 (07.2026)** | [+] жив, обновляется | ovgorskiy.ru + forum.ovgorskiy.ru; «2 выпуска» в месяц; гости хвалят надёжность 10 IoT |
| 15 | **KottoSOFT** | Win7 SP1 **9in1** v.28 (2018); Enterprise v.54/2017; v.104 | [−] затих ~2018-2021, сайт-архив жив | kottosofttrack.ucoz.net; твики ПКМ/ОЕМ/темы, патч; загрузочные wim брал у Xemom1 |
| 16 | **Putnik** | Win10/11 сборки на ru-board | [+/−] | Чистые лайт-сборки без агрессивной резки |
| 17 | **prokazzza** | Сборки XP-эпохи | [−] архив | Легенда нулевых |
| 18 | **ZverCD / Zver** | ZverCD XP | [−] архив | Самая известная XP-сборка в СНГ |
| 19 | **SamLab.ws** | Сборки + драйверпаки SamDrivers | [+/−] | Драйверпаки живы, сборки ОС реже |

## III. Конструкторы (если захотим свой PE, а не Стрельца)
- **Win10XPE (ChrisR)** — самый популярный GUI-конструктор WinPE (Win10/11-база).
- **PhoenixPE** — современный движок PEBakery, «собери свой спасательный Win11».
- **2k10/Xemom1-наборы** — классический конструкторский подход старой школы.

## Для проекта ФЕНИКС-11
- Эталон PE-задач = **Strelec** (уже интегрирован, драйверы SSTR на борту).
- Запасной вариант при проблемах со Стрельцом: **2k10 (Xemom1)** или свой PE через **Win10XPE/PhoenixPE**.
- Десктоп-сборки к проекту НЕ относятся — каталог дан для памяти/справки.

Проверка ссылок и статусов: веб-разведка 2026-10-25 (sergegstrelec.name, forum.ovgorskiy.ru, kottosofttrack.ucoz.net, github.com/ChrisRfr/Win10XPE, github.com/PhoenixPE/PhoenixPE, windowsmatters.com, easy2boot.xyz, winpe.ru).

## IV. Сайт kottosoft.ucoz.com — полный разбор (2026-10-25, по приказу Хозяина)

**Возраст сайта**: НЕ ПОЗДНЕЕ НОЯБРЯ 2014 (первый снапшот Wayback 27.11.2014) → на 25.10.2026 сайту **~12 лет** (минимум 11 лет 11 месяцев).
Лента сборок: **3024 записи** с февраля 2015 по 25.10.2021 (последняя — «Windows 11 Enterprise by Brux»); после октября 2021 сайт жив-висит, но не пополняется.
Метод: проглядены все 302 страницы ленты + 1198 страниц записей без автора в заголовке (автор из текста описания; пометка «~» = атрибуция по описанию, не по заголовку).
Партнёры в сайдбаре: kubines.ucoz.net (Кубинец), spa.ucoz.club, spa-phoenix.ucoz.org (SPA-Phoenix), diza-74.ucoz.ru (DiZona), torrnada.ru, oszone.net.

**Полный список сборщиков, встречающихся на сайте (197 имён, по числу сборок):**

| # | Сборщик | Сборок | Пометка |
|---|---------|--------|---------|
| 1 | KottoSOFT | 591 |  |
| 2 | UralSOFT | 233 |  |
| 3 | Generation2 | 170 |  |
| 4 | AG | 105 |  |
| 5 | Zosma | 92 |  |
| 6 | Adguard | 90 |  |
| 7 | IZUAL | 70 |  |
| 8 | OVGorskiy | 63 |  |
| 9 | g0dl1ke | 55 |  |
| 10 | Lopatkin | 55 |  |
| 11 | Flibustier | 48 |  |
| 12 | Zab | 47 |  |
| 13 | G.M.A. | 45 |  |
| 14 | CUTA | 40 |  |
| 15 | YahooXXX | 40 |  |
| 16 | SanLex | 38 |  |
| 17 | Brux | 37 |  |
| 18 | Integral | 36 |  |
| 19 | Kuloymin | 36 |  |
| 20 | SmokieBlahBlah | 36 |  |
| 21 | StartSoft | 34 |  |
| 22 | Elgujakviso | 27 |  |
| 23 | BananaBrain | 25 |  |
| 24 | Bellisha | 25 |  |
| 25 | Andreyonohov | 24 |  |
| 26 | OneSmiLe | 24 |  |
| 27 | GX | 23 |  |
| 28 | Naifle | 23 |  |
| 29 | Eagle123 | 22 |  |
| 30 | Vladios | 22 |  |
| 31 | Vlazok | 22 |  |
| 32 | KDFX | 21 |  |
| 33 | LeX_6000 | 21 |  |
| 34 | Matros | 21 |  |
| 35 | Semit | 18 |  |
| 36 | TeamOS | 18 |  |
| 37 | m0nkrus | 17 |  |
| 38 | Putnik | 17 |  |
| 39 | Aspro | 16 |  |
| 40 | LIM | 16 |  |
| 41 | MoverSoft | 16 |  |
| 42 | Ratiborus | 16 |  |
| 43 | c400 | 13 |  |
| 44 | Ivandubskoj | 13 |  |
| 45 | Novik | 12 |  |
| 46 | aXeSwY & TomeCar | 11 |  |
| 47 | MandarinStar | 11 |  |
| 48 | Proteus | 11 |  |
| 49 | Sergei Strelec | 11 |  |
| 50 | spb_user | 11 |  |
| 51 | DREY | 10 |  |
| 52 | molchel | 10 |  |
| 53 | Nicky | 10 |  |
| 54 | SLO94 | 10 |  |
| 55 | murphy78 | 9 |  |
| 56 | Donbass | 8 |  |
| 57 | Neomagic | 8 |  |
| 58 | Sharicov | 8 |  |
| 59 | Storm Breaker & TECH Aura | 8 |  |
| 60 | Tatata | 8 |  |
| 61 | Yahoo002 | 8 |  |
| 62 | ArtZak | 7 |  |
| 63 | Den | 7 |  |
| 64 | Dragon | 7 |  |
| 65 | KulHunter | 7 |  |
| 66 | Morhior | 7 |  |
| 67 | Rockmetall | 7 |  |
| 68 | Sebaxakerhtc | 7 |  |
| 69 | Batman | 6 |  |
| 70 | Belish | 6 |  |
| 71 | Bella | 6 |  |
| 72 | Bryansk | 6 |  |
| 73 | Mirkec | 6 |  |
| 74 | Sunehildeep | 6 |  |
| 75 | Vladios & Liveonloan | 6 |  |
| 76 | Vladislays | 6 |  |
| 77 | YelloSOFT | 6 |  |
| 78 | Alex.zed | 5 |  |
| 79 | IDimm | 5 |  |
| 80 | LaMonstre | 5 |  |
| 81 | Leha342 | 5 |  |
| 82 | ROG | 5 |  |
| 83 | Satenex | 5 |  |
| 84 | WinRoNe | 5 |  |
| 85 | Xalex | 5 |  |
| 86 | YahooIII | 5 |  |
| 87 | Anti-Spy | 4 |  |
| 88 | D1mka | 4 |  |
| 89 | Egeri | 4 |  |
| 90 | eXtreme | 4 |  |
| 91 | Game | 4 |  |
| 92 | NIKZZZZ CD | 4 |  |
| 93 | OmegaSOFT | 4 |  |
| 94 | Paxweaver | 4 |  |
| 95 | Stattica | 4 |  |
| 96 | White Death | 4 |  |
| 97 | WolfEywa | 4 |  |
| 98 | 1Pawel | 3 |  |
| 99 | A.L.E.X. | 3 |  |
| 100 | Dr.Verstak | 3 |  |
| 101 | Fedya | 3 |  |
| 102 | Jerry_Xristos | 3 |  |
| 103 | KievIGreen | 3 |  |
| 104 | KosaySOFT | 3 |  |
| 105 | Kristian | 3 |  |
| 106 | KrotySOFT | 3 |  |
| 107 | Maherz | 3 |  |
| 108 | Nicky & Rain | 3 |  |
| 109 | Oleg-zelen | 3 |  |
| 110 | RZN-Soft | 3 |  |
| 111 | Sibiryak | 3 |  |
| 112 | Sura Soft | 3 |  |
| 113 | Team-LiL | 3 |  |
| 114 | BIZ | 2 |  |
| 115 | Brux & White Smoke | 2 |  |
| 116 | Darkalexx4 | 2 |  |
| 117 | Djakonda | 2 |  |
| 118 | Encoder | 2 |  |
| 119 | evgen_b | 2 |  |
| 120 | Golver | 2 |  |
| 121 | KaZiMiR | 2 |  |
| 122 | Kiryandr | 2 |  |
| 123 | LWGam | 2 |  |
| 124 | OrbitDV | 2 |  |
| 125 | Qmax | 2 |  |
| 126 | Rousk | 2 |  |
| 127 | RUwinSOFT | 2 |  |
| 128 | Sam | 2 |  |
| 129 | SapSan | 2 |  |
| 130 | Shaman | 2 |  |
| 131 | Subzero | 2 |  |
| 132 | Vannza | 2 |  |
| 133 | VLSC | 2 |  |
| 134 | W.Z.T. | 2 |  |
| 135 | Xomaze | 2 |  |
| 136 | AEK | 1 |  |
| 137 | AlexSmile | 1 |  |
| 138 | Avatar1962 | 1 |  |
| 139 | BADDGET | 1 |  |
| 140 | Belgian | 1 |  |
| 141 | Blackbox | 1 |  |
| 142 | Camodelkin | 1 |  |
| 143 | CMTeamPK | 1 |  |
| 144 | Dart10 | 1 |  |
| 145 | DaVincci | 1 |  |
| 146 | Degortg | 1 |  |
| 147 | DiLshad Sys | 1 |  |
| 148 | DrozD | 1 |  |
| 149 | Ducazen | 1 |  |
| 150 | Dyatlov | 1 |  |
| 151 | EmiN | 1 |  |
| 152 | Grimm_13 | 1 |  |
| 153 | IceSlam | 1 |  |
| 154 | IgnatievI | 1 |  |
| 155 | kachnu | 1 |  |
| 156 | Karasidi | 1 |  |
| 157 | KATAR0 | 1 |  |
| 158 | Kazanov | 1 |  |
| 159 | Khatmau_sr | 1 |  |
| 160 | KHMILNYK | 1 |  |
| 161 | Kosala | 1 |  |
| 162 | Ks-Soft | 1 |  |
| 163 | Lamer | 1 |  |
| 164 | LamroSOFT | 1 |  |
| 165 | Lazarus | 1 |  |
| 166 | Lucky | 1 |  |
| 167 | Magnum | 1 |  |
| 168 | Mallymkun | 1 |  |
| 169 | Minutka15 | 1 |  |
| 170 | MoDValue | 1 |  |
| 171 | Muhammad Sadeem | 1 |  |
| 172 | MyDream | 1 |  |
| 173 | Natali & KHMILNYK | 1 |  |
| 174 | Nethum | 1 |  |
| 175 | niknikto | 1 |  |
| 176 | OniS | 1 |  |
| 177 | PIP | 1 |  |
| 178 | ProDarks | 1 |  |
| 179 | Rafaela | 1 |  |
| 180 | Ratmir | 1 |  |
| 181 | RazchlenenkA | 1 |  |
| 182 | RemasterOS | 1 |  |
| 183 | REZAK | 1 |  |
| 184 | SemionovSOFT | 1 |  |
| 185 | SPAXPBLACK | 1 |  |
| 186 | StaforceTEAM | 1 |  |
| 187 | Syed Talha Zameer | 1 |  |
| 188 | SYSadminSFT | 1 |  |
| 189 | Trek | 1 |  |
| 190 | TSM | 1 |  |
| 191 | TSPR | 1 |  |
| 192 | UnOfficial | 1 |  |
| 193 | Usonarl | 1 |  |
| 194 | VirUSA | 1 |  |
| 195 | WinRoNe & Leha342 | 1 |  |
| 196 | Xotta6bi4 | 1 |  |
| 197 | Xserver17 | 1 |  |
