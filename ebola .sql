create table ebola_data(
indicator text,
Country text,
Date DATE,
Value Integer
);

-- Update Guinea 2 to Guinea
update ebola_data
set Country = 'Guinea'
where Country = 'Guinea 2';
-- Update Liberia 2 to Liberia
update ebola_data 
set Country = 'Liberia'
where Country = 'Liberia 2';

-- checking indicator column values
--select distinct indicator, count(*) from ebola_data
--group by indicator;

-- combining Guinea & previously Guinea 2 value, same with Liberia
create view combined_ebola_data as 
select indicator, country, date, sum(value) as combined_value
from ebola_data 
group by indicator, country, date;

select * from combined_ebola_data;
--select distinct indicator, count(*) from combined_ebola_data
--group by indicator
--order by indicator;

----------------------------------------------------------------------------------------------------------
-- Total # of confirmed, probable, and suspected cases and deaths per each country---------
create view total_cases_deaths as
SELECT country, 
       MAX(CASE WHEN indicator = 'Cumulative number of confirmed, probable and suspected Ebola cases' 
       THEN combined_value ELSE 0 END) AS total_cases,
       MAX(CASE WHEN indicator = 'Cumulative number of confirmed, probable and suspected Ebola deaths' 
       THEN combined_value ELSE 0 END) AS total_deaths
FROM combined_ebola_data
GROUP BY country; 

select * from total_cases_deaths;

-- # of confirmed, probable, and suspected cases and deaths extraction for Trends-----------------
-- Cases:
select country, date, combined_value as cases
into temp_cases
from combined_ebola_data 
where indicator = 'Cumulative number of confirmed, probable and suspected Ebola cases'
order by country, date;
-- Deaths:
select country, date, combined_value as deaths
into temp_deaths
from combined_ebola_data 
where indicator = 'Cumulative number of confirmed, probable and suspected Ebola deaths'
order by country, date;
-- combining two table
select c.country, c.date, c.cases, d.deaths
into temp_combined
from temp_cases c
join temp_deaths d 
on c.country = d.country and c.date = d.date
order by c.country, c.date;
-- Trends:

create view ebola_trend_cfr as
select country, date, cases, deaths,
CASE 
     WHEN cases > 0 THEN (deaths::float / cases::float) * 100
     ELSE 0 
  END AS Case_Fatality_Rate
from temp_combined
order by country, date;


select * from ebola_trend_cfr;

-- % of confirmed, probable, suspected out of the total cases --------------------
-- # of confirmed cases
select country, date, combined_value as confirmed_cases
into temp_confirmed_cases
from combined_ebola_data 
where indicator = 'Cumulative number of confirmed Ebola cases'
order by country, date;
-- # of probable cases
select country, date, combined_value as probable_cases
into temp_probable_cases
from combined_ebola_data 
where indicator = 'Cumulative number of probable Ebola cases'
order by country, date;
-- # of suspected cases
select country, date, combined_value as suspected_cases
into temp_suspected_cases
from combined_ebola_data 
where indicator = 'Cumulative number of suspected Ebola cases'
order by country, date;
-- Combining tables (confirmed, probable, suspected, and total cases)
select tcc.country, tcc.date, tcc.confirmed_cases, tpc.probable_cases, tsc.suspected_cases, tc.cases
into temp_cases_combined
from temp_confirmed_cases tcc
join temp_probable_cases tpc on tcc.country = tpc.country and tcc.date = tpc.date
join temp_suspected_cases tsc on tcc.country = tsc.country and tcc.date = tsc.date
join temp_cases tc on tcc.country = tc.country and tcc.date = tc.date 
order by tcc.country, tcc.date;


CREATE VIEW latest_date_country AS
SELECT country, MAX(date) AS latest_date
FROM temp_cases_combined
GROUP BY country;

create view cases_combined as
select tcc.country, tcc.confirmed_cases, tcc.probable_cases, tcc.suspected_cases, tcc.cases
from temp_cases_combined tcc
join latest_date_country ldc
	on tcc.country = ldc.country and tcc.date = ldc.latest_date;

select * from cases_combined;



CREATE VIEW percentage_cases AS
SELECT tcc.country,
       (confirmed_cases::float / cases::float) * 100 AS rate_confirmed,
       (probable_cases::float / cases::float) * 100 AS rate_probable,
       (suspected_cases::float / cases::float) * 100 AS rate_suspected
FROM temp_cases_combined tcc
JOIN latest_date_country ldc
  ON tcc.country = ldc.country AND tcc.date = ldc.latest_date;


 

 select country, max(date), min(date)
 from combined_ebola_data
group by country;
 
 

-- SELECT inet_server_addr(), inet_server_port();