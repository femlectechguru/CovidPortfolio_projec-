

select * 
from [dbo].['owid-covid-data$']
where continent is not null
order by 3,4

-- looking at total cases vs Total deaths 

select location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 as DeathPopulation
from [dbo].['owid-covid-data$']
order by 1,2

select location, date, total_cases, total_deaths,
CASE
when isnumeric(total_deaths) =1 AND isnumeric(total_cases) !=0
then (convert(decimal,total_deaths) /NULLIF(convert(decimal,total_cases),0)) * 100
ELSE NULL 
END as DeathPercentage
from [dbo].['owid-covid-data$']
order by 1,2

select location, date, total_cases, total_deaths
from [dbo].['owid-covid-data$']
order by 1,2


-- looking at total cases vs Total deaths using Deathpercentage 
-- shows likelihood of dying if you contract covid in your country

select location, date, total_cases, total_deaths,
CASE
when isnumeric(total_deaths) =1 AND isnumeric(total_cases) !=0
then (convert(decimal,total_deaths) /NULLIF(convert(decimal,total_cases),0)) * 100
ELSE NULL 
END as DeathPercentage
from [dbo].['owid-covid-data$']
WHERE location like 'Africa'
order by 1,2

-- looking at the total_cases vs population
-- shows percentage of people that got covid


select location, date, population,total_cases, 
CASE
when isnumeric(total_deaths) =1 AND isnumeric(total_cases) !=0
then (convert(decimal,total_cases) /NULLIF(convert(decimal,population),0)) * 100
ELSE NULL 
END as DeathPercentage
from [dbo].['owid-covid-data$']
WHERE location like 'Africa'
order by 1,2

-- looking at countries with highest infection rate 

select location, population,MAX(total_cases) AS HighestinfectedCount, MAX((total_cases/population)) * 100 as percentPopulationInfected
from [dbo].['owid-covid-data$']
Group by location,population
order by 1,2

select location, population,MAX(total_cases) AS HighestinfectedCount, MAX((total_cases/population)) * 100 as percentPopulationInfected
from [dbo].['owid-covid-data$']
Group by location,population
order by percentPopulationInfected desc

-- showing countries with highest Death count per population

select location, MAX(cast(Total_deaths as int )) AS TotalDeathCount
from [dbo].['owid-covid-data$']
where continent is not null
Group by location
order by TotalDeathCount desc

--LET'S BREAK THINGS DOWN BY CONTINENT

select continent, MAX(cast(Total_deaths as int )) AS TotalDeathCount
from [dbo].['owid-covid-data$']
where continent is not null
Group by continent
order by TotalDeathCount desc


--showing the continent with the highest death count per population
select continent, MAX(cast(Total_deaths as int )) AS TotalDeathCount
from [dbo].['owid-covid-data$']
where continent is not null
Group by continent
order by TotalDeathCount desc


select date,SUM(new_cases) AS total_cases,SUM(cast(new_deaths as int)) as total_deaths,

SUM(cast(new_deaths as int))/SUM(new_cases) * 100 as DeathPercentage

from [dbo].['owid-covid-data$']

where continent is null
Group by date
order by 1,2

select date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths

from [dbo].['owid-covid-data$']

select  date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths,
CASE
when isnumeric(sum(cast(new_deaths as int))) =1 AND isnumeric(sum(new_cases)) =1
then (convert(decimal,sum(cast(new_deaths as int))) /NULLIF(convert(decimal,sum(new_cases)),0)) * 100
ELSE NULL 
END as DeathPercentage
from [dbo].['owid-covid-data$']
where continent is null
--group by date
order by 1,2

-- this gives you all total world cases and deaths
--GLOBAL NUMBERS
select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths,
CASE
when isnumeric(sum(cast(new_deaths as int))) =1 AND isnumeric(sum(new_cases)) =1
then (convert(decimal,sum(cast(new_deaths as int))) /NULLIF(convert(decimal,sum(new_cases)),0)) * 100
ELSE NULL 
END as DeathPercentage
from [dbo].['owid-covid-data$']
where continent is null
--group by date
order by 1,2






--Looking at the total population vs vaccinations
--this partition the new_vaccination , it checks the date and location and sum them together for the whole location with the date the location is vaccinated

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(cast(vac.new_vaccinations as int)) OVER (partition by dea.location order by  dea.location, dea.date) as RollingPeopleVaccinated
from [dbo].['owid-covid-data$'] dea
join [dbo].[covid_Vaccinations$] vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not  null
order by 2,3

--USING CTE
-- if the number of column is different from your cte it will give error

with PopsVac ( continent, location, date , population, new_vaccinations, RollingPeopleVaccinated)
as 
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(cast(vac.new_vaccinations as int)) OVER (partition by dea.location order by  dea.location, dea.date)
as RollingPeopleVaccinated
--, (RollingPeoplevaccinated/population)*100
from [dbo].['owid-covid-data$'] dea
join [dbo].[covid_Vaccinations$] vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not  null
--order by 2,3
)
select * , (RollingPeoplevaccinated/population)*100 as percentagePopulationvaccinated
from PopsVac

--TEMP TABLE
create table #PercentagePeopleVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeoplevaccinated numeric
)


insert into #PercentagePeopleVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(cast(vac.new_vaccinations as int)) OVER (partition by dea.location order by  dea.location, dea.date) as RollingPeopleVaccinated
from [dbo].['owid-covid-data$'] dea
join [dbo].[covid_Vaccinations$] vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not  null
order by 2,3

select * , (RollingPeoplevaccinated/population)*100 as percentagePopulationvaccinated
from #PercentagePeopleVaccinated


--USING DROP TABLES IF IT EXISTS
DROP TABLE IF  EXISTS #PercentagePeopleVaccinated
create table #PercentagePeopleVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeoplevaccinated numeric
)


insert into #PercentagePeopleVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(cast(vac.new_vaccinations as int)) OVER (partition by dea.location order by  dea.location, dea.date) as RollingPeopleVaccinated
from [dbo].['owid-covid-data$'] dea
join [dbo].[covid_Vaccinations$] vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not  null
order by 2,3

select * , (RollingPeoplevaccinated/population)*100 as percentagePopulationvaccinated
from #PercentagePeopleVaccinated


-- CREATING VIEW TO STORE DATA FOR VISUALIZATION

Create view PercentagePeopleVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(cast(vac.new_vaccinations as int)) OVER (partition by dea.location order by  dea.location, dea.date) as RollingPeopleVaccinated
from [dbo].['owid-covid-data$'] dea
join [dbo].[covid_Vaccinations$] vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not  null
--order by 2,3

select * 
from PercentagePeopleVaccinated

create view DeathPercentage as
select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths,
CASE
when isnumeric(sum(cast(new_deaths as int))) =1 AND isnumeric(sum(new_cases)) =1
then (convert(decimal,sum(cast(new_deaths as int))) /NULLIF(convert(decimal,sum(new_cases)),0)) * 100
ELSE NULL 
END as DeathPercentage
from [dbo].['owid-covid-data$']
where continent is null
--group by date
--order by 1,2

select * 
from DeathPercentage