-- TVORBA PRIMÁRNÍ TABULKY - data mezd a cen potravin v ČR sjednocených na porovnatelné období - společné roky

-- MZDY

SELECT *
FROM czechia_payroll;

-- 1. čtvrtletní mzdy

SELECT 
	value,
	unit_code,
	industry_branch_code ,
	payroll_year,
	payroll_quarter 
FROM czechia_payroll
WHERE value_type_code = 5958
AND calculation_code = 200
ORDER BY 
		industry_branch_code,
		payroll_year,
		payroll_quarter;

-- 2. průměrné roční mzdy

WITH wages_industry_quarter AS (
	SELECT 
		industry_branch_code,
		payroll_year,
		payroll_quarter,
		value
	FROM czechia_payroll
	WHERE value_type_code = 5958
	AND calculation_code = 200
	ORDER BY 
		industry_branch_code,
		payroll_year,
		payroll_quarter
	)
SELECT 
	industry_branch_code ,
	payroll_year,
	avg(value) AS avg_wage_year
FROM wages_industry_quarter
GROUP BY
	industry_branch_code,
	payroll_year;

-- celý datový soubor 440 řádků
-- roky 2006 - 2018 260 řádků

----------------------------------------------------------
-- CENY

SELECT *
FROM czechia_price;

-- 1. extrakce roku z date_from 

SELECT 
	value,
	category_code,
	date_from,
	date_part('year', date_from) AS price_year,
	region_code
FROM czechia_price
WHERE region_code IS NULL
ORDER BY category_code, 
	price_year;


-- 2. průměrné ceny za rok

WITH prices_year_extract AS (
	SELECT 
		value,
		category_code,
		date_from,
		date_part('year', date_from) AS price_year,
		region_code
	FROM czechia_price
	WHERE region_code IS NULL
	ORDER BY category_code, 
		price_year)
SELECT 
	category_code,
	price_year,
	avg(value) AS avg_price_year
FROM prices_year_extract
GROUP BY 
	category_code,
	price_year;


-- celý datový soubor 342 řádků

--------------------------------------------------------------
-- TABULKA PRIMARY_FINAL 

-- 1. Propojení mezd a cen do jedné finální tabulky

WITH wages_industry_quarter AS (
		SELECT 
			industry_branch_code,
			payroll_year,
			payroll_quarter,
			value
		FROM czechia_payroll
		WHERE value_type_code = 5958
		AND calculation_code = 200
		),
	wages_industry_year AS (
		SELECT 
			industry_branch_code ,
			payroll_year,
			avg(value) AS avg_wage_year
		FROM wages_industry_quarter
		GROUP BY
		industry_branch_code,
		payroll_year
	),
	prices_year_extract AS (
		SELECT 
			value,
			category_code,
			date_from,
			date_part('year', date_from) AS price_year,
			region_code
		FROM czechia_price
		WHERE region_code IS NULL
		),
	prices_category_year AS (
		SELECT 
 			category_code,
			price_year,
			avg(value) AS avg_price_year
		FROM prices_year_extract
		GROUP BY 
			category_code,
			price_year
		)
SELECT 
	siy.payroll_year AS year,
	COALESCE(cpib.name, 'Celé hospodářství') AS industry_name,
	siy.avg_wage_year,
	cpu.name AS wage_unit,
	cpc.name AS category_name,
	pcy.avg_price_year,
	cpc.price_value,
	cpc.price_unit	
FROM wages_industry_year AS siy
INNER JOIN prices_category_year AS pcy
	ON siy.payroll_year = pcy.price_year
LEFT JOIN czechia_payroll_industry_branch AS cpib 
	ON siy.industry_branch_code = cpib.code
LEFT JOIN czechia_payroll_unit AS cpu
	ON cpu.code = 80403
LEFT JOIN czechia_price_category AS cpc 
	ON pcy.category_code = cpc.code
ORDER BY 
	YEAR,
	industry_name,
	category_name;

-- 6840 řádků

-- 2. VÝSLEDNÝ SQL SKRIPT - Vytvoření tabulky PRIMARY_FINAL: 

CREATE TABLE t_Ivana_Amranova_project_SQL_primary_final AS (
		WITH wages_industry_quarter AS (
			SELECT 
				industry_branch_code,
				payroll_year,
				payroll_quarter,
				value
			FROM czechia_payroll
			WHERE value_type_code = 5958
			AND calculation_code = 200
			),
		wages_industry_year AS (
			SELECT 
				industry_branch_code ,
				payroll_year,
				avg(value) AS avg_wage_year
			FROM wages_industry_quarter
			GROUP BY
				industry_branch_code,
				payroll_year
			),
		prices_year_extract AS (
			SELECT 
				value,
				category_code,
				date_from,
				date_part('year', date_from) AS price_year,
				region_code
			FROM czechia_price
			WHERE region_code IS NULL
			),
		prices_category_year AS (
			SELECT 
 				category_code,
				price_year,
				avg(value) AS avg_price_year
			FROM prices_year_extract
			GROUP BY 
				category_code,
				price_year
			)
	SELECT 
		siy.payroll_year AS year,
		COALESCE(cpib.name, 'Celé hospodářství') AS industry_name,
		siy.avg_wage_year,
		cpu.name AS wage_unit,
		cpc.name AS category_name,
		pcy.avg_price_year,
		cpc.price_value,
		cpc.price_unit	
	FROM wages_industry_year AS siy
	INNER JOIN prices_category_year AS pcy
		ON siy.payroll_year = pcy.price_year
	LEFT JOIN czechia_payroll_industry_branch AS cpib 
		ON siy.industry_branch_code = cpib.code
	LEFT JOIN czechia_payroll_unit AS cpu
		ON cpu.code = 80403
	LEFT JOIN czechia_price_category AS cpc 
		ON pcy.category_code = cpc.code
	ORDER BY 
		YEAR,
		industry_name,
		category_name
	);
