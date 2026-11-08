/* ============================================================
   Fixes and additions for the Power BI dashboard
   Run the whole script in SSMS. GO separates the batches because
   CREATE VIEW must be the first statement in its batch.
   ============================================================ */
USE CreditRisk;
GO

/* 1) vw_missing_flags: the old version had no label, so the two
      fields (employment length / interest rate) were mixed up. */
DROP VIEW IF EXISTS vw_missing_flags;
GO
CREATE VIEW vw_missing_flags AS
SELECT
    'Employment length'                                              AS field_name,
    emp_length_missing                                               AS is_missing,
    COUNT(*)                                                         AS total_loans,
    SUM(loan_status)                                                 AS defaults,
    CAST(100.0 * SUM(loan_status) / COUNT(*) AS DECIMAL(5,2))        AS default_rate_pct
FROM loans
GROUP BY emp_length_missing
UNION ALL
SELECT
    'Interest rate',
    int_rate_missing,
    COUNT(*),
    SUM(loan_status),
    CAST(100.0 * SUM(loan_status) / COUNT(*) AS DECIMAL(5,2))
FROM loans
GROUP BY int_rate_missing;
GO

/* 2) vw_cap_simulation: was a plain SELECT, now a view */
CREATE VIEW vw_cap_simulation AS
SELECT
    t.cap_pct                                                              AS cap_pct,
    COUNT(*)                                                               AS rejected_loans,
    SUM(l.loan_status)                                                     AS defaults_avoided,
    SUM(1 - l.loan_status)                                                 AS good_customers_lost,
    CAST(100.0 * SUM(l.loan_status) / (SELECT SUM(loan_status) FROM loans) AS DECIMAL(5,2)) AS pct_of_all_defaults_avoided
FROM (VALUES (20), (25), (30), (35), (40)) AS t(cap_pct)
JOIN loans l ON l.loan_percent_income > t.cap_pct / 100.0
GROUP BY t.cap_pct;
GO

/* 3) vw_risk_tiers: was a plain SELECT, now a view */
CREATE VIEW vw_risk_tiers AS
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
   + CASE WHEN cb_person_default_on_file = 'Y' THEN 1 ELSE 0 END);
GO

/* 4) Business view: how much of the money lent sits in defaulted loans.
      This is exposure (amount lent), not actual loss. */
CREATE VIEW vw_exposure AS
SELECT
    SUM(CAST(loan_amnt AS BIGINT))                                                         AS total_lent,
    SUM(CASE WHEN loan_status = 1 THEN CAST(loan_amnt AS BIGINT) ELSE 0 END)               AS lent_in_defaults,
    CAST(100.0 * SUM(CASE WHEN loan_status = 1 THEN CAST(loan_amnt AS BIGINT) ELSE 0 END)
          / SUM(CAST(loan_amnt AS BIGINT)) AS DECIMAL(5,2))                                AS defaults_share_pct
FROM loans;
GO

/* 5) Business view: the cap simulation in money terms */
CREATE VIEW vw_cap_exposure AS
SELECT
    t.cap_pct                                                                              AS cap_pct,
    SUM(CASE WHEN l.loan_status = 1 THEN CAST(l.loan_amnt AS BIGINT) ELSE 0 END)           AS exposure_avoided,
    SUM(CASE WHEN l.loan_status = 0 THEN CAST(l.loan_amnt AS BIGINT) ELSE 0 END)           AS good_lending_lost
FROM (VALUES (20), (25), (30), (35), (40)) AS t(cap_pct)
JOIN loans l ON l.loan_percent_income > t.cap_pct / 100.0
GROUP BY t.cap_pct;
GO

SELECT * FROM vw_exposure;
