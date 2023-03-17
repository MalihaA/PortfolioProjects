select *
from PortfolioProject..CovidDeaths
where continent is not null
order by location, date
--order by 3, 4

--Select *
--from [PortfolioProject].[dbo].[CovidVaccinations]
--where continent is not null
--order by 3, 4

-- Select Data that we are going to be using
select location, date, total_cases, new_cases, total_deaths, population 
from PortfolioProject..CovidDeaths
where continent is not null
order by location, date
--order by 1, 2

-- Looking at Total Cases vs Total Deaths
-- Looking for likelihood of dying if you contract Covid in your country i.e. percentage of people who get infected and die

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where location like '%states%'
	and continent is not null
order by 1, 2


-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid.

select location, date, population, total_cases, (total_cases / population)*100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths
--where location like '%states%'
where continent is not null
order by 1, 2

-- Looking at  Countries with Highest Infection Rate compared to Population

select location, population, max(total_cases) as HighestInfectionCount, (max(total_cases / population))*100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths
--where location like '%states%'
where continent is not null
group by location, population
order by PercentPopulationInfected desc

-- Showing Countries with Highest Death Count per Population

select location, max(cast (total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
--where location like '%states%'
where continent is not null
group by location
order by TotalDeathCount desc

-- LETS BREAK THINGS DOWN BY CONTINENT

-- Showing the continents with the highest death count per population

select continent, max(cast (total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
--where location like '%states%'
where continent is not null
group by continent
order by TotalDeathCount desc

--select location, max(cast (total_deaths as int)) as TotalDeathCount
--from PortfolioProject..CovidDeaths
----where location like '%states%'
--where continent is null
--group by location
--order by TotalDeathCount desc

--select location, max(cast (total_deaths as int)) as TotalDeathCount
--from PortfolioProject..CovidDeaths
--where location like '%states%'
--group by location

-- GLOBAL NUMBERS

--daily

--select date, sum(new_cases) as toal_cases, sum(cast(new_deaths as int)) as total_deaths,  sum(cast (new_deaths as int))/sum(new_cases)*100 as DeathPercentage
--from PortfolioProject..CovidDeaths
----where location like '%states%'
--where continent is not null
--group by date
--order by 1, 2

--total to date

select sum(new_cases) as toal_cases, sum(cast(new_deaths as int)) as total_deaths,  sum(cast (new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
--where location like '%states%'
where continent is not null
--group by date
order by 1, 2


-- Looking at Total Population vs Vaccinations
--Shiws Percentage of Population that has recieved at least one Covid Vaccine

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) over (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
--sum(cast (vac.new_vaccinations as int)) over (partition by  dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
order by 2,3

-- Use CTE  to Perform Calculation on Partition By in previous query

with PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--sum(cast (vac.new_vaccinations as int)) over (partition by  dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *, (RollingPeopleVaccinated /Population )*100 as PercentPopulationVaccinated
from PopvsVac
--order by 2,3

--TEMP TABLE

Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric,
)

Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--sum(cast (vac.new_vaccinations as int)) over (partition by  dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

--Creating viewto store data for later visualizations

Create View PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--sum(cast (vac.new_vaccinations as int)) over (partition by  dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

Select *
from PercentPopulationVaccinated
