# Credit Risk Analysis: Who Defaults, and What Lending Policy Reduces It?

End-to-end data analytics project on **32,409 loans**: data cleaning in **Power Query**, analysis in **SQL Server**, and a 4-page interactive dashboard in **Power BI**.

> **Business question:** Which borrowers default, and which lending policy reduces defaults without turning away good customers?

## Dashboard

| Overview | Risk Drivers |
|---|---|
| ![Overview](images/01_overview.png) | ![Risk Drivers](images/02_risk_drivers.png) |

| The 30% line | Recommendations |
|---|---|
| ![Loan-to-Income](images/03_loan_to_income.png) | ![Recommendations](images/04_recommendations.png) |

## Dataset

- Loan-level data: 32,581 rows and 12 columns (borrower age, income, home ownership, employment length, loan grade, amount, interest rate, loan-to-income, prior default, credit history length, and the target `loan_status`).
- **Note:** the data shows strong signs of being synthetic (see Limitations), so the results illustrate the method rather than real market behaviour.

## Tools

Excel (initial inspection), Power Query (cleaning), SQL Server and SSMS (analysis, views), Power BI and DAX (dashboard).

## Workflow

### 1. Data cleaning (Power Query)

| Issue | Rows | Decision | Why |
|---|---|---|---|
| Exact duplicates | 165 | Removed | No new information |
| Impossible ages (123, 144) | 5 | Removed | Cannot be corrected |
| Employment length of 123 years | 2 | Removed | Impossible |
| Missing `person_emp_length` | 887 | Median (4) + flag column | Missing rows defaulted more (31.7% vs 21.6%), so the flag keeps that signal |
| Missing `loan_int_rate` | 3,094 | Median per loan grade + flag column | Interest rate is driven by grade |
| Income above 1M | 8 | Kept + flag column | Ages are plausible |

Result: **32,409 rows, 18 columns**. Six columns were added: 3 flags and 3 bands (age, income, loan-to-income). As a check, key results were recomputed on complete rows only and stayed close (default rate 21.87% vs 21.71%).

### 2. Analysis (SQL Server)

- Default rate by grade, home ownership, loan purpose, prior default, age, income, job length, credit history, loan amount.
- Combinations of factors (income x loan-to-income, grade x loan-to-income) to test whether a factor is independent.
- Interest rate vs default rate per grade (is risk priced in?).
- Policy simulation: a cap on loan-to-income at 20%, 25%, 30%, 35%, 40%, in loans and in money.
- A simple 3-rule risk flag and how well it performs.
- Every analysis is saved as a **SQL view** that Power BI reads, so SQL and the dashboard show the same numbers.

### 3. Dashboard (Power BI)

Four pages that follow the story: the problem, the drivers, the 30% line, the recommendation. All risk charts share the same scale so strong and weak factors can be compared by eye.

## Key findings

- **21.87%** of loans defaulted, and **24.75%** of the money lent (76.9M of 310.9M) sits in defaulted loans.
- Default rate jumps at **grade D: 59%** (grades A to C: 10% to 21%).
- Strongest factors: loan-to-income, income (under 30K: 45.6% vs over 100K: 9.6%), home ownership (renters 31.6% vs owners 7.5%).
- Weak factors: age and credit history length.
- Loan-to-income above **30%** lifts the default rate to **70%**. That group is 12% of loans but 38% of all defaults, and it holds even among loans graded A to C (3,019 loans, 67% default), so grade alone is not enough.

## Recommendation

Cap loan-to-income at **30%**:

- Avoids 2,689 defaults (38%) and about 40.2M of money tied to defaults.
- Turns away 1,129 good customers (20.0M, 8.6% of repaid lending).
- A simple rule (loan-to-income above 30%, or grade D or worse, or prior default) catches 76% of defaults and flags 21% of good customers.

## Limitations

- The data looks synthetic: every renter above 30% loan-to-income defaulted (2,339 of 2,339), and the default rate jumps from 24% at 30% to 69% at 31%.
- The 30% effect is concentrated among renters; non-renters above 30% default at 23.7%.
- Correlation, not causation.
- Amounts are money lent, not actual loss (recoveries and interest are not in the data).
- The risk rule was built and tested on the same data, so its performance is optimistic.
- Next steps: logistic regression to isolate each factor, a train/test split, and real lending data.

## Repository structure

```
credit-risk-analysis/
├── README.md
├── images/                 dashboard screenshots
├── data/                   cleaned dataset (see note below)
├── sql/
│   ├── 01_analysis.sql
│   └── 02_views.sql
├── powerbi/
│   └── credit_risk_dashboard.pbix
├── docs/
│   ├── cleaning_log.md
│   └── presentation.pptx
```

## How to reproduce

1. Load the cleaned CSV into SQL Server as a table named `loans` in a database named `CreditRisk`.
2. Run the SQL scripts in `sql/` (each view is separated by `GO`).
3. Open the `.pbix`, point the data source to your SQL Server, and refresh.

## Author

 Marwa Elfahlwy · www.linkedin.com/in/marwa-elfahlwy

 · marwaelfahlwy@gmail.com
