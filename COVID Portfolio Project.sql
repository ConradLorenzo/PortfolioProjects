SELECT *
FROM covid_deaths
WHERE continent is not null
ORDER BY 3, 4


-- Select Data that we are going to be using
Select Location, date, total_cases, new_cases, total_deaths, population
From covid_deaths
Order By 1


-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract covid in Philippines
Select Location, date, total_cases, total_deaths, (cast(total_deaths as float))/(cast(total_cases as float))*100 as DeathPercentage
From covid_deaths
WHERE location like '%Philippines%'
Order By 2 DESC


-- Looking at Total Cases vs Population
-- Shows what percentage of population got covid
Select Location, date, population, total_cases, (cast(total_cases as float))/(cast(population as float))*100 as PercentPopulationInfected
From covid_deaths
WHERE location like '%Philippines%'
Order By 2 DESC


-- Looking at Countries with Highest Infection Rate compared to Population
Select Location, population, MAX(total_cases) as HighestInfectionCount, MAX((cast(total_cases as float))/(cast(population as float)))*100 as PercentPopulationInfected
From covid_deaths
Group By Location, population
Order By PercentPopulationInfected DESC


-- Showing Countries with Highest Death Count per Population
Select Location, MAX(CAST(total_deaths as int)) as TotalDeathCount
From covid_deaths
WHERE continent is not null
Group By Location
Order By TotalDeathCount DESC


-- We are going to break it down by Continent
-- Showing continents with the highest death count per population
Select continent, MAX(CAST(total_deaths as int)) as TotalDeathCount
From covid_deaths
WHERE continent is not null
	AND location NOT IN ('High income', 'Upper middle income', 'Lower middle income', 'Low income')
Group By continent
Order By TotalDeathCount DESC


-- Global Numbers
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
CASE
	WHEN SUM(new_cases) = 0 then 0
	ELSE SUM(cast(new_deaths as int))/SUM(new_cases)*100
END as DeathPercentage
From covid_deaths
WHERE continent is not null
GROUP BY date
Order By 1 DESC

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
CASE
	WHEN SUM(new_cases) = 0 then 0
	ELSE SUM(cast(new_deaths as int))/SUM(new_cases)*100
END as DeathPercentage
From covid_deaths
WHERE continent is not null
--GROUP BY date
Order By 1 DESC


-- Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


-- USE CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, people_vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (people_vaccinated/population)*100
FROM PopvsVac
ORDER BY 2,3


-- TEMP TABLE
DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
    continent nvarchar(255),
    location nvarchar(255),
    date datetime,
    population numeric,
    new_vaccinations numeric,
    people_vaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--order by 2,3

SELECT *, (people_vaccinated/population)*100
FROM #PercentPopulationVaccinated


-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

CREATE VIEW ContinentsHighestDeathCount as
Select continent, MAX(CAST(total_deaths as int)) as TotalDeathCount
From covid_deaths
WHERE continent is not null
	AND location NOT IN ('High income', 'Upper middle income', 'Lower middle income', 'Low income')
Group By continent

CREATE VIEW GlobalDeathNumbers as
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
CASE
	WHEN SUM(new_cases) = 0 then 0
	ELSE SUM(cast(new_deaths as int))/SUM(new_cases)*100
END as DeathPercentage
From covid_deaths
WHERE continent is not null
GROUP BY date