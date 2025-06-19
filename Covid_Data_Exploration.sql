Create table "Covid_Death"
(iso_code varchar(10),	continent varchar(50) ,	location varchar(50),	date date,	population int,
	total_cases	int, new_cases int,	new_cases_smoothed	numeric, total_deaths int,	new_deaths int,
	new_deaths_smoothed	numeric, total_cases_per_million numeric,	new_cases_per_million numeric,
	new_cases_smoothed_per_million numeric,	total_deaths_per_million numeric,	new_deaths_per_million numeric,
	new_deaths_smoothed_per_million numeric,	reproduction_rate numeric,	icu_patients int,	icu_patients_per_million numeric,
	hosp_patients int,	hosp_patients_per_million numeric,	weekly_icu_admissions numeric,
	weekly_icu_admissions_per_million	numeric, weekly_hosp_admissions numeric,	
	weekly_hosp_admissions_per_million numeric
);
select * from "Covid_Death";

alter table "Covid_Death"
	alter column population type Bigint;
alter table "Covid_Death"
	alter column total_deaths type numeric;
alter table "Covid_Death"
	alter column total_cases type numeric;

Copy "Covid_Death"
from 'C:\Users\keert\OneDrive\Desktop\Learnings from Bhargavi\SQL PORTFOLIO PROJECT\CovidDeaths.csv'
Delimiter ',' Csv Header;

select * from "Covid_Death";

Select location, date, total_cases, new_cases, total_deaths, population
from "Covid_Death" 
	where continent is not null;

---Death Percentage countrywise--
Select location, date, total_cases, total_deaths, cast ((total_deaths/total_cases)*100 as numeric (10,2)) as Death_Percentage, population
from "Covid_Death"
 where continent is not null;

Select location, date, total_cases, total_deaths, round((total_deaths/total_cases)*100,2) as Death_Percentage, population
from "Covid_Death"
	where continent is not null
order by 1,2 desc;

--Total Cases vs population--
Select location, date, total_cases, population, round((total_cases/population)*100,5) as Total_Cases_Percentage
from "Covid_Death";

---Country with highest infection rate--

select * from "Covid_Death";

select location, population, max(total_cases) as Total_Cases, round(max((total_cases/population)*100),2) as Percent_Population_Infected
	from "Covid_Death"
	where (total_cases/population)*100 is not null and continent is not null
	group by location, population
	order by Percent_Population_Infected desc;

--showing countries with highest death count per population

select location, population, max(total_deaths) as Highest_Deaths, round(max((total_deaths/population)*100),3) as Population_Death_Percent
	from "Covid_Death"
	where (total_deaths/population)*100 is not null and continent is not null
	group by location, population
	order by Population_Death_Percent desc;

----showing continets with the highest death count per population--

select continent, max(total_deaths) as Highest_Deaths, round(max((total_deaths/population)*100),3) as Population_Death_Percent
	from "Covid_Death"
	where (total_deaths/population)*100 is not null and continent is not null
	group by continent
	order by Population_Death_Percent desc;

select continent, max(total_deaths) as Highest_Deaths
	from "Covid_Death"
	where total_deaths is not null and continent is not null
	group by continent;

---global numbers--
select date, max(total_deaths) as Highest_Deaths
	from "Covid_Death"
	where total_deaths is not null and continent is not null
	group by date
	order by Highest_Deaths desc;

select date, sum(new_cases) as Total_New_Cases, sum(cast(new_deaths as numeric)) as Total_New_Deaths, 
	round(sum(cast(new_deaths as numeric))/sum(new_cases)*100,2) as Death_Percentage
	from "Covid_Death"
	where new_cases is not null and continent is not null
	group by date
	order by Death_Percentage desc;


--join 2 tables--

select * from "Covid_Death" cd
join "Covid_Vaccination" cv
on cd.date= cv.date and cd.location= cv.location;

----Total population vs Total vaccinations---

select cd.continent,cd.location,  max(population) as Total_Population, max(total_vaccinations) as Total_Vaccinations
	from "Covid_Death" cd
join "Covid_Vaccination" cv
on cd.date= cv.date and cd.location= cv.location
	where cd.location is not null and cd.continent is not null and Total_Vaccinations is not null
	group by cd.location, cd.continent
	order by Total_Vaccinations desc;

---Total population vs per day vaccinations---
select cd.continent,cd.location, cd.date,  population, new_vaccinations
	from "Covid_Death" cd
join "Covid_Vaccination" cv
on cd.date= cv.date and cd.location= cv.location
	where cd.location is not null and cd.continent is not null and new_vaccinations is not null
	order by new_vaccinations desc;

---Total population vs new_vaccinations percentage on daily basis---
select cd.continent,cd.location, cd.date,  population, new_vaccinations, 
	(sum(new_vaccinations)/population)*100 as New_Vaccinations_Percent
	from "Covid_Death" cd
join "Covid_Vaccination" cv
on cd.date= cv.date and cd.location= cv.location
	where cd.location is not null and cd.continent is not null and new_vaccinations is not null
	group by cd.continent, cd.location,cd.date, population, new_vaccinations
	order by new_vaccinations desc;

---Total population vs rolled_new_vaccinations percentage on daily basis---

select cd.continent,cd.location, cd.date,  population, new_vaccinations, 
	(sum(new_vaccinations) over (partition by cd.location order by cd.location, cd.date)) as rolled_new_vaccinations, 
	round(((sum(new_vaccinations) over (partition by cd.location order by cd.location, cd.date))/population)*100,3) as rolled_new_vaccinations_percent
	from "Covid_Death" cd
join "Covid_Vaccination" cv
on cd.date= cv.date and cd.location= cv.location
	where cd.location is not null and cd.continent is not null and new_vaccinations is not null 
	group by cd.continent, cd.location,cd.date, population, new_vaccinations
	order by rolled_new_vaccinations_percent desc;

--alternate using CTE--

With popvsvac (continent,location, date,  population, new_vaccinations, rolled_new_vaccinations)
	as
	(
select cd.continent,cd.location, cd.date,  population, new_vaccinations, 
	(sum(new_vaccinations) over (partition by cd.location order by cd.location, cd.date)) 
	as rolled_new_vaccinations--- cumulative
	from "Covid_Death" cd
join "Covid_Vaccination" cv
on cd.date= cv.date and cd.location= cv.location
	where cd.location is not null and cd.continent is not null and new_vaccinations is not null 
	group by cd.continent, cd.location,cd.date, population, new_vaccinations
	order by rolled_new_vaccinations desc
)
select continent,location, date,  population, new_vaccinations,
	round((rolled_new_vaccinations/population)*100,2) as rolled_new_vaccination_percent
from popvsvac;

-----Temp table---

Create temp table popvsvac (
	continent varchar(255) ,location varchar(255), date date,  population numeric, 
	new_vaccinations numeric, rolled_new_vaccinations numeric);
	
insert into popvsvac
select cd.continent,cd.location, cd.date,  population, new_vaccinations, 
	(sum(new_vaccinations) over (partition by cd.location order by cd.location, cd.date)) 
	as rolled_new_vaccinations--- cumulative
	from "Covid_Death" cd
join "Covid_Vaccination" cv
on cd.date= cv.date and cd.location= cv.location
	where cd.location is not null and cd.continent is not null and new_vaccinations is not null 
	group by cd.continent, cd.location,cd.date, population, new_vaccinations
	order by rolled_new_vaccinations desc;

select continent,location, date,  population, new_vaccinations,
	round((rolled_new_vaccinations/population)*100,2) as rolled_new_vaccination_percent
from popvsvac;


----View to store data for future---

Create view popvsvac_view as
	select cd.continent,cd.location, cd.date,  population, new_vaccinations, 
	(sum(new_vaccinations) over (partition by cd.location order by cd.location, cd.date)) 
	as rolled_new_vaccinations--- cumulative
	from "Covid_Death" cd
join "Covid_Vaccination" cv
on cd.date= cv.date and cd.location= cv.location
	where cd.location is not null and cd.continent is not null and new_vaccinations is not null 
	group by cd.continent, cd.location,cd.date, population, new_vaccinations
	order by rolled_new_vaccinations desc;

select continent,location, date,  population, new_vaccinations,
	round((rolled_new_vaccinations/population)*100,2) as rolled_new_vaccination_percent
from popvsvac_view;


