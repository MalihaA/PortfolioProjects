
/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

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
FROM PortfolioProjects.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Total Cases vs. Total Deaths
	-- Convert the data type to float where needed
	-- Use NULLIF to handle the possibility of division by zero 
--Shows likelihood of dying if you contract covid in your country 

Select location, date, total_cases, total_deaths,(CONVERT(float,total_deaths)/NULLIF(CONVERT(float, total_cases), 0))*100 AS DeathPercentage
FROM PortfolioProjects..CovidDeaths
WHERE location like '%states%'
AND continent IS NOT NULL
ORDER BY 1,2

-- Total Cases Vs Population
-- Shows the percentage of population infected with Covid

Select location, date, population, total_cases, (CONVERT(float, total_cases)/population)* 100 AS PercentPopulationInfected
FROM PortfolioProjects..CovidDeaths
--WHERE location like '%states%'
--WHERE continent IS NOT NULL
ORDER BY 1,2


-- Countries with Highest Infection Rate compared to the Population

Select location, population, MAX(CONVERT(float, total_cases)) as HighestInfectionCount, MAX(total_cases/population)* 100 AS PercentPopulationInfected
FROM PortfolioProjects..CovidDeaths
--WHERE location like '%states%'
GROUP BY Location, population
ORDER BY PercentPopulationInfected DESC

-- Countries with the Highest Death Count per Population
	-- using CAST instead of CONVERT to change the datatype

Select location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM PortfolioProjects..CovidDeaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC


-- Breaking things down BY CONTINENT

-- Showing continents with the Highest Death Count per Population

Select continent, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM PortfolioProjects..CovidDeaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, (SUM(new_deaths)/SUM(new_cases))*100 as DeathPercentage
FROM PortfolioProjects..CovidDeaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL and new_cases is not NULL
--Group By date
ORDER BY 1, 2


-- Looking at Total Populations vs Vaccination
-- Percentage of Population that has had atleast one Covid Vaccine

	-- What is the total number of people that have been vaccinated
	-- do a rolling count of new vaccinations by location by using PARTITION BY caluse. 
	-- Partition by location because we want the count to start over everytime there is a new location

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT( BIGINT, vac.new_vaccinations)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated-- can also do CAST(vac.new_vaccinations as BIGINT)
FROM PortfolioProjects..CovidDeaths dea				-- join the two data tables to get population and vaccination data
JOIN PortfolioProjects..CovidVaccinations vac
	ON dea.location = vac.location					-- where these two columns match
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


--Using Commom Table Expression (CTE) to perform calculation on PARTITION BY in the previous query
	-- THE CTE PopvsVac calculates and stores info related to covid deaths and vaccinations
		-- CTE PopvsVac calculates the rolling sum of new vaccinations
			-- PARTITION BY calculates  calculates rolling sum based upon the partitions by location
		-- CTE PopvsVac performs a join to integrate the data from two tables. 
			-- CTE filters out rows where contient info is missing
	-- The main query then selects all the columns from the CTE and calulates percentage of rolling vaccinations wrt the population 

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT( BIGINT, vac.new_vaccinations))				-- can aslo do CAST(vac.new_vaccinations as BIGINT)
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated 
FROM PortfolioProjects..CovidDeaths dea
JOIN PortfolioProjects..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100  -- use the info stored in the CTE PopvsVac to calculate % of pop that recieved vaccinations over time
FROM PopvsVac


-- Using a Temp table to perform calculation on PARTITION BY

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated		-- create a temp table with columns and data types as specified
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated		-- populate the temp table with the resukts of the following query
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


-- Creating a VIEW to store data for later visualizations

USE PortfolioProjects		-- We want to create the view in the PortfolioProjects database

CREATE VIEW PercentPopulationVaccinated AS
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

-- DROP VIEW PercentPopulationVaccinated	-- incase we want to drop the view
