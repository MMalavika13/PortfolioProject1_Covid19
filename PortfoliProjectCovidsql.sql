
-- Data from our world in data - Covid 19 data till Feb
-- Data is split into two tables -CovidDeath and CovidVaccination
-- We'll be using the two tables CovidDeath and CovidVaccination from the database PortfolioProject for the analysis

-- To see the entire table
select * from PortfolioProject..CovidDeath;

-- Similarly for Table 2
select * from PortfolioProject..CovidVaccination;


-- To select data particular to the first set of analysis
select location, date,total_cases,total_deaths 
from PortfolioProject..CovidDeath;

-- To find Total cases vs Total deaths by location
select location,date,total_cases,total_deaths,
(cast(total_deaths as float)/cast(total_cases as float))*100 
as DeathPercentage
from PortfolioProject..CovidDeath
order by 1,2;

-- To find Total cases vs Total deaths specific to India
select location,date,total_cases,total_deaths,
(cast(total_deaths as float)/cast(total_cases as float))*100 
as DeathPercentage
from PortfolioProject..CovidDeath
where location = 'India'
order by 1,2;

-- To find New cases vs New deaths - since there are many zero values, we'll use exception handling to prevent the program from crashing
Begin Try
select location,date,new_cases,new_deaths,
(cast(new_deaths as float)/cast(new_cases as float))*100 
as NewDeathPercentage
from PortfolioProject..CovidDeath;
End Try
Begin Catch
print 'Divide by Zero Error'
End Catch;

-- To find New cases vs New deaths: to rectify the error and proceed with the program

Update PortfolioProject..CovidDeath
set new_cases = null where new_cases = 0;


-- Trying the code again
select location,date,new_cases,new_deaths,
(cast(new_deaths as float)/cast(new_cases as float))*100 
as NewDeathPercentage
from PortfolioProject..CovidDeath;

-- To find New cases vs New cases for India
select location,date,new_cases,new_deaths,
(cast(new_deaths as float)/cast(new_cases as float))*100 
as NewDeathPercentage
from PortfolioProject..CovidDeath
where location = 'India';

-- Looking at countries with highest death rate compared to number of cases
select location,total_cases,max(total_deaths) as HighestDeath,
max((cast(total_deaths as float)/cast(total_cases as float))*100) 
as DeathRate
from PortfolioProject..CovidDeath
Group by location,total_cases
order by DeathRate desc;

-- Showing countries with maximum death counts
select location, max(total_deaths) as HighestDeathCount
from PortfolioProject..CovidDeath
Group by location
order by HighestDeathCount desc;

-- Showing continents with maximum death counts
select continent, max(total_deaths) as HighestDeathCount
from PortfolioProject..CovidDeath
where continent is not null
Group by continent
order by HighestDeathCount desc;

-- GLOBAL NUMBERS

-- To find Total cases vs Total deaths globally on a given date
 
select date,cast(sum(new_cases) as float) as Total_cases, cast(sum(new_deaths) as float)as Total_deaths,
(cast(sum(new_deaths) as float))/cast(sum(new_cases) as float)*100 as DeathPercentageGlobal
from PortfolioProject..CovidDeath
where continent is not null
Group by date
Order by 1,2;

-- To find the sum of new cases globally on a daily basis
select date, sum(new_cases)as Total_cases
from PortfolioProject..CovidDeath
where continent is not null
Group by date
order by 1,2;

-- To find Total cases vs Total deaths in the world till date
 
select cast(sum(new_cases) as float) as Total_cases, cast(sum(new_deaths) as float)as Total_deaths,
(cast(sum(new_deaths) as float))/cast(sum(new_cases) as float)*100 as DeathPercentageGlobal
from PortfolioProject..CovidDeath
where continent is not null
Order by 1,2;

-- Analysis using both tables - CovidDeath and CovidVaccination

-- To join both the tables

select * from PortfolioProject..CovidDeath dea
join PortfolioProject..CovidVaccination vac
	on dea.location = vac.location
	and dea.date = vac.date;

-- Total Cases vs Total Population

select dea.date, dea.continent,dea.location,dea.total_cases,vac.population, 
(cast(dea.total_cases as float)/cast(vac.population as float))*100 
as TotalPopulationInfected
from PortfolioProject..CovidDeath dea
join PortfolioProject..CovidVaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
	order by 1,2,3;


-- Cumulative New Cases vs Total Population

select dea.date, dea.continent,dea.location,vac.population,dea.new_cases,
sum(convert(float,dea.new_cases)) OVER (partition by dea.location Order by dea.location, dea.date) as Cumulative_cases
from PortfolioProject..CovidDeath dea
join PortfolioProject..CovidVaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
	order by 1,3;


-- Using CTE Total Cases (cumulative) vs Total Population

With PopVsVac (date, continent, location, population, new_Cases, Cumulative_cases)
as
(
select dea.date, dea.continent,dea.location,vac.population,dea.new_cases,
sum(convert(float,dea.new_cases)) OVER (partition by dea.location Order by dea.location, dea.date) as Cumulative_cases
from PortfolioProject..CovidDeath dea
join PortfolioProject..CovidVaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
	
	)
select * from
PopVsVac;

-- Using CTE to find the percentage of population affected by covid

With PopVsVac (date, continent, location, population, new_Cases, Cumulative_cases)
as
(
select dea.date, dea.continent,dea.location,vac.population,dea.new_cases,
sum(convert(float,dea.new_cases)) OVER (partition by dea.location Order by dea.location, dea.date) as Cumulative_cases
from PortfolioProject..CovidDeath dea
join PortfolioProject..CovidVaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null
	
	)
select *, (Cumulative_cases/population)*100 as Infection_rate from
PopVsVac;

-- Temp Table

Drop table if exists #PercentPopulationInfected
-- Drop table added for ease of editing the code at a later point
create table #PercentPopulationInfected
(
date datetime,
continent nvarchar(255),
location nvarchar(255),
population numeric,
new_cases numeric,
cumulative_cases numeric
);

Insert into #PercentPopulationInfected
select dea.date, dea.continent,dea.location,vac.population,dea.new_cases,
sum(convert(float,dea.new_cases)) OVER (partition by dea.location Order by dea.location, dea.date) as Cumulative_cases
from PortfolioProject..CovidDeath dea
join PortfolioProject..CovidVaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null

select *, (Cumulative_cases/population)*100 as Infection_rate from
#PercentPopulationInfected;


-- CREATING VIEWS

-- view for Cumulative cases

create view Cumulative_cases as
select dea.date, dea.continent,dea.location,vac.population,dea.new_cases,
sum(convert(float,dea.new_cases)) OVER (partition by dea.location Order by dea.location, dea.date) as Cumulative_cases
from PortfolioProject..CovidDeath dea
join PortfolioProject..CovidVaccination vac
	on dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null;

select * from Cumulative_cases;

-- View for Global Death Percentage

create view global_death_percentage as
select cast(sum(new_cases) as float) as Total_cases, cast(sum(new_deaths) as float)as Total_deaths,
(cast(sum(new_deaths) as float))/cast(sum(new_cases) as float)*100 as DeathPercentageGlobal
from PortfolioProject..CovidDeath
where continent is not null;

select * from global_death_percentage;
