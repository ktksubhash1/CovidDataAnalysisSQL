SELECT * 
FROM Portfolio..CovidDeaths 
WHERE continent is not null
ORDER BY 3,4

--SELECT * FROM Portfolio..CovidVaccinations ORDER BY 3,4


-- Select the data that we are going to be using
select location, date, total_cases, new_cases, total_deaths, population
from Portfolio..CovidDeaths
where continent is not null
order by 1,2


--Change data type of total_deaths from nvarchar(225) to float
alter table Portfolio..CovidDeaths
alter column total_deaths float


--Total Cases vs total deaths
--DeathPercentage shows how probable you are to die if you contract covid
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from Portfolio..CovidDeaths
where location='united states' and continent is not null
order by 1,2


--What percentage of popiulation got infected
select location, date, total_cases, population, (total_cases/population)*100 as PopulationInfected
from Portfolio..CovidDeaths
where location='united states' and continent is not null
order by 1,2


--Countries with highest infection rate compared to population
select location, population, max(total_cases) as HighestInfectionCount, max(total_cases/population)*100 as PercentagePopulationInfected
from Portfolio..CovidDeaths
where continent is not null
group by location, population
order by PercentagePopulationInfected desc, HighestInfectionCount desc


--Countries with highest death count per population
select location, max(total_deaths) as TotalDeathCount
from Portfolio..CovidDeaths
where continent is not null
group by location
order by TotalDeathCount desc


--Total death count by continent
select continent, max(total_deaths) as 'Total Death Count'
from Portfolio.dbo.CovidDeaths
where continent is not null
group by continent
order by [Total Death Count] desc


--Global numbers
--Total new cases by date
select date, SUM(new_cases) as NewCases
from Portfolio..CovidDeaths
where continent is not null
group by date
order by date


--World Death percentage by date
select date, SUM(new_cases) as TotalCases, SUM(new_deaths) as TotalDeaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
from Portfolio..CovidDeaths
where continent is not null
group by date
order by 1,2


--World overall total cases, total deaths and death percentage
select SUM(new_cases) as TotalCases, SUM(new_deaths) as TotalDeaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
from Portfolio..CovidDeaths
where continent is not null


--Rolloing totals of vaccination by continent, location, date
select d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(convert(float, v.new_vaccinations)) over (partition by d.location order by d.location, d.date) as RollingTotalVaccinations
from Portfolio..CovidDeaths d
join Portfolio..CovidVaccinations v
	on d.location = v.location and
	d.date = v.date
where d.continent is not null
order by 2,3;



--Using CTE
With popvsvac (continent, location, date, population, new_vaccinations, RollingTotalVaccinations)
as
(
select d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(convert(bigint, v.new_vaccinations)) over (partition by d.location order by d.location, d.date) as RollingTotalVaccinations
from Portfolio..CovidDeaths d
join Portfolio..CovidVaccinations v
	on d.location = v.location and
	d.date = v.date
where d.continent is not null
)
select *, (RollingTotalVaccinations/population)*100 as RollingVacPercentages
from popvsvac


--TEMP TABLE

drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingTotalvaccinations numeric,
)

insert into #PercentPopulationVaccinated
select d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(convert(bigint, v.new_vaccinations)) over (partition by d.location order by d.location, d.date) as RollingTotalVaccinations
from Portfolio..CovidDeaths d
join Portfolio..CovidVaccinations v
	on d.location = v.location and
	d.date = v.date
where d.continent is not null
order by 2,3

select *, (RollingTotalVaccinations/Population)*100 as RollingPercentage
from #PercentPopulationVaccinated


--Creating views to store data for visualizations
create view PercentagePopulationVaccinated
as
select d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(convert(bigint, v.new_vaccinations)) over (partition by d.location order by d.location, d.date) as RollingTotalVaccinations
from Portfolio..CovidDeaths d
join Portfolio..CovidVaccinations v
	on d.location = v.location and
	d.date = v.date
where d.continent is not null
--order by 2,3

select *
from PercentagePopulationVaccinated