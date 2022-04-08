SELECT *
FROM portfolio_project.deaths
WHERE continent <> ""
ORDER BY 3,4

SELECT *
FROM portfolio_project.vaccinations
ORDER BY 3,4

-- select the data to use

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM portfolio_project.deaths
WHERE continent <> ""
ORDER BY 1,2

-- looking at total cases vs total deaths 
-- shows the likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM portfolio_project.deaths
WHERE location like '%states%'
and continent <> ""
ORDER BY 1,2

-- looking at total case vs population 
-- shows percentage of population that got covid

SELECT location, date, population, total_cases, (total_cases/population)*100 as percent_pop_infected
FROM portfolio_project.deaths
-- WHERE location like '%states%'
ORDER BY 1,2

-- look at countries with highest infection rate compared to population 

SELECT location, population, MAX(total_cases) as highest_infection_count, MAX((total_cases/population))*100 as percent_pop_infected
FROM portfolio_project.deaths
-- WHERE location like '%states%'
WHERE location NOT IN ('European Union', 'Europe', 'World', 'International', 'Africa', 'South America')
and location NOT LIKE ('%income%')
GROUP BY location, population
ORDER BY percent_pop_infected desc


-- showing the countries with the highest death count per population

SELECT location, MAX(cast(total_deaths as signed)) as total_death_count 
FROM portfolio_project.deaths
WHERE continent <> ""
GROUP BY location
ORDER BY total_death_count desc

-- break things down by continent 
-- showing the continents with the highest death count per population

SELECT continent, MAX(cast(total_deaths as signed)) as total_death_count 
FROM portfolio_project.deaths
WHERE continent <> ""
and location not like '%income%'
GROUP BY continent
ORDER BY total_death_count desc 

-- more accurate 

SELECT continent, SUM(cast(new_deaths as signed)) as total_death_count 
FROM portfolio_project.deaths
WHERE continent <> ""
GROUP BY continent
ORDER BY total_death_count desc


-- global numbers

-- total new cases and death per day in the world 

SELECT date, SUM(new_cases) as total_cases,SUM(cast(new_deaths as signed)) as total_deaths,SUM(cast(new_deaths as signed))/SUM(new_cases)*100 as death_percentage
FROM portfolio_project.deaths
WHERE continent <> ""
GROUP BY date
ORDER BY 1,2

-- total cases and deaths in world

SELECT SUM(new_cases) as total_cases,SUM(cast(new_deaths as signed)) as total_deaths,SUM(cast(new_deaths as signed))/SUM(new_cases)*100 as death_percentage
FROM portfolio_project.deaths
WHERE continent <> ""
ORDER BY 1,2

-- looking at total population vs vaccinations with rolling vaccine count 

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
, SUM(CONVERT(vac.new_vaccinations, signed)) OVER (PARTITION BY dea.location 
ORDER BY dea.location, dea.date) as rolling_people_vaccinated
FROM portfolio_project.deaths dea
JOIN portfolio_project.vaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent <> ""
ORDER BY 2,3

-- use CTE to show rolling percent of pop vaccinated with rolling vaccination count

WITH pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
, SUM(CONVERT(vac.new_vaccinations, signed)) OVER (PARTITION BY dea.location 
ORDER BY dea.location, dea.date) as rolling_people_vaccinated
FROM portfolio_project.deaths dea
JOIN portfolio_project.vaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent <> ""
)
SELECT *, (rolling_people_vaccinated/population)*100
FROM pop_vs_vac

-- temp table 

DROP TEMPORARY TABLE IF EXISTS percent_pop_vaccinated;
CREATE TEMPORARY TABLE percent_pop_vaccinated 
(
continent TEXT,
location TEXT,
date date,
population NUMERIC,
new_vaccinations NUMERIC,
rolling_people_vaccinated NUMERIC
);
INSERT IGNORE INTO percent_pop_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
, SUM(CAST(vac.new_vaccinations as signed)) OVER (PARTITION BY dea.location 
ORDER BY dea.location, dea.date) as rolling_people_vaccinated
FROM portfolio_project.deaths dea
JOIN portfolio_project.vaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent <> "";

SELECT *, (rolling_people_vaccinated/population)*100
FROM percent_pop_vaccinated

-- creating view to store data for later visualizations

CREATE VIEW percent_vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
, SUM(CAST(vac.new_vaccinations as signed)) OVER (PARTITION BY dea.location 
ORDER BY dea.location, dea.date) as rolling_people_vaccinated
FROM portfolio_project.deaths dea
JOIN portfolio_project.vaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent <> "";

SELECT * 
FROM percent_vaccinated
