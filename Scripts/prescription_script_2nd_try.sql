SELECT *
FROM cbsa;

SELECT *
FROM drug;

SELECT *
FROM fips_county;

SELECT *
FROM overdose_deaths;

SELECT *
FROM population;

SELECT *
FROM prescriber;

SELECT *
FROM prescription;

SELECT *
FROM zip_fips;

-- 1. MVP
    -- a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT npi,
	   SUM(total_claim_count) AS sum_total
FROM prescription
GROUP BY npi
ORDER BY sum_total DESC
-- ANSWER: NPI 1881634483, 99707 claims


    -- b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT nppes_provider_first_name,
	   nppes_provider_last_org_name,
	   specialty_description,
	   SUM(total_claim_count) AS total_num_claims
FROM prescription
INNER JOIN prescriber
USING(npi)
GROUP BY nppes_provider_first_name,
	   	 nppes_provider_last_org_name,
	     specialty_description
ORDER BY total_num_claims DESC;



-- 2. MVP
    -- a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT specialty_description,
	   SUM(total_claim_count)
FROM prescriber
INNER JOIN prescription
USING(npi)
GROUP BY specialty_description
ORDER BY SUM(total_claim_count) DESC;


-- ANSWER: Family Practice
    
	-- b. Which specialty had the most total number of claims for opioids?

SELECT specialty_description,
	   SUM(total_claim_count)
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING(drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY SUM(total_claim_count) DESC



-- ANSWER: Nurse Practitioner 
   
   
   -- c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

   SELECT specialty_description
   FROM prescriber

   EXCEPT 

   SELECT specialty_description
   FROM prescription
   INNER JOIN prescriber
   USING(npi)





   -- d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

-- WITH total_percent_of_claims AS
-- 	(SELECT pbr.specialty_description, SUM(rx.total_claim_count) AS total_percent
-- 	FROM prescriber AS pbr
-- 		INNER JOIN prescription AS rx
-- 			USING(npi)
-- 		INNER JOIN drug AS d
-- 			USING(drug_name)
-- 	WHERE opioid_drug_flag = 'Y'
-- 	GROUP BY specialty_description)
-- SELECT pbr.specialty_description, ROUND((total_percent / SUM(total_claim_count)*100)) AS percentage
-- FROM prescription
-- 	INNER JOIN prescriber AS pbr
-- 		USING(npi)
-- 	INNER JOIN total_percent_of_claims
-- 		USING(specialty_description)
-- GROUP BY pbr.specialty_description, total_percent
-- ORDER BY percentage DESC;


   






-- 	3. MVP
--     a. Which drug (generic_name) had the highest total drug cost?

SELECT generic_name,
	   SUM(total_drug_cost)
FROM prescription
INNER JOIN drug
USING(drug_name)
GROUP BY generic_name
ORDER BY SUM(total_drug_cost) DESC


-- ANSWER: Insulin Glargine

--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT generic_name,
	   ROUND((total_drug_cost/total_day_supply), 2) AS cost_per_day
FROM prescription
INNER JOIN drug
USING(drug_name)
GROUP BY generic_name, cost_per_day
ORDER BY generic_name DESC



-- 4. MVP
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/

SELECT drug_name,
	   CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	   		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			ELSE 'neither' END AS drug_type
FROM drug





--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.


SELECT
	   CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	   		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			ELSE 'neither' END AS drug_type,
	   SUM(total_drug_cost)
FROM drug
INNER JOIN prescription
USING(drug_name)
GROUP BY drug_type


-- ANSWER: More was spent on opioids


-- 5. MVP
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT DISTINCT cbsa
FROM cbsa
WHERE cbsaname ILIKE '%TN%'

-- ANSWER: 11





--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.


SELECT cbsaname,
	SUM(population) AS sum
	FROM cbsa
	INNER JOIN population
	USING(fipscounty)
	GROUP BY cbsaname
	ORDER BY sum DESC;

-- ANSWER: CBSA 34980, Nashville-davidson total_population 1,830,410
		-- CBSA Morristown, TN	 34100, total_population 116,352




--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.


WITH non_cbsa_county AS (SELECT fipscounty
						FROM fips_county
						INNER JOIN population
						USING(fipscounty)
						EXCEPT
						SELECT fipscounty
						FROM cbsa)

SELECT county, population
FROM non_cbsa_county
INNER JOIN population
USING(fipscounty)
INNER JOIN
fips_county
USING(fipscounty)
ORDER BY population DESC


-- ANSWER: SEVIER
		



-- 6. MVP
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
INNER JOIN drug
USING (drug_name)
WHERE total_claim_count > 3000


-- ANSWER: Run Query

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT drug_name, 
		total_claim_count, 
		CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			 WHEN opioid_drug_flag = 'N' THEN 'not opioid'
			 END AS drug_type
FROM prescription
INNER JOIN drug
USING (drug_name)
WHERE total_claim_count > 3000



--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT  nppes_provider_first_name,
		nppes_provider_last_org_name,
	    drug_name, 
		total_claim_count, 
		CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			 WHEN opioid_drug_flag = 'N' THEN 'not opioid'
			 END AS drug_type
FROM prescription
INNER JOIN drug
USING (drug_name)
INNER JOIN prescriber
USING(npi)
WHERE total_claim_count > 3000


-- 7. MVP The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.


--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT npi,
	   drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
	  AND nppes_provider_city = 'NASHVILLE'
	  AND opioid_drug_flag = 'Y'






--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT p1.npi,
	   d.drug_name,
	   SUM(total_claim_count)
FROM prescriber AS p1
CROSS JOIN drug AS d
LEFT JOIN prescription AS p2
USING(drug_name)
WHERE specialty_description = 'Pain Management'
AND nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y'
GROUP BY p1.npi, d.drug_name
ORDER BY sum DESC

						



--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.


SELECT p1.npi,
	   d.drug_name,
	   SUM(total_claim_count) AS sum_claim_count,
	   COALESCE(SUM(total_claim_count),'0')
FROM prescriber AS p1
CROSS JOIN drug AS d
LEFT JOIN prescription AS p2
USING(drug_name)
WHERE specialty_description = 'Pain Management'
AND nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y'
GROUP BY p1.npi, d.drug_name
ORDER BY sum_claim_count DESC NULLS LAST































-- BONUS

-- 1. How many npi numbers appear in the prescriber table but not in the prescription table?

SELECT npi
FROM prescriber
EXCEPT
SELECT npi
FROM prescription





-- 2.
--     a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT generic_name,
	   SUM(total_claim_count)
FROM prescriber
INNER JOIN prescription USING(npi)
INNER JOIN drug USING(drug_name)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY sum DESC
LIMIT 5


--     b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT generic_name,
	   SUM(total_claim_count)
FROM prescriber
INNER JOIN prescription USING(npi)
INNER JOIN drug USING(drug_name)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY sum DESC
LIMIT 5


--     c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.

SELECT generic_name,
	   SUM(total_claim_count)
FROM prescriber
INNER JOIN prescription USING(npi)
INNER JOIN drug USING(drug_name)
WHERE specialty_description IN ('Cardiology', 'Family Practice')
GROUP BY generic_name
ORDER BY sum DESC
LIMIT 5

-- 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
--     a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
    
SELECT npi,
	   SUM(total_claim_count) AS total_num_of_claim,
	   nppes_provider_city
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY SUM(total_claim_count) DESC
LIMIT 5;





--    b. Now, report the same for Memphis.

SELECT npi,
	   SUM(total_claim_count) AS total_num_of_claim,
	   nppes_provider_city
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY npi, nppes_provider_city
ORDER BY SUM(total_claim_count) DESC
LIMIT 5;
    


--     c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

(SELECT npi,
	   SUM(total_claim_count) AS total_num_of_claim,
	   nppes_provider_city
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY SUM(total_claim_count) DESC
LIMIT 5)
UNION
(SELECT npi,
	   SUM(total_claim_count) AS total_num_of_claim,
	   nppes_provider_city
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY npi, nppes_provider_city
ORDER BY SUM(total_claim_count) DESC
LIMIT 5)
UNION
(SELECT npi,
	   SUM(total_claim_count) AS total_num_of_claim,
	   nppes_provider_city
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE nppes_provider_city = 'KNOXVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY SUM(total_claim_count) DESC
LIMIT 5)
UNION
(SELECT npi,
	   SUM(total_claim_count) AS total_num_of_claim,
	   nppes_provider_city
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE nppes_provider_city = 'CHATTANOOGA'
GROUP BY npi, nppes_provider_city
ORDER BY SUM(total_claim_count) DESC
LIMIT 5)
ORDER BY nppes_provider_city


	

-- 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.


WITH avg_table AS (SELECT  DISTINCT county,
						    SUM(overdose_deaths) OVER(PARTITION BY county) AS count_county,
	 					   AVG(overdose_deaths) OVER(PARTITION BY county) AS avg_county,
	                       AVG(overdose_deaths) OVER() AS avg_total
					FROM overdose_deaths
					INNER JOIN fips_county
					ON overdose_deaths.fipscounty = CAST(fips_county.fipscounty AS numeric)
					ORDER BY avg_county DESC)

SELECT county,
	   count_county,
	   avg_total
FROM avg_table
WHERE avg_county > avg_total;
	





SELECT AVG(overdose_deaths)
FROM overdose_deaths
					INNER JOIN fips_county
					ON overdose_deaths.fipscounty = CAST(fips_county.fipscounty AS numeric)

-- 5.

--     a. Write a query that finds the total population of Tennessee.

SELECT SUM(population)
FROM population
INNER JOIN fips_county
USING(fipscounty);




    
--     b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.






SELECT county,
		population,
		(SELECT SUM(population) FROM population INNER JOIN fips_county USING(fipscounty)),
		ROUND(population/(SELECT SUM(population) FROM population INNER JOIN fips_county USING(fipscounty))*100,2)
FROM population
INNER JOIN fips_county
USING(fipscounty)



















-- GROUPING SETS





-- 1. Write a query which returns the total number of claims for these two groups. Your output should look like this: 

-- specialty_description         |total_claims|
-- ------------------------------|------------|
-- Interventional Pain Management|       55906|
-- Pain Management               |       70853|

SELECT specialty_description,
		SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE specialty_description = 'Interventional Pain Management'
	  OR specialty_description = 'Pain Management'
GROUP BY specialty_description



-- 2. Now, let's say that we want our output to also include the total number of claims between these two groups. Combine two queries with the UNION keyword to accomplish this. Your output should look like this:

-- specialty_description         |total_claims|
-- ------------------------------|------------|
--                               |      126759|
-- Interventional Pain Management|       55906|
-- Pain Management               |       70853|



SELECT  '' AS specialty_description,
		SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE specialty_description = 'Interventional Pain Management'
	  OR specialty_description = 'Pain Management'

UNION

SELECT specialty_description,
		SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE specialty_description = 'Interventional Pain Management'
	  OR specialty_description = 'Pain Management'
GROUP BY specialty_description
ORDER BY total_claims DESC





-- 3. Now, instead of using UNION, make use of GROUPING SETS (https://www.postgresql.org/docs/10/queries-table-expressions.html#QUERIES-GROUPING-SETS) to achieve the same output.

-- 4. In addition to comparing the total number of prescriptions by specialty, let's also bring in information about the number of opioid vs. non-opioid claims by these two specialties. Modify your query (still making use of GROUPING SETS so that your output also shows the total number of opioid claims vs. non-opioid claims by these two specialites:

-- specialty_description         |opioid_drug_flag|total_claims|
-- ------------------------------|----------------|------------|
--                               |                |      129726|
--                               |Y               |       76143|
--                               |N               |       53583|
-- Pain Management               |                |       72487|
-- Interventional Pain Management|                |       57239|

-- 5. Modify your query by replacing the GROUPING SETS with ROLLUP(opioid_drug_flag, specialty_description). How is the result different from the output from the previous query?

-- 6. Switch the order of the variables inside the ROLLUP. That is, use ROLLUP(specialty_description, opioid_drug_flag). How does this change the result?

-- 7. Finally, change your query to use the CUBE function instead of ROLLUP. How does this impact the output?

-- 8. In this question, your goal is to create a pivot table showing for each of the 4 largest cities in Tennessee (Nashville, Memphis, Knoxville, and Chattanooga), the total claim count for each of six common types of opioids: Hydrocodone, Oxycodone, Oxymorphone, Morphine, Codeine, and Fentanyl. For the purpose of this question, we will put a drug into one of the six listed categories if it has the category name as part of its generic name. For example, we could count both of "ACETAMINOPHEN WITH CODEINE" and "CODEINE SULFATE" as being "CODEINE" for the purposes of this question.

-- The end result of this question should be a table formatted like this:

-- city       |codeine|fentanyl|hyrdocodone|morphine|oxycodone|oxymorphone|
-- -----------|-------|--------|-----------|--------|---------|-----------|
-- CHATTANOOGA|   1323|    3689|      68315|   12126|    49519|       1317|
-- KNOXVILLE  |   2744|    4811|      78529|   20946|    84730|       9186|
-- MEMPHIS    |   4697|    3666|      68036|    4898|    38295|        189|
-- NASHVILLE  |   2043|    6119|      88669|   13572|    62859|       1261|

-- For this question, you should look into use the crosstab function, which is part of the tablefunc extension (https://www.postgresql.org/docs/9.5/tablefunc.html). In order to use this function, you must (one time per database) run the command
-- 	CREATE EXTENSION tablefunc;

-- Hint #1: First write a query which will label each drug in the drug table using the six categories listed above.
-- Hint #2: In order to use the crosstab function, you need to first write a query which will produce a table with one row_name column, one category column, and one value column. So in this case, you need to have a city column, a drug label column, and a total claim count column.
-- Hint #3: The sql statement that goes inside of crosstab must be surrounded by single quotes. If the query that you are using also uses single quotes, you'll need to escape them by turning them into double-single quotes.









