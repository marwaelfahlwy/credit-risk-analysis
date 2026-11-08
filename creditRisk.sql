CREATE DATABASE CreditRisk;
USE CreditRisk;

SELECT*
FROM loans;
-- للتأكد انو الداتا اللي سحبتها صحيحية هختبرها 
--هشوف عدد  صفوف الداتا 
SELECT
	COUNT(*) AS Total_Rows,
	SUM(loan_status) AS Loans_Status

FROM
	loans;

-- المفروض عندي 32409 قرض وعندي 7088 قرض متعثر
-------------------------------------------------------------

ALTER TABLE loans ALTER COLUMN loan_int_rate DECIMAL(6,3);
ALTER TABLE loans ALTER COLUMN loan_percent_income DECIMAL(5,2);

SELECT 
	TOP 5 age_group, 
	income_group, 
	lti_group, 
	loan_int_rate 
FROM 
	loans;

---------------------------------------------------------------
-- دلوقتي هجيب اعلى واقل فايدة عشان اتأكد اني بعد ما حولت الداتا هيا هيا 
SELECT
	MAX(loan_int_rate) AS THE_HIGHEST, 
    MIN(loan_int_rate) AS THE_LEAST
FROM 
	loans;
---------------------------------------------------------------
 -- دلوقتي هنحسب عدد القروض وعدد المتعثرين ونسبة التعثر الكلية 
 -- لانو دا الاساس اللي هقارن بيه بعد كدا
 SELECT
    COUNT(*) AS total_loans,
    SUM(loan_status) AS defaults,
    ROUND(100.0 * SUM(loan_status) / COUNT(*), 2) AS default_rate_pct
 FROM
	loans;
----------------------------------------------------------------------
SELECT 
	TOP 5 loan_grade, loan_int_rate, loan_percent_income
FROM 
	loans;
SELECT 
	MIN(loan_int_rate) AS min_rate,	
	MAX(loan_int_rate) AS max_rate 
FROM 
	loans;
----------------------------------------------------------------------
--التعثر حسب درجة القرض 
CREATE VIEW DEFAULT_BY_LOANS AS 
    SELECT
        loan_grade,
        COUNT(*)                                        AS total_loans,
        SUM(loan_status)                                AS defaults,
        ROUND(100.0 * SUM(loan_status) / COUNT(*), 2)   AS default_rate_pct
    FROM
	    loans
    GROUP BY 
	    loan_grade
    --ORDER BY 
	   -- loan_grade;
--------------------------------------------------------------------------
-- التعثر حسب نوع السكن 
SELECT
    person_home_ownership,
    COUNT(*)                                                         AS total_loans,
    SUM(loan_status)                                                 AS defaults,
    CAST(100.0 * SUM(loan_status) / COUNT(*) AS DECIMAL(5,2))        AS default_rate_pct
FROM 
	loans
GROUP BY
	person_home_ownership
ORDER BY 
	default_rate_pct DESC;
-------------------------------------------------------------------------
-- التعثر حسب غرض القرض
SELECT
    loan_intent,
    COUNT(*)                                                         AS total_loans,
    SUM(loan_status)                                                 AS defaults,
    CAST(100.0 * SUM(loan_status) / COUNT(*) AS DECIMAL(5,2))        AS default_rate_pct
FROM 
	loans
GROUP BY 
	loan_intent
ORDER BY 
	default_rate_pct DESC;
---------------------------------------------------------------------------
-- التعثر حسب وجود تعثر سابق
SELECT
    cb_person_default_on_file,
    COUNT(*)                                                         AS total_loans,
    SUM(loan_status)                                                 AS defaults,
    CAST(100.0 * SUM(loan_status) / COUNT(*) AS DECIMAL(5,2))        AS default_rate_pct
FROM 
	loans
GROUP BY 
	cb_person_default_on_file
ORDER BY 
	default_rate_pct DESC;
-------------------------------------------------------------------------------
-- التعثر حسب نسبة القرض للدخل
SELECT
    lti_group,
    COUNT(*)                                                         AS total_loans,
    SUM(loan_status)                                                 AS defaults,
    CAST(100.0 * SUM(loan_status) / COUNT(*) AS DECIMAL(5,2))        AS default_rate_pct
FROM 
	loans
GROUP BY 
	lti_group
ORDER BY 
	lti_group;

------------------------------------------------------------------------------------
--التعثر حسب فئة السن
SELECT
    age_group,
    COUNT(*)                                                         AS total_loans,
    SUM(loan_status)                                                 AS defaults,
    CAST(100.0 * SUM(loan_status) / COUNT(*) AS DECIMAL(5,2))        AS default_rate_pct
FROM 
	loans
GROUP BY 
	age_group
ORDER BY 
	age_group;

----------------------------------------------------------------------------------------
-- التعثر حسب فئة الدخل
SELECT
    income_group,
    COUNT(*)                                                         AS total_loans,
    SUM(loan_status)                                                 AS defaults,
    CAST(100.0 * SUM(loan_status) / COUNT(*) AS DECIMAL(5,2))        AS default_rate_pct
FROM 
	loans
GROUP BY
	income_group
ORDER BY
	income_group;
---------------------------------------------------------------------------------------
-- الدخل ونسبة القرض مع بعض
SELECT
    lti_group,
    income_group,
    COUNT(*)                                                         AS total_loans,
    CAST(100.0 * SUM(loan_status) / COUNT(*) AS DECIMAL(5,2))        AS default_rate_pct
FROM loans
GROUP BY lti_group, income_group
ORDER BY MIN(loan_percent_income), MIN(person_income);
-----------------------------------------------------------------------------------------
-- هل النسبة بتفرق حتى مع نفس الدرجة
SELECT
    CASE WHEN loan_grade IN ('A','B','C') THEN 'A-C' ELSE 'D-G' END   AS grade_band,
    lti_group,
    COUNT(*)                                                           AS total_loans,
    CAST(100.0 * SUM(loan_status) / COUNT(*) AS DECIMAL(5,2))          AS default_rate_pct
FROM loans
GROUP BY CASE WHEN loan_grade IN ('A','B','C') THEN 'A-C' ELSE 'D-G' END, lti_group
ORDER BY grade_band, MIN(loan_percent_income);
------------------------------------------------------------------------------------------
-- هل الفايدة العالية بتعوّض الخطورة؟
CREATE VIEW vw_grade_pricing AS
SELECT
    loan_grade,
    COUNT(*)                                                         AS total_loans,
    CAST(AVG(loan_int_rate) AS DECIMAL(5,2))                         AS avg_int_rate,
    CAST(100.0 * SUM(loan_status) / COUNT(*) AS DECIMAL(5,2))        AS default_rate_pct
FROM loans
GROUP BY loan_grade
--ORDER BY loan_grade;
-------------------------------------------------------------------------------------------
-- لو البنك حط سقف لنسبة القرض للدخل؟
SELECT
    t.cap_pct                                                              AS cap_pct,
    COUNT(*)                                                               AS rejected_loans,
    SUM(l.loan_status)                                                     AS defaults_avoided,
    SUM(1 - l.loan_status)                                                 AS good_customers_lost,
    CAST(100.0 * SUM(l.loan_status) / (SELECT SUM(loan_status) FROM loans) AS DECIMAL(5,2))  AS pct_of_all_defaults_avoided
FROM (VALUES (20), (25), (30), (35), (40)) AS t(cap_pct)
JOIN loans l ON l.loan_percent_income > t.cap_pct / 100.0
GROUP BY t.cap_pct
ORDER BY t.cap_pct;
---------------------------------------------------------------------------------------------
-- هل حجم لاقرض بيفرق ف التعثر
-- هل حجم القرض (loan_amnt) بيفرق في التعثر؟
-- عشان نعرف هل المبلغ نفسه مؤثر ولا بس نسبته للدخل
CREATE VIEW vw_amount_bands AS
SELECT
    CASE
        WHEN loan_amnt <= 5000  THEN '1. up to 5K'
        WHEN loan_amnt <= 10000 THEN '2. 5K-10K'
        WHEN loan_amnt <= 15000 THEN '3. 10K-15K'
        ELSE                         '4. over 15K'
    END                                                                AS amount_band,
    COUNT(*)                                                           AS total_loans,
    SUM(loan_status)                                                   AS defaults,
    CAST(100.0 * SUM(loan_status) / COUNT(*) AS DECIMAL(5,2))          AS default_rate_pct
FROM loans
GROUP BY
    CASE
        WHEN loan_amnt <= 5000  THEN '1. up to 5K'
        WHEN loan_amnt <= 10000 THEN '2. 5K-10K'
        WHEN loan_amnt <= 15000 THEN '3. 10K-15K'
        ELSE                         '4. over 15K'
    END
--ORDER BY amount_band;
---------------------------------------------------------------------------
-- هل سنين الخبرة في الشغل بتفرق؟	
CREATE VIEW vw_experience_bands AS
SELECT
    CASE
        WHEN person_emp_length <= 1 THEN '1. 0-1 years'
        WHEN person_emp_length <= 3 THEN '2. 2-3 years'
        WHEN person_emp_length <= 6 THEN '3. 4-6 years'
        WHEN person_emp_length <= 9 THEN '4. 7-9 years'
        ELSE                             '5. 10+ years'
    END                                                                AS emp_band,
    COUNT(*)                                                           AS total_loans,
    SUM(loan_status)                                                   AS defaults,
    CAST(100.0 * SUM(loan_status) / COUNT(*) AS DECIMAL(5,2))          AS default_rate_pct
FROM loans
GROUP BY
    CASE
        WHEN person_emp_length <= 1 THEN '1. 0-1 years'
        WHEN person_emp_length <= 3 THEN '2. 2-3 years'
        WHEN person_emp_length <= 6 THEN '3. 4-6 years'
        WHEN person_emp_length <= 9 THEN '4. 7-9 years'
        ELSE                             '5. 10+ years'
    END
--ORDER BY emp_band;
---------------------------------------------------------------------------------------------
-- هل طول التاريخ الائتماني بيفرق؟
CREATE VIEW vw_history_bands AS
SELECT
    CASE
        WHEN cb_person_cred_hist_length <= 3  THEN '1. 2-3 years'
        WHEN cb_person_cred_hist_length <= 5  THEN '2. 4-5 years'
        WHEN cb_person_cred_hist_length <= 8  THEN '3. 6-8 years'
        WHEN cb_person_cred_hist_length <= 12 THEN '4. 9-12 years'
        ELSE                                       '5. 13+ years'
    END                                                                AS hist_band,
    COUNT(*)                                                           AS total_loans,
    SUM(loan_status)                                                   AS defaults,
    CAST(100.0 * SUM(loan_status) / COUNT(*) AS DECIMAL(5,2))          AS default_rate_pct
FROM loans
GROUP BY
    CASE
        WHEN cb_person_cred_hist_length <= 3  THEN '1. 2-3 years'
        WHEN cb_person_cred_hist_length <= 5  THEN '2. 4-5 years'
        WHEN cb_person_cred_hist_length <= 8  THEN '3. 6-8 years'
        WHEN cb_person_cred_hist_length <= 12 THEN '4. 9-12 years'
        ELSE                                       '5. 13+ years'
    END
--ORDER BY hist_band;
----------------------------------------------------------------------------------
-- هل الصفوف اللي كانت ناقصة (خبرة أو فايدة) ليها نسبة تعثر مختلفة؟
CREATE VIEW vw_missing_flags AS
SELECT
    emp_length_missing,
    COUNT(*)                                                           AS total_loans,
    SUM(loan_status)                                                   AS defaults,
    CAST(100.0 * SUM(loan_status) / COUNT(*) AS DECIMAL(5,2))          AS default_rate_pct
FROM loans
GROUP BY emp_length_missing
--ORDER BY emp_length_missing

UNION ALL

SELECT
    int_rate_missing,
    COUNT(*)                                                           AS total_loans,
    SUM(loan_status)                                                   AS defaults,
    CAST(100.0 * SUM(loan_status) / COUNT(*) AS DECIMAL(5,2))          AS default_rate_pct
FROM loans
GROUP BY int_rate_missing
--ORDER BY int_rate_missing;
-------------------------------------------------------------------------------------------
-- ملف العميل الأخطر والأأمن: أنهي تركيبات (سكن + درجة + نسبة قرض) أعلى وأقل في التعثر؟
CREATE VIEW vw_risk_profiles AS
SELECT
    person_home_ownership,
    CASE WHEN loan_grade IN ('A','B','C') THEN 'A-C' ELSE 'D-G' END   AS grade_band,
    lti_group,
    COUNT(*)                                                           AS total_loans,
    SUM(loan_status)                                                   AS defaults,
    CAST(100.0 * SUM(loan_status) / COUNT(*) AS DECIMAL(5,2))          AS default_rate_pct
FROM loans
GROUP BY
    person_home_ownership,
    CASE WHEN loan_grade IN ('A','B','C') THEN 'A-C' ELSE 'D-G' END,
    lti_group
HAVING COUNT(*) >= 100
--ORDER BY default_rate_pct DESC;



SELECT
    person_home_ownership,
    COUNT(*)           AS total_loans,
    SUM(loan_status)   AS defaults
FROM loans
WHERE loan_percent_income > 0.30
GROUP BY person_home_ownership
ORDER BY person_home_ownership;
---------------------------------------------------------------------------------------
-- قاعدة تقييم بسيطة: لو عرّفنا "عميل عالي الخطورة" بقواعد (نسبة قرض فوق 30% أو درجة D فأعلى أو تعثر سابق)، كام متعثر بتلقط وكام عميل كويس بتظلمه؟
CREATE VIEW vw_rule_performance AS
SELECT
    CASE WHEN loan_percent_income > 0.30
           OR loan_grade IN ('D','E','F','G')
           OR cb_person_default_on_file = 'Y'
         THEN 'High risk' ELSE 'Not flagged' END                       AS risk_flag,
    COUNT(*)                                                           AS total_loans,
    SUM(loan_status)                                                   AS defaults,
    SUM(1 - loan_status)                                               AS good_customers,
    CAST(100.0 * SUM(loan_status) / COUNT(*) AS DECIMAL(5,2))          AS default_rate_pct
FROM loans
GROUP BY
    CASE WHEN loan_percent_income > 0.30
           OR loan_grade IN ('D','E','F','G')
           OR cb_person_default_on_file = 'Y'
         THEN 'High risk' ELSE 'Not flagged' END;





SELECT
    (CASE WHEN loan_percent_income > 0.30 THEN 1 ELSE 0 END
   + CASE WHEN loan_grade IN ('D','E','F','G') THEN 1 ELSE 0 END
   + CASE WHEN cb_person_default_on_file = 'Y' THEN 1 ELSE 0 END)    AS rules_triggered,
    COUNT(*)                                                           AS total_loans,
    SUM(loan_status)                                                   AS defaults,
    CAST(100.0 * SUM(loan_status) / COUNT(*) AS DECIMAL(5,2))          AS default_rate_pct
FROM loans
GROUP BY
    (CASE WHEN loan_percent_income > 0.30 THEN 1 ELSE 0 END
   + CASE WHEN loan_grade IN ('D','E','F','G') THEN 1 ELSE 0 END
   + CASE WHEN cb_person_default_on_file = 'Y' THEN 1 ELSE 0 END)
ORDER BY rules_triggered;
----------------------------------------
SELECT @@SERVERNAME AS server_name;