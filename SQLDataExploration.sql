SELECT *
FROM PortfolioProjects.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT *
--FROM PortfolioProjects..CovidVaccinations
--WHERE continent IS NOT NULL
--ORDER BY 3,4

-- Select the data that we are going to be starting with

Select location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Total Cases vs. Total Deaths
	-- Convert the data type to float
	-- Use NULLIF to handle the possibility of division by zero 
--Shows likelihood of dying if you contract covid in your country 

Select location, date, total_cases, total_deaths,(CONVERT(float,total_deaths)/NULLIF(CONVERT(float, total_cases), 0))*100 AS DeathPercentage
FROM PortfolioProjects..CovidDeaths
WHERE location like '%states%'
AND continent IS NOT NULL
ORDER BY 1,2


-- Total Cases Vs Population
-- Shows the percentage of population infected with Covid

Select location, date, total_cases, population, (total_cases/population)* 100 AS PercentPopulationInfected
FROM PortfolioProjects..CovidDeaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Countries with Highest Infection Rate compared to the Population

Select location, population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)* 100 AS PercentPopulationInfected
FROM PortfolioProjects..CovidDeaths
--WHERE location like '%states%'
GROUP BY Location, population
ORDER BY PercentPopulationInfected DESC

-- Countries with the Highest Death Count per Popultion

Select location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM PortfolioProjects..CovidDeaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- Breaking things down by Continent

-- Showing continents with the Highest Death Count per Population

Select continent, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM PortfolioProjects..CovidDeaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Global Numbers

Select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, (SUM(new_deaths)/SUM(new_cases))*100 as DeathPercentage --, total_deaths, (CONVERT (float, total_deaths)/ NULLIF (CONVERT (float, total_cases),0))* 100 as DeathPercentage
FROM PortfolioProjects..CovidDeaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL and new_cases is not NULL
--Group By date
ORDER BY 1, 2


-- Looking at Total Populations vs Vaccination
-- Percentage of Population that has atleast one Covid Vaccine



-- What is the total number of people that have been vaccinated
-- do a rolling count of new vaccinations by location, 
-- Partition by location because we want the count to start over everytime there is a new location

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT( BIGINT, vac.new_vaccinations)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated-- can aslo do CAST(vac.new_vaccinations as BIGINT)
FROM PortfolioProjects..CovidDeaths dea
JOIN PortfolioProjects..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--Using CTE to perform calculation on PARTITION BY
-- We want to know how many people in a country are vaccinated. 
-- For this we use the MAX(RollingPeopleVaccinated) and divide it by the population 
-- We use a CTE to achieve this goal

WITH PopvsVac (Continent, location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT( BIGINT, vac.new_vaccinations)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated-- can aslo do CAST(vac.new_vaccinations as BIGINT)
FROM PortfolioProjects..CovidDeaths dea
JOIN PortfolioProjects..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac

-- Using a Temp table to perform calculation on PARTITION BY

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT( BIGINT, vac.new_vaccinations)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated-- can aslo do CAST(vac.new_vaccinations as BIGINT)
FROM PortfolioProjects..CovidDeaths dea
JOIN PortfolioProjects..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)/100
FROM #PercentPopulationVaccinated

-- Creating view to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT( BIGINT, vac.new_vaccinations)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated-- can aslo do CAST(vac.new_vaccinations as BIGINT)
FROM PortfolioProjects..CovidDeaths dea
JOIN PortfolioProjects..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3


SELECT *
FROM PercentPopulationVaccinated