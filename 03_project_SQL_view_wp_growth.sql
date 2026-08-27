-- VYTVOŘENÍ VIEW PRO VÝZKUMNÍ OTÁZKU Č. 5
-- roční procentuální růst průměrných mezd a průměrných cen sledovaných potravin v období 2006 - 2018

CREATE VIEW v_amranova_wage_price_growth AS 
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
	wage_growth AS (
	SELECT 
		YEAR,
		industry_name,
		avg_wage_year,
		avg_wage_previous_year,
		avg_wage_year - avg_wage_previous_year AS difference,
		(avg_wage_year - avg_wage_previous_year)/avg_wage_previous_year * 100 AS wage_growth_percentage
	FROM avg_wage_previous_year
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
	price_growth AS (
	SELECT 
		YEAR,
		avg_price_all_categories,
		avg_price_all_previous,
		avg_price_all_categories - avg_price_all_previous AS difference,
		(avg_price_all_categories - avg_price_all_previous)/avg_price_all_previous * 100 AS price_growth_percentage
	FROM prices_all_categories_previous
	)
SELECT 
	wg.YEAR,
	wg.wage_growth_percentage,
	pg.price_growth_percentage
FROM wage_growth wg
INNER JOIN price_growth pg
	ON wg.YEAR = pg.YEAR;