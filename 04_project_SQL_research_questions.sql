-- VÝZKUMNÁ OTÁZKA Č.1: Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

-- 1. vrácení se na původní granularitu před spojením dat - year, industry, avg_salary a vyloučení Celého hospodářství

SELECT
	YEAR,
	industry_name,
	max(avg_wage_year) AS avg_wage_year,
	wage_unit
FROM t_Ivana_Amranova_project_SQL_primary_final
GROUP BY
	YEAR,
	industry_name,
	wage_unit
HAVING industry_name != 'Celé hospodářství'
ORDER BY
	YEAR,
	industry_name;

-- 247 řádků

-- 2. výpočet meziročních rozdílů

WITH wages_industry_year AS (
	SELECT
		YEAR,
		industry_name,
		max(avg_wage_year) AS avg_wage_year,
		wage_unit
	FROM t_Ivana_Amranova_project_SQL_primary_final
	GROUP BY
		YEAR,
		industry_name,
		wage_unit
	HAVING industry_name != 'Celé hospodářství'
	)
SELECT 
	YEAR,
	industry_name,
	avg_wage_year,
	lag(avg_wage_year) OVER (PARTITION BY industry_name ORDER BY year) AS avg_wage_previous_year,
	avg_wage_year - lag(avg_wage_year) OVER (PARTITION BY industry_name ORDER BY year) AS difference,
	(avg_wage_year - lag(avg_wage_year) OVER (PARTITION BY industry_name ORDER BY year))/lag(avg_wage_year) OVER (PARTITION BY industry_name ORDER BY year) * 100 AS percentage_difference
FROM wages_industry_year;

-- 3. VÝSLEDNÉ SQL SKRIPTY - analýza růstu/poklesu: 

-- pokles napříč roky a odvětvími:

WITH wages_industry_year AS (
	SELECT
		YEAR,
		industry_name,
		max(avg_wage_year) AS avg_wage_year,
		wage_unit
	FROM t_Ivana_Amranova_project_SQL_primary_final
	GROUP BY
		YEAR,
		industry_name,
		wage_unit
	HAVING industry_name != 'Celé hospodářství'
	),
	wages_industry_differencies AS (
	SELECT 
		YEAR,
		industry_name,
		avg_wage_year,
		lag(avg_wage_year) OVER (PARTITION BY industry_name ORDER BY year) AS avg_wage_previous_year,
		avg_wage_year - lag(avg_wage_year) OVER (PARTITION BY industry_name ORDER BY year) AS difference,
		(avg_wage_year - lag(avg_wage_year) OVER (PARTITION BY industry_name ORDER BY year))/lag(avg_wage_year) OVER (PARTITION BY industry_name ORDER BY year) * 100 AS percentage_difference
	FROM wages_industry_year
	)
SELECT
	YEAR,
	industry_name,
	difference,
	round(percentage_difference::NUMERIC,2) AS percentage_difference
FROM wages_industry_differencies
WHERE difference < 0
ORDER BY 
	industry_name,
	YEAR;

-- seznam odvětví s alespoň jedním zaznamenaným meziročním poklesem mezd (16 řádků):

WITH wages_industry_year AS (
	SELECT
		YEAR,
		industry_name,
		max(avg_wage_year) AS avg_wage_year,
		wage_unit
	FROM t_Ivana_Amranova_project_SQL_primary_final
	GROUP BY
		YEAR,
		industry_name,
		wage_unit
	HAVING industry_name != 'Celé hospodářství'
	),
	wages_industry_differencies AS (
	SELECT 
		YEAR,
		industry_name,
		avg_wage_year,
		lag(avg_wage_year) OVER (PARTITION BY industry_name ORDER BY year) AS avg_wage_previous_year,
		avg_wage_year - lag(avg_wage_year) OVER (PARTITION BY industry_name ORDER BY year) AS difference,
		(avg_wage_year - lag(avg_wage_year) OVER (PARTITION BY industry_name ORDER BY year))/lag(avg_wage_year) OVER (PARTITION BY industry_name ORDER BY year) * 100 AS percentage_difference
	FROM wages_industry_year
	)
SELECT DISTINCT industry_name
FROM wages_industry_differencies
WHERE difference < 0
ORDER BY
 industry_name;

-- seznam odvětví bez meziročního poklesu mezd (3 řádky):

WITH wages_industry_year AS (
	SELECT
		YEAR,
		industry_name,
		max(avg_wage_year) AS avg_wage_year,
		wage_unit
	FROM t_Ivana_Amranova_project_SQL_primary_final
	GROUP BY
		YEAR,
		industry_name,
		wage_unit
	HAVING industry_name != 'Celé hospodářství'
	),
	wages_industry_differencies AS (
	SELECT 
		YEAR,
		industry_name,
		avg_wage_year,
		lag(avg_wage_year) OVER (PARTITION BY industry_name ORDER BY year) AS avg_wage_previous_year,
		avg_wage_year - lag(avg_wage_year) OVER (PARTITION BY industry_name ORDER BY year) AS difference,
		(avg_wage_year - lag(avg_wage_year) OVER (PARTITION BY industry_name ORDER BY year))/lag(avg_wage_year) OVER (PARTITION BY industry_name ORDER BY year) * 100 AS percentage_difference
	FROM wages_industry_year
	)
SELECT
    industry_name
FROM wages_industry_differencies
GROUP BY
    industry_name
HAVING COUNT(*) FILTER (WHERE difference < 0) = 0
ORDER BY
    industry_name;

-------------------------------------------------------------------------------------

-- VÝZKUMNÁ OTÁZKA Č. 2: 
-- Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?

-- VÝSLEDNÝ SQL SKRIPT - porovnání ceny mléka a chleba v letech 2006 a 2018 s průměrnou mzdou celého hospodářství v daných letech:

SELECT 
	YEAR,
	category_name,
	avg_price_year,
	price_value,
	price_unit,
	avg_wage_year,
	wage_unit,
	round((avg_wage_year/avg_price_year)::NUMERIC, 2) AS amount_purchase
FROM t_Ivana_Amranova_project_SQL_primary_final
WHERE YEAR IN ('2006', '2018')
	AND category_name IN ('Mléko polotučné pasterované', 'Chléb konzumní kmínový')
	AND industry_name = 'Celé hospodářství';


---------------------------------------------------------------------------------------

-- VÝZKUMNÁ OTÁZKA Č. 3: Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)? 

-- 1. vrácení se na původní granularitu před spojením dat mezd a cen

SELECT 
	YEAR,
	category_name,
	max(avg_price_year) AS avg_price_year,
	price_value,
	price_unit
FROM t_Ivana_Amranova_project_SQL_primary_final
GROUP BY 
	category_name,
	YEAR,
	price_value,
	price_unit
ORDER BY 
	category_name,
	year;

-- 2. výpočet meziročních rozdílů

WITH prices_category_year AS (
	SELECT 
		YEAR,
		category_name,
		max(avg_price_year) AS avg_price_year,
		price_value,
		price_unit
	FROM t_Ivana_Amranova_project_SQL_primary_final
	GROUP BY 
		category_name,
		YEAR,
		price_value,
		price_unit
	),
	prices_category_previous_year AS (
	SELECT 
		YEAR,
		category_name,
		price_value,
		price_unit,
		avg_price_year,
		lag(avg_price_year) OVER (PARTITION BY category_name ORDER BY year) AS avg_price_previous_year
	FROM prices_category_year
	)
SELECT 
	YEAR,
	category_name,
	price_value,
	price_unit,
	avg_price_year,
	avg_price_year - avg_price_previous_year AS difference,
	(avg_price_year - avg_price_previous_year)/avg_price_previous_year * 100 AS percentage_difference
FROM prices_category_previous_year;
	
-- 3. výpočet průměrného meziročního růstu cen pro danou kategorii

WITH prices_category_year AS (
	SELECT 
		YEAR,
		category_name,
		max(avg_price_year) AS avg_price_year,
		price_value,
		price_unit
	FROM t_Ivana_Amranova_project_SQL_primary_final
	GROUP BY 
		category_name,
		YEAR,
		price_value,
		price_unit
	),
	prices_category_previous_year AS (
	SELECT 
		YEAR,
		category_name,
		price_value,
		price_unit,
		avg_price_year,
		lag(avg_price_year) OVER (PARTITION BY category_name ORDER BY year) AS avg_price_previous_year
	FROM prices_category_year
	),
	prices_category_differencies AS (
	SELECT 
		YEAR,
		category_name,
		price_value,
		price_unit,
		avg_price_year,
		avg_price_year - avg_price_previous_year AS difference,
		(avg_price_year - avg_price_previous_year)/avg_price_previous_year * 100 AS percentage_difference
	FROM prices_category_previous_year
	)
SELECT
	YEAR,
	category_name,
	difference,
	percentage_difference,
	avg(percentage_difference) OVER (PARTITION BY category_name) AS avg_percentage_difference
FROM prices_category_differencies;

-- 4. VÝSLEDNÝ SQL SKRIPT - seznam kategorií potravin podle průměrného meziročního růstu:
	
WITH prices_category_year AS (
	SELECT 
		YEAR,
		category_name,
		max(avg_price_year) AS avg_price_year,
		price_value,
		price_unit
	FROM t_Ivana_Amranova_project_SQL_primary_final
	GROUP BY 
		category_name,
		YEAR,
		price_value,
		price_unit
	),
	prices_category_previous_year AS (
	SELECT 
		YEAR,
		category_name,
		price_value,
		price_unit,
		avg_price_year,
		lag(avg_price_year) OVER (PARTITION BY category_name ORDER BY year) AS avg_price_previous_year
	FROM prices_category_year
	),
	prices_category_differencies AS (
	SELECT 
		YEAR,
		category_name,
		price_value,
		price_unit,
		avg_price_year,
		avg_price_year - avg_price_previous_year AS difference,
		(avg_price_year - avg_price_previous_year)/avg_price_previous_year * 100 AS percentage_difference
	FROM prices_category_previous_year
	),
	prices_category_growth AS (
	SELECT
		YEAR,
		category_name,
		difference,
		percentage_difference,
		avg(percentage_difference) OVER (PARTITION BY category_name) AS avg_percentage_difference
	FROM prices_category_differencies
	)
SELECT DISTINCT
	category_name,
	round(avg_percentage_difference::NUMERIC, 2) AS avg_percentage_difference
FROM prices_category_growth
ORDER BY avg_percentage_difference;

------------------------------------------------------------------------------------------

-- VÝZKUMNÁ OTÁZKA Č. 4: Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?

-- 1. průměrné mzdy za celé hospodářství v letech 2006 - 2018

SELECT
	YEAR,
	industry_name,
	max(avg_wage_year) AS avg_wage_year,
	wage_unit
FROM t_Ivana_Amranova_project_SQL_primary_final
WHERE industry_name = 'Celé hospodářství'
GROUP BY
	YEAR,
	industry_name,
	wage_unit
ORDER BY
	YEAR;

-- 2. výpočet meziročních rozdílů

WITH avg_wage_year AS (
	SELECT
		YEAR,
		industry_name,
		max(avg_wage_year) AS avg_wage_year,
		wage_unit
	FROM t_Ivana_Amranova_project_SQL_primary_final
	WHERE industry_name = 'Celé hospodářství'
	GROUP BY
		YEAR,
		industry_name,
		wage_unit
	),
	avg_wage_previous_year AS (
	SELECT 
		YEAR,
		industry_name,
		avg_wage_year,
		LAG(avg_wage_year) OVER (ORDER BY year) AS avg_wage_previous_year
	FROM avg_wage_year
	),
	avg_wage_differences AS (
	SELECT 
		YEAR,
		industry_name,
		avg_wage_year,
		avg_wage_previous_year,
		avg_wage_year - avg_wage_previous_year AS difference,
		(avg_wage_year - avg_wage_previous_year)/avg_wage_previous_year * 100 AS wage_percentage_difference
	FROM avg_wage_previous_year
	)
SELECT 
	YEAR,
	wage_percentage_difference
FROM avg_wage_differences;

-- 3. průměrné ceny jednotlivých kategorií potravin v letech 2006 - 2018

SELECT 
	YEAR,
	category_name,
	max(avg_price_year) AS avg_price_year,
	price_value,
	price_unit
FROM t_Ivana_Amranova_project_SQL_primary_final
GROUP BY 
	category_name,
	YEAR,
	price_value,
	price_unit
ORDER BY 
	YEAR,
	category_name;

-- 4. průměrná cena všech sledovaných kategorií potravin

WITH prices_category_year AS (
	SELECT 
		YEAR,
		category_name,
		max(avg_price_year) AS avg_price_year,
		price_value,
		price_unit
	FROM t_Ivana_Amranova_project_SQL_primary_final
	GROUP BY 
		category_name,
		YEAR,
		price_value,
		price_unit
	)
SELECT
	YEAR,
	avg(avg_price_year) AS avg_price_all_categories
FROM prices_category_year
GROUP BY year
ORDER BY YEAR

-- 5. výpočet meziročních rozdílů cen potravin

WITH prices_category_year AS (
	SELECT 
		YEAR,
		category_name,
		max(avg_price_year) AS avg_price_year,
		price_value,
		price_unit
	FROM t_Ivana_Amranova_project_SQL_primary_final
	GROUP BY 
		category_name,
		YEAR,
		price_value,
		price_unit
	),
	prices_all_categories AS (
	SELECT
		YEAR,
		avg(avg_price_year) AS avg_price_all_categories
	FROM prices_category_year
	GROUP BY year
	),
	prices_all_categories_previous AS (
	SELECT 
		YEAR,
		avg_price_all_categories,
		lag(avg_price_all_categories) OVER (ORDER BY year) AS avg_price_all_previous
	FROM prices_all_categories
	),
	avg_price_difference AS (
	SELECT 
		YEAR,
		avg_price_all_categories,
		avg_price_all_previous,
		avg_price_all_categories - avg_price_all_previous AS difference,
		(avg_price_all_categories - avg_price_all_previous)/avg_price_all_previous * 100 AS price_percentage_difference
	FROM prices_all_categories_previous
	)
SELECT
	YEAR,
	price_percentage_difference
FROM avg_price_difference;


-- 6. VÝSLEDNÝ SQL SKRIPT - porovnání meziročního růstu cen a mezd:

WITH avg_wage_year AS (
	SELECT
		YEAR,
		industry_name,
		max(avg_wage_year) AS avg_wage_year,
		wage_unit
	FROM t_Ivana_Amranova_project_SQL_primary_final
	WHERE industry_name = 'Celé hospodářství'
	GROUP BY
		YEAR,
		industry_name,
		wage_unit
	),
	avg_wage_previous_year AS (
	SELECT 
		YEAR,
		industry_name,
		avg_wage_year,
		LAG(avg_wage_year) OVER (ORDER BY year) AS avg_wage_previous_year
	FROM avg_wage_year
	),
	avg_wage_differences AS (
	SELECT 
		YEAR,
		industry_name,
		avg_wage_year,
		avg_wage_previous_year,
		avg_wage_year - avg_wage_previous_year AS difference,
		(avg_wage_year - avg_wage_previous_year)/avg_wage_previous_year * 100 AS wage_percentage_difference
	FROM avg_wage_previous_year
	),
	wage_growth AS (
	SELECT 
		YEAR,
		wage_percentage_difference
	FROM avg_wage_differences
	),
	prices_category_year AS (
	SELECT 
		YEAR,
		category_name,
		max(avg_price_year) AS avg_price_year,
		price_value,
		price_unit
	FROM t_Ivana_Amranova_project_SQL_primary_final
	GROUP BY 
		category_name,
		YEAR,
		price_value,
		price_unit
	),
	prices_all_categories AS (
	SELECT
		YEAR,
		avg(avg_price_year) AS avg_price_all_categories
	FROM prices_category_year
	GROUP BY year
	),
	prices_all_categories_previous AS (
	SELECT 
		YEAR,
		avg_price_all_categories,
		lag(avg_price_all_categories) OVER (ORDER BY year) AS avg_price_all_previous
	FROM prices_all_categories
	),
	avg_price_difference AS (
	SELECT 
		YEAR,
		avg_price_all_categories,
		avg_price_all_previous,
		avg_price_all_categories - avg_price_all_previous AS difference,
		(avg_price_all_categories - avg_price_all_previous)/avg_price_all_previous * 100 AS price_percentage_difference
	FROM prices_all_categories_previous
	),
	price_growth AS (
	SELECT
		YEAR,
		price_percentage_difference
	FROM avg_price_difference
	)
SELECT 
	wg.YEAR,
	round(wg.wage_percentage_difference::NUMERIC, 2) AS wage_percentage_difference,
	round(pg.price_percentage_difference::NUMERIC, 2) AS price_percentage_difference,
	round((pg.price_percentage_difference - wg.wage_percentage_difference)::NUMERIC, 2) AS price_wage_growth_gap
FROM wage_growth wg
INNER JOIN price_growth pg
	ON wg.YEAR = pg.YEAR
ORDER BY price_wage_growth_gap DESC;


--------------------------------------------------------------------

-- VÝZKUMNÁ OTÁZKA Č. 5: 
-- Má výška HDP vliv na změny ve mzdách a cenách potravin? 
-- Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?


-- 1. HDP pro ČR ve sledovaném období a výpočet meziročního procentního růstu 

WITH gdp_year AS (
	SELECT
		country,
		YEAR,
		gdp
	FROM t_ivana_amranova_project_SQL_secondary_final
	WHERE country = 'Czech Republic'
		AND YEAR BETWEEN '2006' AND '2018'
	),
	gdp_previous_year as (
	SELECT 
		YEAR,
		gdp,
		LAG(gdp) OVER (ORDER BY year) AS gdp_previous_year
	FROM gdp_year
	),
	gdp_pct_difference AS (
	SELECT 
		YEAR,
		gdp,
		gdp_previous_year,
		gdp - gdp_previous_year AS difference,
		(gdp - gdp_previous_year)/gdp_previous_year * 100 AS gdp_growth_percentage
	FROM gdp_previous_year
	)
SELECT 
	YEAR,
	gdp_growth_percentage
FROM gdp_pct_difference;

-- 2. tvorba VIEW pro data meziročního růstu mezd a cen - uloženo v souboru 'project_SQL_view_wp_growth.sql'

-- 3. spojení meziročního růstu HDP, mezd a cen

WITH gdp_year AS (
	SELECT
		YEAR,
		gdp
	FROM t_ivana_amranova_project_SQL_secondary_final
	WHERE country = 'Czech Republic'
		AND YEAR BETWEEN '2006' AND '2018'
	),
	gdp_previous_year as (
	SELECT 
		YEAR,
		gdp,
		LAG(gdp) OVER (ORDER BY year) AS gdp_previous_year
	FROM gdp_year
	),
	gdp_growth AS (
	SELECT 
		YEAR,
		gdp,
		gdp_previous_year,
		gdp - gdp_previous_year AS difference,
		(gdp - gdp_previous_year)/gdp_previous_year * 100 AS gdp_growth_percentage
	FROM gdp_previous_year
	)
SELECT
	gg.YEAR,
	gg.gdp_growth_percentage,
	wpg.wage_growth_percentage,
	wpg.price_growth_percentage 
FROM gdp_growth gg
INNER JOIN v_amranova_wage_price_growth wpg
	ON gg.YEAR = wpg.YEAR;

-- 4. porovnání růstu HDP, mezd a cen ve stejném a následujícím roce

WITH gdp_year AS (
	SELECT
		YEAR,
		gdp
	FROM t_ivana_amranova_project_SQL_secondary_final
	WHERE country = 'Czech Republic'
		AND YEAR BETWEEN '2006' AND '2018'
	),
	gdp_previous_year as (
	SELECT 
		YEAR,
		gdp,
		LAG(gdp) OVER (ORDER BY year) AS gdp_previous_year
	FROM gdp_year
	),
	gdp_growth AS (
	SELECT 
		YEAR,
		gdp,
		gdp_previous_year,
		gdp - gdp_previous_year AS difference,
		(gdp - gdp_previous_year)/gdp_previous_year * 100 AS gdp_growth_percentage
	FROM gdp_previous_year
	),
	gdp_wage_price_growth AS (
	SELECT
		gg.YEAR,
		gg.gdp_growth_percentage,
		wpg.wage_growth_percentage,
		wpg.price_growth_percentage 
	FROM gdp_growth gg
	INNER JOIN v_amranova_wage_price_growth wpg
		ON gg.YEAR = wpg.YEAR
	)
	SELECT 
		YEAR,
		gdp_growth_percentage,
		wage_growth_percentage,
		LEAD(wage_growth_percentage) OVER (ORDER BY year) AS wage_growth_next_year,
		price_growth_percentage,
		LEAD(price_growth_percentage) OVER (ORDER BY year) AS price_growth_next_year
	FROM gdp_wage_price_growth;

-- 5. VÝSLEDNÝ SQL SKRIPT - výpočet korelace a analýza souvislosti růstu HDP, mezd a cen:

WITH gdp_year AS (
	SELECT
		YEAR,
		gdp
	FROM t_ivana_amranova_project_SQL_secondary_final
	WHERE country = 'Czech Republic'
		AND YEAR BETWEEN '2006' AND '2018'
	),
	gdp_previous_year as (
	SELECT 
		YEAR,
		gdp,
		LAG(gdp) OVER (ORDER BY year) AS gdp_previous_year
	FROM gdp_year
	),
	gdp_growth AS (
	SELECT 
		YEAR,
		gdp,
		gdp_previous_year,
		gdp - gdp_previous_year AS difference,
		(gdp - gdp_previous_year)/gdp_previous_year * 100 AS gdp_growth_percentage
	FROM gdp_previous_year
	),
	gdp_wage_price_growth AS (
	SELECT
		gg.YEAR,
		gg.gdp_growth_percentage,
		wpg.wage_growth_percentage,
		wpg.price_growth_percentage 
	FROM gdp_growth gg
	INNER JOIN v_amranova_wage_price_growth wpg
		ON gg.YEAR = wpg.YEAR
	),
	growth_comparison AS (
	SELECT 
		YEAR,
		gdp_growth_percentage,
		wage_growth_percentage,
		LEAD(wage_growth_percentage) OVER (ORDER BY year) AS wage_growth_next_year,
		price_growth_percentage,
		LEAD(price_growth_percentage) OVER (ORDER BY year) AS price_growth_next_year
	FROM gdp_wage_price_growth
	)
SELECT
	round(corr(gdp_growth_percentage, wage_growth_percentage)::NUMERIC, 2) AS gdp_wage_correlation,
	round(corr(gdp_growth_percentage, price_growth_percentage)::NUMERIC, 2) AS gdp_price_correlation,
	round(corr(gdp_growth_percentage, wage_growth_next_year)::NUMERIC, 2) AS gdp_wage_next_year_correlation,
	round(corr(gdp_growth_percentage, price_growth_next_year)::NUMERIC, 2) AS gdp_price_next_year_correlation
FROM growth_comparison;

