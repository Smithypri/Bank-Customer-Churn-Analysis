CREATE TABLE IF NOT EXISTS bank_churn
(
	RowNumber SERIAL,
	CustomerId INTEGER PRIMARY KEY,
	Surname VARCHAR(50) NOT NULL,
	CreditScore INTEGER NOT NULL,
	Geography VARCHAR(50),
	Gender VARCHAR(50),
	Age INTEGER,
	Tenure INTEGER,
	Balance FLOAT,
	NumOfProducts INTEGER,
	HasCrCard INTEGER,
	IsActiveMember INTEGER,
	EstimatedSalary FLOAT,
	Exited INTEGER
);


CREATE TABLE IF NOT EXISTS active_customer
(
	IsActiveMember INTEGER,
	Active_Category VARCHAR(10) 
);


CREATE TABLE IF NOT EXISTS bank_churn
(
	RowNumber SERIAL,
	CustomerId INTEGER PRIMARY KEY,
	Surname VARCHAR(50) NOT NULL,
	CreditScore INTEGER NOT NULL,
	Geography VARCHAR(50),
	Gender VARCHAR(50),
	Age INTEGER,
	Tenure INTEGER,
	Balance FLOAT,
	NumOfProducts INTEGER,
	HasCrCard INTEGER,
	IsActiveMember INTEGER,
	EstimatedSalary FLOAT,
	Exited INTEGER
);

CREATE TABLE IF NOT EXISTS credit_card
(
	HasCrCard INTEGER PRIMARY KEY,
	Credit_card VARCHAR(10)
);


CREATE TABLE IF NOT EXISTS exit_customer
(
	Exited INTEGER PRIMARY KEY,
	Exit_category VARCHAR(10)
);

--First dataset look
SELECT * FROM bank_churn;
SELECT * FROM active_customer;
SELECT * FROM credit_card;
SELECT * FROM exit_customer

-- row count of tables
SELECT COUNT(*) AS Row_Count FROM bank_churn;
SELECT COUNT(*) AS Row_Count FROM active_customer;
SELECT COUNT(*) AS Row_Count FROM credit_card;
SELECT COUNT(*) AS Row_Count FROM exit_customer;


-- 1.Total customers of Bank
SELECT COUNT(*) AS total_customers
FROM bank_churn;

-- 2.Total active members
SELECT COUNT(*) AS active_customers_count
FROM bank_churn
INNER JOIN active_customer
ON bank_churn.IsActiveMember = active_customer.IsActiveMember
WHERE active_customer.active_category = 'Yes';

-- 3. Total In-active members
SELECT COUNT() - (SELECT COUNT() 
FROM bank_churn
INNER JOIN active_customer
ON bank_churn.IsActiveMember = active_customer.IsActiveMember
WHERE active_customer.active_category = 'Yes') AS in_active_customers_count
FROM bank_churn;

-- 4. Total credit card holders
SELECT COUNT(*) AS credit_card_holders_count
FROM bank_churn
INNER JOIN credit_card
ON bank_churn.hascrcard = credit_card.hascrcard
WHERE credit_card.credit_card = 'Yes';

-- 5. Total non-credit card holders
SELECT COUNT(*) AS non_credit_card_holders_count
FROM bank_churn
INNER JOIN credit_card
ON bank_churn.hascrcard = credit_card.hascrcard
WHERE credit_card.credit_card = 'No';

--6. Total customers Exited
SELECT COUNT(*) AS customers_exited_count
FROM bank_churn
INNER JOIN exit_customer
ON bank_churn.exited = exit_customer.exited
WHERE exit_customer.exit_category = 'Yes';

--7 . Total retained customers 
SELECT COUNT(*) AS customers_retained_count
FROM bank_churn
INNER JOIN exit_customer
ON bank_churn.exited = exit_customer.exited
WHERE exit_customer.exit_category = 'No';

--8 . Credit score type based on credit score
SELECT creditscore,
CASE 
    WHEN creditscore >= 800 AND creditscore <= 850 THEN 'Excellent'
	WHEN creditscore >= 740 AND creditscore <= 799 THEN 'Very Good'
	WHEN creditscore >= 670 AND creditscore <= 739 THEN 'Good'
	WHEN creditscore >= 580 AND creditscore <= 669 THEN 'Fair'
	ELSE 'Poor'
END AS credit_score_type
FROM bank_churn
LIMIT 5;

--9 . Customer churn with respect to credit score type
SELECT 
CASE 
    WHEN creditscore >= 800 AND creditscore <= 850 THEN 'Excellent'
	WHEN creditscore >= 740 AND creditscore <= 799 THEN 'Very Good'
	WHEN creditscore >= 670 AND creditscore <= 739 THEN 'Good'
	WHEN creditscore >= 580 AND creditscore <= 669 THEN 'Fair'
	ELSE 'Poor'
END AS credit_score_type,COUNT(CustomerId)AS exit_customer_count
FROM bank_churn
INNER JOIN exit_customer
ON bank_churn.Exited = exit_customer.Exited
WHERE exit_customer.exit_category = 'Yes'
GROUP BY credit_score_type
ORDER BY exit_customer_count DESC;


-- 10 . Customer churn with respect to whether the customer is an active member or not
SELECT Active_Category, COUNT(CustomerId)AS exit_customer_count
FROM bank_churn
INNER JOIN exit_customer ON bank_churn.Exited = exit_customer.Exited
INNER JOIN active_customer ON bank_churn.IsActiveMember = active_customer.IsActiveMember
WHERE exit_customer.exit_category = 'Yes'
GROUP BY Active_Category
ORDER BY exit_customer_count DESC;
/* This shows that the customers who have Fair and poor credit score type are more prone to exit bank and 
the customer who have credit score type as Excellent are least expected to exit the bank. */


-- 11 . Effect of age group and Geography leading to Female customers churn
CREATE TEMPORARY TABLE age_table AS
(	SELECT *,
CASE 
    WHEN age >= 18 AND age <= 20 THEN '18-20'
	WHEN age >= 21 AND age <= 30 THEN '21-30'
	WHEN age >= 31 AND age <= 40 THEN '31-40'
	WHEN age >= 41 AND age <= 50 THEN '41-50'
	WHEN age >= 51 AND age <= 60 THEN '51-60'
	ELSE '>60'
END AS age_group
FROM bank_churn
 );
 
SELECT age_group
, COALESCE(France, 0) AS France
, COALESCE(Germany, 0) AS Germany
, COALESCE(Spain, 0) AS Spain
FROM CROSSTAB('SELECT age_group 
    			, Geography
    			, COUNT(customerId) as exit_customer_count
    			FROM age_table 
    			INNER JOIN exit_customer
                ON age_table.Exited = exit_customer.Exited
                WHERE exit_customer.exit_category = ''Yes'' AND gender = ''Female''
    			GROUP BY age_group,Geography
				ORDER BY age_group,Geography',
            'VALUES (''France''), (''Germany''), (''Spain'')')
    AS final_result(age_group VARCHAR, France BIGINT, Germany BIGINT, Spain BIGINT);
	/* Female customers in the age group of 41-50 who are from Germany are most likely to exit bank. */


-- 12. Effect of Tenure and Geography leading to Female customers churn
SELECT Tenure
, COALESCE(France, 0) AS France
, COALESCE(Germany, 0) AS Germany
, COALESCE(Spain, 0) AS Spain
FROM CROSSTAB('SELECT Tenure 
    			, Geography
    			, COUNT(customerId) as exit_customer_count
    			FROM bank_churn 
    			INNER JOIN exit_customer
                ON bank_churn.Exited = exit_customer.Exited
                WHERE exit_customer.exit_category = ''Yes'' AND gender = ''Female''
    			GROUP BY Tenure,Geography
				ORDER BY Tenure,Geography',
            'VALUES (''France''), (''Germany''), (''Spain'')')
    AS final_result(Tenure VARCHAR, France BIGINT, Germany BIGINT, Spain BIGINT);
	/* Female customers with a tenure of 1 year and who are from Germany are most likely to exit bank. */


-- 13. Effect of number of products and Geography leading to Female customers churn
SELECT NumOfProducts,France,Germany,Spain
	FROM CROSSTAB('SELECT NumOfProducts 
    			, Geography
    			, COUNT(customerId) as exit_customer_count
    			FROM bank_churn 
    			INNER JOIN exit_customer
                ON bank_churn.Exited = exit_customer.Exited
                WHERE exit_customer.exit_category = ''Yes'' AND gender = ''Female''
    			GROUP BY NumOfProducts,Geography
				ORDER BY NumOfProducts,Geography',
            'VALUES (''France''), (''Germany''), (''Spain'')')
    AS final_result(NumOfProducts VARCHAR, France BIGINT, Germany BIGINT, Spain BIGINT);
	/* Female customers with a number of products as 1 and who are from Germany are most likely to exit bank. */



-- 14. Effect of active customer status and Geography leading to Female customers churn
SELECT Active_Category,France,Germany,Spain
	FROM CROSSTAB('SELECT Active_Category 
    			, Geography
    			, COUNT(customerId) as exit_customer_count
    			FROM bank_churn 
    			INNER JOIN exit_customer ON bank_churn.Exited = exit_customer.Exited
				INNER JOIN active_customer ON bank_churn.IsActiveMember = active_customer.IsActiveMember
                WHERE exit_customer.exit_category = ''Yes'' AND gender = ''Female''
    			GROUP BY Active_Category,Geography
				ORDER BY Active_Category,Geography',
            'VALUES (''France''), (''Germany''), (''Spain'')')
    AS final_result(Active_Category VARCHAR, France BIGINT, Germany BIGINT, Spain BIGINT);
/* Female customers who are not active members and who are from France are most likely to exit bank. */

-- 15.  Effect of balance group and Geography leading to Female customers churn
CREATE TEMPORARY TABLE balance_table AS
(	SELECT *,
CASE 
    WHEN balance >= 0 AND balance <= 100000 THEN '0-100000'
	WHEN balance >= 100001 AND balance <= 150000 THEN '100000-150000'
	WHEN balance >= 150001 AND balance <= 200000 THEN '150001-200000'
	WHEN balance >= 200001 AND balance <= 250000 THEN '200001-250000'
	ELSE '>250000'
END AS balance_group
FROM bank_churn
 );
 
SELECT balance_group
, COALESCE(France, 0) AS France
, COALESCE(Germany, 0) AS Germany
, COALESCE(Spain, 0) AS Spain
FROM CROSSTAB('SELECT balance_group 
    			, Geography
    			, COUNT(customerId) as exit_customer_count
    			FROM balance_table 
    			INNER JOIN exit_customer
                ON balance_table.Exited = exit_customer.Exited
                WHERE exit_customer.exit_category = ''Yes'' AND gender = ''Female''
    			GROUP BY balance_group,Geography
				ORDER BY balance_group,Geography',
            'VALUES (''France''), (''Germany''), (''Spain'')')
    AS final_result(balance_group VARCHAR, France BIGINT, Germany BIGINT, Spain BIGINT);
/* Female customers with account balance between 100000 and 150000 and who are from Germany are most likely to exit bank. */
