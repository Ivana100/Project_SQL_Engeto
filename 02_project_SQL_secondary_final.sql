-- TVORBA SEKUNDÁRNÍ TABULKY - dodatečná data o dalších evropských státech

-- 1. selekce evropských zemí

SELECT 
	country,
	continent
FROM countries
WHERE continent = 'Europe';

-- 2. selekce relevantních dat pro porovnatelné období 2006 - 2008

SELECT 
	country,
	YEAR,
	gdp,
	gini,
	population
FROM economies
WHERE YEAR BETWEEN 2006 and 2018;

-- 3. VÝSLEDNÝ SQL SKRIPT - Vytvoření tabulky SECONDARY_FINAL: 

CREATE TABLE t_ivana_amranova_project_SQL_secondary_final AS (
	WITH continent AS (
		SELECT 
			country,
			continent
		FROM countries
		WHERE continent = 'Europe'
		),
		countries_data AS (
		SELECT 
			country,
			YEAR,
			gdp,
			gini,
			population
		FROM economies
		WHERE YEAR BETWEEN 2006 and 2018
		)
	SELECT 
		c.country,
		cd.YEAR,
		cd.gdp,
		cd.gini,
		cd.population
	FROM continent c
	LEFT JOIN countries_data cd
	ON c.country = cd.country
	ORDER BY
		country,
		YEAR
	);

