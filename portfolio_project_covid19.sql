Select *
From PortfolioProject..CovidDeaths$
Where continent is not NULL
Order by location, date;

Select *
From PortfolioProject..CovidVaccinations$
Where continent is not NULL
Order by 3, 4;

--  Select the data that we are going to use:

SElect location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths$
Where continent is not NULL
Order by 1, 2;

--   Looking at Total Cases vs Total Deaths:
--   Shows the likelihood of dying if you contract Covid in a country:

Select location, date, total_deaths, total_cases, round(total_deaths/total_cases, 4)*100 as DeathPercentage
From PortfolioProject..CovidDeaths$
Where location = 'Iran'
Order by 1, 2;

--   Looking at Total Cases vs Population:
--   Shows what percentage of population infected with Covid in a country:

Select location, date, population, total_cases, round(total_cases/population, 4)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths$
Where location = 'Iran'
Order by 1, 2;

--   Countries with Highest Infection Rate compared to Population: Cyprus has the highest infection rate in the world.

Select location, population, Max(total_cases) as HighestTotalCases, Max(round(total_cases/population, 4)*100) as HighestPercentPopulationInfected
From PortfolioProject..CovidDeaths$
Where continent is not NULL
Group by location, population
Order by 4 desc;

--   Countries with Highest Death Count:

Select location, population, Max(cast(total_deaths as int)) as TotalDeaths
From PortfolioProject..CovidDeaths$
Where continent is not NULL
Group by location, population
Order by 3 desc;

--   BREAKING THINGS DOWN BY CONTINENT:
--   Showing contintents with the highest death:

With  ContinentDeaths as (
	Select trim(continent) as continent, location, population, Max(cast(total_deaths as int)) as TotalDeaths
	From PortfolioProject..CovidDeaths$
	Where continent is not NULL
	Group by continent, location, population
	--Order by TotalDeaths desc
	)
Select continent, sum(population) as ContinentPopulation, sum(TotalDeaths) as ContinentTotalDeaths
From ContinentDeaths
Group by continent
Order by 3 desc;


--   GLOBAL NUMBERS:
--	 Per day:

Select date, SUM(new_cases) as Total_cases, SUM(CAST(new_deaths as int)) as Total_deaths, round(SUM(new_cases)/SUM(CAST(new_deaths as int)), 4)*100 as DeathPercentage
From PortfolioProject..CovidDeaths$
Group By date
Having SUM(CAST(new_deaths as int)) != 0
Order by date;

--   In total:

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
ROUND(SUM(cast(new_deaths as int))/SUM(New_Cases), 5)*100 as DeathPercentage
From PortfolioProject..CovidDeaths$
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2


--   Total Population vs New Vaccinations (vaccination doses administered):
--   Shows Percentage of vaccination doses administered to Population:

Select dth.continent, dth.location, dth.date, dth.population, vcc.new_vaccinations,
SUM(CONVERT(bigint, vcc.new_vaccinations )) OVER (Partition by dth.location Order by dth.location, dth.date) as RollingNewVaccinations
--, Round(RollingPeopleVaccinated / dth.population, 4)*100
From PortfolioProject..CovidDeaths$ dth
Join PortfolioProject..CovidVaccinations$ vcc
	On dth.location = vcc.location
	And dth.date = vcc.date
Where dth.continent is not null and dth.location = 'Iran'
Order by 2, 3

--   Using CTE to perform Calculation on Partition By in previous query:

With vaccinated as 
(
Select dth.continent, dth.location, dth.date, dth.population, vcc.new_vaccinations,
SUM(CAST(vcc.new_vaccinations as bigint)) OVER (Partition by dth.location Order by dth.location, dth.date) as RollingNewVaccinations
From PortfolioProject..CovidDeaths$ dth
Join PortfolioProject..CovidVaccinations$ vcc
	On dth.location = vcc.location
	And dth.date = vcc.date
Where dth.continent is not null 
-- Order by 2, 3
)
Select *, Round(RollingNewVaccinations / population, 4)*100 as PercentVaccinated
From vaccinated 
where location  like '%states'


--    Global vaccination doses administered
Select avg(population) as world_population, SUM(CAST(new_vaccinations as bigint)) as total_new_vaccinations,
ROUND(SUM(CAST(vcc.new_vaccinations as bigint))/avg(population), 5)*100 as NewVaccinationPercentage
From PortfolioProject..CovidDeaths$ dth
Join PortfolioProject..CovidVaccinations$ vcc
	On dth.location = vcc.location
	And dth.date = vcc.date
where dth.location = 'world' 




--    USING TEMP TABLE
--    Shows Percentage of patients in intensive care units (ICUs) and Percentage of patients in hospital:

Drop Table If Exists #Patients
Create Table #Patients
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
ICU_patients numeric,
Hosp_patients numeric,
RollingICUPatients numeric,
RollingHospPatients numeric
)

INSERT INTO #Patients
	select Continent, location, date, population, icu_patients, hosp_patients, sum(convert(int, icu_patients)) over (Partition by location Order By location, date) as RollingICUPatients,
	Sum(CAST(hosp_patients as int)) over (Partition by location Order by location, date) As RollingHospPatients
	from PortfolioProject.dbo.CovidDeaths$
	where location is not NULL

--    Patients rates for each location:

with Patients as (
Select *, 
CAST((RollingICUPatients / population)*100 as DECIMAL(4,2)) as PercentICUPatients, CAST((RollingHospPatients / population)*100 as DECIMAL(4, 2)) as PercentHospPatients
From #Patients
Where ICU_patients is not null 
and Hosp_patients is not null
--Where location = 'United States'
)
select distinct continent, location, max(PercentICUPatients) over (Partition by location) as ICUPatients_per_100,
max(PercentHospPatients) over (Partition by location) as HospPatients_per_100
from Patients
order by 3 desc