# India Job Market Analysis Dashboard

An interactive 3-page Power BI report built on **717 job postings** from the Adzuna API. It shows how active hiring is for each role, which skills employers ask for, what the roles pay, and where the jobs are.

**Roles covered:** Data Analyst · Business Analyst · Data Scientist · Data Engineer · AI Engineer · Full Stack Developer

**Tools:** Python (API data collection) · Excel (data cleaning) · PostgreSQL · SQL · Power BI · DAX

## Dashboard preview

| Page 1: Overview | Page 2: Skills and Roles | Page 3: Salary, Experience and Location |
|---|---|---|
| ![Overview](screenshots/Overview.png) | ![Skills and Roles](screenshots/Skills_and_Roles.png) | ![Salary and Location](screenshots/Salary_and_Location.png) |

Full report as PDF: [India_Job_Market_Dashboard.pdf](India_Job_Market_Dashboard.pdf)

## Business questions

1. How active is hiring for each role right now (share of recent postings)?
2. Which skills do employers ask for, overall and for each role?
3. How much do these roles pay, and how does pay change with experience?
4. Which cities have the most openings?

## Key insights

- **Pay splits into two tiers.** AI Engineer, Data Scientist and Data Engineer postings have a median of **12.8 to 15.5 LPA** (average 15.0 to 16.9), while Data Analyst, Business Analyst and Full Stack Developer have a median of **6.5 to 7.5 LPA** (average 8.3 to 9.4). Salary is the midpoint of the advertised range. Averages run higher than medians because a few high salaries pull them up.
- **Pay tends to rise with experience.** Average midpoint is **12.3 LPA** for 0-2 years, **13.0** for 3-5 years and **16.4** for 6+ years. The 6+ group has only 13 postings, so treat it as a direction, not a precise figure.
- **Bangalore dominates.** It has **187 of the 515 postings with a known city (36%)**, about 3.5 times Hyderabad or Pune (54 each).
- **Python and SQL lead skills demand.** They appear in **107 and 100** of the 357 postings with detected skills. For Data Analyst postings, **SQL** is the top skill: 35 of the 68 Data Analyst postings with detected skills (51%), ahead of Excel and Python (20 each), Power BI (16) and Tableau (14).
- **AI Engineer is the most active hiring role right now.** **117 of 137 postings (85%)** are recent, the highest share of any role.
- **Salary transparency is low.** Only **308 of 717 postings (43%)** list a salary, from 73% for Full Stack Developer to 26% for AI Engineer.

## Data

| Item | Detail |
|---|---|
| Source | Adzuna Jobs API, one search per role, India |
| Size | 717 postings, 548 companies |
| Posted dates | 17 May 2019 to 8 Oct 2026 (58% posted in the last ~6 months, 39% dated before 2026) |
| "Recent" | Posted in roughly the last 6 months before the data pull (from mid-April 2026) |
| Storage | PostgreSQL database `india_job_analysis` |

**Data files in this repository**

| File | Rows | Description |
|---|---|---|
| `india_jobs_final_clean.csv` | 717 | One row per posting: role, title, company, city, salary min/max, minimum experience, posted date and derived flags (`has_salary`, `has_skills`, `salary_mid_lpa`, `is_recent`) |
| `india_job_skills_717.csv` | 977 | One row per posting and skill (`job_id`, `skill`), covering 357 postings |
| `queries.sql` | | SQL used to set up and validate the data in PostgreSQL |

**Model:** `jobs_final` (1) → `job_skills` (many) on `job_id`, single direction filter.

**How the data was prepared**

1. Job postings were collected from the Adzuna API using Python (one search per role).
2. Basic cleaning was done in Python, and the remaining cleaning was done in Excel.
3. The cleaned data was loaded into PostgreSQL and checked with SQL queries (row counts, duplicates, nulls, date range).
4. Power BI reads the two tables and the report is built on top, with DAX measures for salary, coverage and skills.

## Report pages

- **Overview:** total postings, postings with salary, postings with detected skills, average salary, postings by role (sample), recent postings by role, top 8 cities, top 8 skills.
- **Skills and Roles:** top skills, selected skills by role, skill coverage by role, top skills in Data Analyst postings, and the most common role-skill combinations.
- **Salary, Experience and Location:** median salary by role, min vs max salary, salary by experience band, top cities (all vs recent), share of postings listing a salary, highest advertised salaries.

Role, City and Posted date slicers are synced across pages. Every page has a navigator, key findings and a source note.

## Selected DAX

```DAX
Total Jobs = DISTINCTCOUNT(jobs_final[job_id])

Jobs With Salary =
CALCULATE(DISTINCTCOUNT(jobs_final[job_id]), jobs_final[has_salary] = TRUE())

Salary Data Coverage % = DIVIDE([Jobs With Salary], [Total Jobs])

Average Salary Midpoint = ROUND(AVERAGE(jobs_final[salary_mid_lpa]), 1)

Median Salary Midpoint = ROUND(MEDIAN(jobs_final[salary_mid_lpa]), 1)

Jobs With Detected Skills =
COUNTROWS(
    FILTER(VALUES(jobs_final[job_id]), CALCULATE(COUNTROWS(job_skills)) > 0)
)

Jobs by Skill = DISTINCTCOUNT(job_skills[job_id])

Jobs by Skill (Data Analyst) =
CALCULATE(DISTINCTCOUNT(job_skills[job_id]), jobs_final[role] = "Data Analyst")

Recent Jobs =
CALCULATE(DISTINCTCOUNT(jobs_final[job_id]), jobs_final[is_recent] = TRUE())

-- Calculated column: experience bands
exp_band =
SWITCH(
    TRUE(),
    ISBLANK(jobs_final[min_experience_years]), BLANK(),
    jobs_final[min_experience_years] <= 2, "0-2 yrs",
    jobs_final[min_experience_years] <= 5, "3-5 yrs",
    "6+ yrs"
)
```

## Limitations

- This is a **snapshot sample** from one source, not a census of the Indian job market.
- Postings per role reflect how many results were collected per search (three roles have exactly 137), so role counts are **not** a measure of demand. The share of recent postings is used instead.
- Salary is the **midpoint of the advertised range**, available for 43% of postings. 28 postings list only a maximum and are excluded from salary averages.
- The experience view uses only the **120 postings** that list both salary and experience.
- Skills are detected from posting text, so coverage is partial (357 of 717 postings, 50%). Business Analyst coverage is especially low (20 of 137).
- City analysis excludes postings with a blank or "Other" city.
- 39% of postings (281) are dated before 2026. "Recent" means posted in roughly the last 6 months before the data pull.

## Repository contents

```
├── README.md
├── India_Job_Market_Analysis.pbix
├── India_Job_Market_Dashboard.pdf
├── india_jobs_final_clean.csv
├── india_job_skills_717.csv
├── queries.sql
└── screenshots/
    ├── overview.png
    ├── skills_and_roles.png
    └── salary_and_location.png
```

To explore the report, download `India_Job_Market_Analysis.pbix` and open it in Power BI Desktop (free).

## About me

**Shalu**: aspiring data analyst (SQL, Excel, Power BI).
[LinkedIn](linkedin.com/in/shalu-8628461aa) · Shalupaul2201@email.com
