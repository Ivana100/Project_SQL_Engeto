# Projekt SQL - Dostupnost základních potravin široké veřejnosti 

## Úvod

Cílem projektu je analyzovat vývoj mezd a cen vybraných potravin v České republice a posoudit, jak se v období 2006 - 2018 měnila jejich dostupnost.

Projekt vychází z dat o mzdách, cenách potravin a ekonomických ukazatelích. Hlavním cílem je připravit datové podklady pro zodpovězení pěti definovaných výzkumných otázek.

Součástí projektu je také vytvoření sekundární datové tabulky obsahující vybrané ekonomické ukazatele dalších evropských států.

---

# Datové zdroje

## Zdrojové tabulky

Pro analýzu mezd a cen potravin byly použity následující tabulky:

- `czechia_payroll` - informace o mzdách v různých odvětvích za několikaleté období
- `czechia_payroll_calculation` – číselník kalkulací v tabulce mezd
- `czechia_payroll_industry_branch` – číselník odvětví v tabulce mezd
- `czechia_payroll_unit` – číselník jednotek hodnot v tabulce mezd
- `czechia_payroll_value_type` – číselník typů hodnot v tabulce mezd
- `czechia_price` – informace o cenách vybraných potravin
- `czechia_price_category` – číselník kategorií potravin
- `czechia_region` – číselník krajů České republiky
- `czechia_district` – číselník okresů České republiky

Datové sady mezd a cen pocházejí z Portálu otevřených dat České republiky.

## Dodatečné tabulky

Pro doplnění ekonomického kontextu byly použity:

- `countries` – informace o jednotlivých státech
- `economies` – ekonomické ukazatele pro daný stát a rok

---

# Výstupní tabulky

V rámci projektu byly vytvořeny dvě finální datové tabulky požadované zadáním:

### `t_ivana_amranova_project_sql_primary_final`

Obsahuje sjednocená data o mzdách a cenách potravin v České republice za společné srovnatelné období.

### `t_ivana_amranova_project_sql_secondary_final`

Obsahuje dodatečné ekonomické ukazatele pro evropské státy.

---

# Tvorba primární finální tabulky 
`t_ivana_amranova_project_sql_primary_final`

## Zpracování mezd

Zdrojová tabulka `czechia_payroll` obsahuje údaje o mzdách na čtvrtletní úrovni.

Pro analýzu byla vybrána hodnota odpovídající **průměrné hrubé mzdě na zaměstnance** (`value_type_code = 5958`) a způsob výpočtu odpovídající **přepočtenému ukazateli** (`calculation_code = 200`).

Z původních čtvrtletních údajů byl následně vypočítán průměr mzdy za jednotlivé roky a jednotlivá odvětví.

Výsledkem je roční průměrná mzda pro každé odvětví.
V tabulce byli ponechány i data za celé hospodářství (`industry_branch_code is null`).


## Zpracování cen potravin

Zdrojová tabulka `czechia_price` obsahuje ceny potravin zaznamenané v časových intervalech 7 dní prostřednictvím hodnot `date_from` a `date_to`.

Pro účely analýzy byl rok získán z hodnoty `date_from`.

Následně byly ceny agregovány na roční úroveň a pro jednotlivé kategorie potravin byl vypočítán průměr ceny za daný rok.

Do analýzy byly zahrnuty celorepublikové hodnoty, tedy záznamy bez specifikovaného regionu (`region_code IS NULL`).



## Sjednocení období

Data o mzdách jsou dostupná za období:

**Q1 2000 – Q2 2021**

Data o cenách potravin jsou dostupná za období:

**2006 – 2018**

Proto bylo pro společné porovnání zvoleno období:

**2006 – 2018**

Toto období bylo použito při tvorbě primární finální tabulky a následných analýzách.

## Spojení mezd a cen

Po převedení obou datových zdrojů na společnou roční úroveň byly údaje o mzdách a cenách spojeny podle roku.

Primární datová tabulka má v důsledku tohoto spojení granularitu odpovídající kombinaci:

**rok × odvětví × kategorie potravin**

To znamená, že například roční hodnota mzdy pro určité odvětví se v tabulce může opakovat pro více kategorií potravin stejného roku.

Toto opakování není změnou původní hodnoty mzdy, ale důsledkem spojení dvou datových zdrojů s různými dimenzemi.

Při následných výpočtech proto bylo nutné tuto vlastnost zohlednit a před výpočtem některých ukazatelů provést odpovídající agregaci.

Například při analýze vývoje mezd byla data nejprve agregována na úroveň roku a odvětví pomocí `MAX()` nad hodnotou roční průměrné mzdy.

# Tvorba sekundární finální tabulky 
`t_ivana_amranova_project_sql_secondary_final`

Tabulka vznikla spojením tabulek `countries` a `economies` podle jednotlivých evropských krajin.

---

# Informace o výstupních datech

Primární finální tabulka `t_ivana_amranova_project_sql_secondary_final` obsahuje údaje pouze za společné období **2006–2018**, protože pouze v tomto období jsou současně dostupná data o mzdách i cenách potravin.

Původní data o mzdách a cenách měla rozdílnou granularitu. Mzdy byly dostupné na čtvrtletní úrovni, zatímco ceny potravin byly zaznamenávány v jednotlivých časových intervalech. Pro potřeby společné analýzy byly oba zdroje převedeny na roční úroveň.

Primární tabulka proto obsahuje agregované roční hodnoty, nikoliv původní čtvrtletní nebo jednotlivé časové záznamy.

Vzhledem ke způsobu spojení se mohou hodnoty mezd v primární tabulce opakovat pro více kategorií potravin v rámci stejného roku a odvětví. Při analytických výpočtech je proto nutné pracovat s odpovídající granularitou a zabránit vícenásobnému započítání stejné hodnoty.

Při výpočtu meziročních změn navíc první rok sledovaného období nemá hodnotu meziroční změny, protože pro její výpočet není k dispozici předchozí rok.

Podobně při použití funkce `LEAD()` není pro poslední rok dostupná hodnota následujícího roku.

Tyto hodnoty jsou proto v příslušných výpočtech `NULL` a nejsou zahrnuty např. do výpočtu korelace funkcí `CORR()` ve výzkumní otázce č. 5.

U mzdových dat jsou dostupné hodnoty za jednotlivá odvětví i za celé hospodářství. Hodnoty za celé hospodářství byly použity u výzkumných otázek, které vyžadovaly celkovou průměrnou mzdu.

Data o cenách obsahují hodnoty jednotlivých kategorií potravin. Pro výzkumné otázky 4 a 5, kde bylo potřeba pracovat s celkovým vývojem cen potravin, byla vypočtena průměrná cena z cen sledovaných kategorií potravin za jednotlivé roky.

V sekundární finální tabulce `t_ivana_amranova_project_sql_secondary_final` chybí data pro tři území uvedená v tabulce `countries`, pro která nejsou odpovídající údaje v tabulce `economies`: Holy See (Vatican City State), Northern Ireland a Svalbard and Jan Mayen.

U některých států nejsou dostupné kompletní údaje za celé sledované období a může chybět hodnota HDP nebo GINI koeficientu.

Výběr evropských zemí vychází z dostupného geografického zařazení ve zdrojových datech. Výsledná tabulka proto nemusí obsahovat pouze suverénní státy v politickém smyslu, zahrnuje také některá území geograficky řazená k Evropě.

---

# Výzkumné otázky

## 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

Pro jednotlivá odvětví byly vypočítány meziroční změny průměrných mezd - absolutní i procentuální.

### Výsledek

- **16 odvětví** zaznamenalo v období 2006 - 2018 alespoň jeden meziroční pokles mzdy.
- **3 odvětví** zaznamenala v celém sledovaném období pouze meziroční růst mezd.

Výsledky tedy ukazují, že mzdy nerostly ve všech odvětvích každoročně.

**Odvětví s alespoň jedním meziročním poklesem:**  
- *Administrativní a podpůrné činnosti*
- *Činnosti v oblasti nemovitostí*
- *Doprava a skladování*
- *Informační a komunikační činnosti*
- *Kulturní, zábavní a rekreační činnosti*
- *Peněžnictví a pojišťovnictví*
- *Profesní, vědecké a technické činnosti*
- *Stavebnictví*
- *Těžba a dobývání*
- *Ubytování, stravování a pohostinství*
- *Velkoobchod a maloobchod; opravy a údržba motorových vozidel*
- *Veřejná správa a obrana; povinné sociální zabezpečení*
- *Výroba a rozvod elektřiny, plynu, tepla a klimatiz. vzduchu*
- *Vzdělávání*
- *Zásobování vodou; činnosti související s odpady a sanacemi*
- *Zemědělství, lesnictví, rybářství*

**Odvětví bez meziročního poklesu:**  
- *Ostatní činnosti*
- *Zdravotní a sociální péče*
- *Zpracovatelský průmysl*

---

## 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období?

Pro výpočet byla porovnána průměrná mzda (`industry_branch_code is null`) s průměrnou cenou kilogramu chleba a litru mléka v letech 2006 a 2018.

### Výsledek

Za průměrnou mzdu bylo možné koupit přibližně:

| Rok | Chléb | Mléko |
|---|---:|---:|
| 2006 | 1 211,66 kg | 1 353,10 l |
| 2018 | 1 322 kg | 1 616,77 l |

Z výsledků vyplývá, že množství chleba i mléka, které bylo možné za průměrnou mzdu koupit, se mezi lety 2006 a 2018 zvýšilo.

---

## 3. Která kategorie potravin zdražuje nejpomaleji?

Pro jednotlivé kategorie potravin byl vypočítán průměrný meziroční procentuální růst jejich ceny.

### Výsledek

Nejnižší průměrný meziroční procentuální růst ceny byl zaznamenán u kategorie **cukr**, kde dosáhl hodnoty **−1,92 %**.

Záporná hodnota znamená, že průměrná cena cukru měla ve sledovaném období v průměru meziročně klesající tendenci.

Tomu odpovídá také skutečnost, že průměrná cena cukru byla v roce 2018 nižší než v roce 2006.

---

## 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?

Pro každý rok byl porovnán meziroční procentuální růst průměrných cen sledovaných potravin a meziroční procentuální růst průměrné mzdy.

Rozdíl byl vypočítán jako:

**růst cen potravin − růst mezd**

### Výsledek

V žádném ze sledovaných let nebyl meziroční růst cen sledovaných potravin o více než **10 procentních bodů** vyšší než růst průměrné mzdy.

Nejvyšší rozdíl mezi růstem cen potravin a růstem mezd činil **5,23 procentního bodu v roce 2013**.

Naopak v roce **2009** byl růst cen potravin o **9,78 procentního bodu nižší** než růst mezd.

Výsledky tedy hypotézu o více než desetiprocentním rozdílu nepotvrzují.

---

## 5. Má výška HDP vliv na změny ve mzdách a cenách potravin?
Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?

Pro Českou republiku byly z ekonomických dat získány hodnoty HDP za období 2006 - 2018.

Pro HDP byl stejně jako u mezd a cen vypočítán meziroční procentuální růst.

Následně byly porovnány:

1. meziroční změna HDP a změna mezd ve stejném roce,
2. meziroční změna HDP a změna cen potravin ve stejném roce,
3. meziroční změna HDP a změna mezd v následujícím roce,
4. meziroční změna HDP a změna cen potravin v následujícím roce.

Pro posouzení lineární souvislosti byl použit Pearsonův korelační koeficient prostřednictvím funkce `CORR()`.

Korelace pro porovnání HDP se mzdami a cenami ve stejném roce byly vypočítány z 12 dostupných pozorování. Při porovnání růstu HDP s růstem mezd a cen v následujícím roce bylo k dispozici 11 pozorování, protože pro poslední rok sledovaného období není dostupná hodnota následujícího roku.

### Výsledky

| Porovnání | Korelační koeficient |
|---|---:|
| HDP a růst mezd ve stejném roce | 0,49 |
| HDP a růst cen potravin ve stejném roce | 0,49 |
| HDP a růst mezd v následujícím roce | 0,70 |
| HDP a růst cen potravin v následujícím roce | −0,03 |

### Interpretace

Korelace mezi růstem HDP a růstem mezd ve stejném roce je přibližně **0,49**, což představuje středně silnou pozitivní lineární souvislost.

Podobně byla zjištěna přibližně **0,49 korelace** mezi růstem HDP a růstem cen potravin ve stejném roce.

Nejvyšší sledovaná korelace byla mezi růstem HDP a růstem mezd v následujícím roce, kde dosáhla přibližně **0,70**. V rámci sledovaného období tedy data ukazují poměrně silnou pozitivní lineární souvislost mezi růstem HDP a růstem mezd v následujícím roce.

Naopak korelace mezi růstem HDP a růstem cen potravin v následujícím roce byla téměř nulová (**−0,03**), což ukazuje na prakticky žádnou lineární souvislost mezi těmito dvěma veličinami v analyzovaném období.

Korelace však sama o sobě neprokazuje kauzální vztah. Výsledky proto ukazují pouze míru lineární souvislosti mezi sledovanými ukazateli, nikoliv to, že změna HDP přímo způsobuje změnu mezd nebo cen.

---

# Použité metody

V průběhu analýzy byly použity zejména:

- `AVG()` a `MAX()` pro agregaci hodnot,
- `GROUP BY`,
- `INNER JOIN` a `LEFT JOIN`,
- `LAG()` pro získání hodnoty předchozího roku,
- `LEAD()` pro získání hodnoty následujícího roku,
- výpočet absolutních a procentuálních meziročních změn,
- `CORR()` pro výpočet Pearsonova korelačního koeficientu,
- `ROUND()` pro zaokrouhlení prezentovaných výsledků.

Pro opakovaně využívaný výpočet meziročního růstu mezd a cen bylo vytvořeno view:

`v_amranova_wage_price_growth`

View obsahuje roční procentuální růst průměrných mezd a průměrných cen sledovaných potravin v srovnatelném období 2006 - 2018.

---

# Struktura SQL skriptů

SQL část projektu obsahuje:

1. vytvoření primární finální datové tabulky,
2. vytvoření sekundární finální datové tabulky,
3. vytvoření view pro meziroční růst mezd a cen,
4. SQL dotazy pro jednotlivé výzkumné otázky,

Původní zdrojová data nebyla upravována. Veškeré potřebné agregace a transformace byly provedeny až při vytváření nových tabulek, view nebo v analytických dotazech.

Primární finální tabulka byla vytvořena jako součást tohoto projektu pro sjednocení dat o mzdách a cenách na společnou roční granularitu. V běžné analytické práci by bylo možné pracovat přímo se zdrojovými tabulkami a vhodnou granularitu vytvářet až v jednotlivých analytických dotazech.

V SQL skriptech jsou pro účely projektu ponechány také dílčí kroky zpracování dat, které předcházely finálním dotazům. Tyto mezikroky slouží především k lepší přehlednosti a dokumentaci postupu analýzy.

---

# Závěr

Analýza ukázala, že:

- mzdy nerostly ve všech odvětvích každoročně,
- dostupnost chleba a mléka se mezi roky 2006 a 2018 zvýšila,
- nejnižší průměrný meziroční růst ceny byl zaznamenán u cukru,
- růst cen potravin nepřevýšil růst mezd v žádném roce o více než 10 procentních bodů,
- mezi růstem HDP a růstem mezd existovala v analyzovaném období pozitivní lineární souvislost, nejsilnější při porovnání HDP s růstem mezd v následujícím roce,
- mezi růstem HDP a růstem cen potravin v následujícím roce nebyla zjištěna významná lineární souvislost.

Výsledky představují popis vztahů v analyzovaném období let 2006 - 2018. Zejména u korelační analýzy není možné z výsledků automaticky vyvozovat příčinné vztahy.

