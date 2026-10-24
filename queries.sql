-- ============================================================
-- India Job Market Analysis
-- Database: india_job_analysis
-- Tables: jobs_final, job_skills
-- ============================================================


-- ============================================================
-- 1. CREATE TABLES
-- ============================================================

-- Create the final job postings table with 14 columns.
CREATE TABLE jobs_final (
    job_id BIGINT PRIMARY KEY,
    role VARCHAR(100),
    title TEXT,
    company TEXT,
    city VARCHAR(100),
    salary_min_lpa NUMERIC(10,2),
    salary_max_lpa NUMERIC(10,2),
    min_experience_years NUMERIC(4,1),
    posted_date DATE,
    has_skills BOOLEAN,
    has_salary BOOLEAN,
    salary_mid_lpa NUMERIC(10,2),
    is_recent BOOLEAN,
    skills_required TEXT
);

-- Create the normalized job-skills table with one row per job-skill pair.
CREATE TABLE job_skills (
    job_id BIGINT NOT NULL,
    skill VARCHAR(100) NOT NULL,
    PRIMARY KEY (job_id, skill),
    FOREIGN KEY (job_id) REFERENCES jobs(job_id)
);


-- ============================================================
-- 2. LOAD DATA
-- ============================================================

-- No original COPY or INSERT statement is available in the conversation record.
-- Previously, the CSV files were imported through pgAdmin.
-- Jobs CSV: path/to/file.csv
-- Skills CSV: path/to/file.csv


-- ============================================================
-- 3. DATA VALIDATION
-- ============================================================

-- Count all job rows and unique job IDs; expected: 717 for jobs_final.
SELECT
    COUNT(*) AS total_jobs,
    COUNT(DISTINCT job_id) AS unique_job_ids
FROM jobs_final;


-- Count jobs with non-empty skill text and jobs without it.
SELECT
    COUNT(*) AS total_jobs,
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(skills_required), '') IS NOT NULL
    ) AS jobs_with_nonempty_skills,
    COUNT(*) FILTER (
        WHERE skills_required IS NULL
           OR TRIM(skills_required) = ''
    ) AS jobs_without_skills_text
FROM jobs_final;


-- Count job-skill rows, jobs represented, and unique skills.
-- Previously observed: 977 rows, 357 jobs, 49 unique skills.
SELECT
    COUNT(*) AS total_job_skill_rows,
    COUNT(DISTINCT job_id) AS jobs_with_skill_records,
    COUNT(DISTINCT skill) AS unique_skills
FROM job_skills;


-- Find duplicate job IDs in the jobs table; expected: no rows.
SELECT
    job_id,
    COUNT(*) AS occurrences
FROM jobs_final
GROUP BY job_id
HAVING COUNT(*) > 1;


-- Check missing values in important job fields.
SELECT
    COUNT(*) FILTER (
        WHERE role IS NULL OR TRIM(role) = ''
    ) AS missing_role,
    COUNT(*) FILTER (
        WHERE title IS NULL OR TRIM(title) = ''
    ) AS missing_title,
    COUNT(*) FILTER (
        WHERE posted_date IS NULL
    ) AS missing_posted_date,
    COUNT(*) FILTER (
        WHERE salary_min_lpa IS NULL
    ) AS missing_salary_min,
    COUNT(*) FILTER (
        WHERE salary_max_lpa IS NULL
    ) AS missing_salary_max,
    COUNT(*) FILTER (
        WHERE skills_required IS NULL
           OR TRIM(skills_required) = ''
    ) AS missing_skills_text
FROM jobs_final;


-- Find jobs where the minimum salary exceeds the maximum salary; expected: no rows.
SELECT
    job_id,
    salary_min_lpa,
    salary_max_lpa
FROM jobs_final
WHERE salary_min_lpa IS NOT NULL
  AND salary_max_lpa IS NOT NULL
  AND salary_min_lpa > salary_max_lpa;


-- Check the earliest and latest posting dates.
SELECT
    MIN(posted_date) AS earliest_posting,
    MAX(posted_date) AS latest_posting
FROM jobs_final;


-- Count jobs with at least one available salary value; previously observed: 308.
SELECT COUNT(*) AS jobs_with_salary
FROM jobs_final
WHERE salary_min_lpa IS NOT NULL
   OR salary_max_lpa IS NOT NULL;


-- Find job-skill rows that do not match a job in jobs_final; expected: no rows.
SELECT
    js.job_id,
    js.skill
FROM job_skills AS js
LEFT JOIN jobs_final AS j
    ON j.job_id = js.job_id
WHERE j.job_id IS NULL;


-- Find duplicate job-skill pairs; expected: no rows.
SELECT
    job_id,
    skill,
    COUNT(*) AS occurrences
FROM job_skills
GROUP BY job_id, skill
HAVING COUNT(*) > 1;


-- ============================================================
-- 4. ANALYSIS QUERIES
-- ============================================================

-- Count job postings by role, from highest to lowest.
SELECT
    role,
    COUNT(*) AS job_count
FROM jobs
GROUP BY role
ORDER BY job_count DESC;


-- Compare salary availability and average salary values by role.
SELECT
    role,
    COUNT(*) FILTER (
        WHERE salary_min_lpa IS NOT NULL
           OR salary_max_lpa IS NOT NULL
    ) AS jobs_with_salary,
    ROUND(AVG(salary_min_lpa), 2) AS avg_min_salary_lpa,
    ROUND(AVG(salary_max_lpa), 2) AS avg_max_salary_lpa,
    ROUND(AVG(salary_mid_lpa), 2) AS avg_mid_salary_lpa
FROM jobs
GROUP BY role
ORDER BY avg_mid_salary_lpa DESC;


-- Count job postings by city, excluding missing city values.
SELECT
    city,
    COUNT(*) AS job_count
FROM jobs
WHERE city IS NOT NULL
GROUP BY city
ORDER BY job_count DESC;


-- Count distinct jobs mentioning each skill.
SELECT
    skill,
    COUNT(DISTINCT job_id) AS job_count
FROM job_skills
GROUP BY skill
ORDER BY job_count DESC;


-- Count distinct jobs mentioning each skill within each role.
SELECT
    j.role,
    js.skill,
    COUNT(DISTINCT js.job_id) AS job_count
FROM jobs AS j
JOIN job_skills AS js
    ON j.job_id = js.job_id
GROUP BY j.role, js.skill
ORDER BY j.role, job_count DESC;


-- Summarize minimum, maximum, and average experience by role.
SELECT
    role,
    COUNT(min_experience_years) AS jobs_with_experience,
    ROUND(AVG(min_experience_years), 2) AS avg_experience_years,
    MIN(min_experience_years) AS min_experience_years,
    MAX(min_experience_years) AS max_experience_years
FROM jobs
GROUP BY role
ORDER BY avg_experience_years DESC;


-- Count job postings by company, excluding missing company names.
SELECT
    company,
    COUNT(*) AS job_count
FROM jobs
WHERE company IS NOT NULL
GROUP BY company
ORDER BY job_count DESC;


-- Compare minimum and maximum advertised salaries by role.
SELECT
    role,
    MIN(salary_min_lpa) AS lowest_min_salary_lpa,
    MAX(salary_max_lpa) AS highest_max_salary_lpa,
    ROUND(AVG(salary_min_lpa), 2) AS avg_min_salary_lpa,
    ROUND(AVG(salary_max_lpa), 2) AS avg_max_salary_lpa
FROM jobs
GROUP BY role
ORDER BY avg_max_salary_lpa DESC;


-- Count recent job postings by role.
SELECT
    role,
    COUNT(*) AS recent_job_count
FROM jobs
WHERE is_recent = TRUE
GROUP BY role
ORDER BY recent_job_count DESC;


-- Compare jobs with and without salary information by role.
SELECT
    role,
    COUNT(*) AS total_jobs,
    COUNT(*) FILTER (
        WHERE salary_min_lpa IS NOT NULL
           OR salary_max_lpa IS NOT NULL
    ) AS jobs_with_salary,
    COUNT(*) FILTER (
        WHERE salary_min_lpa IS NULL
          AND salary_max_lpa IS NULL
    ) AS jobs_without_salary
FROM jobs
GROUP BY role
ORDER BY total_jobs DESC;


-- Compare job demand across roles and cities.
SELECT
    role,
    city,
    COUNT(*) AS job_count
FROM jobs
WHERE city IS NOT NULL
GROUP BY role, city
ORDER BY role, job_count DESC;


-- Compare salary midpoint with minimum experience by role.
SELECT
    role,
    min_experience_years,
    ROUND(AVG(salary_mid_lpa), 2) AS avg_salary_mid_lpa,
    COUNT(*) AS job_count
FROM jobs
WHERE salary_mid_lpa IS NOT NULL
  AND min_experience_years IS NOT NULL
GROUP BY role, min_experience_years
ORDER BY role, min_experience_years;


-- Count distinct jobs per skill within each role, sorted by popularity.
SELECT
    j.role,
    js.skill,
    COUNT(DISTINCT js.job_id) AS job_count
FROM jobs AS j
JOIN job_skills AS js
    ON j.job_id = js.job_id
GROUP BY j.role, js.skill
ORDER BY j.role, job_count DESC;


-- Count job postings by role and company.
SELECT
    role,
    company,
    COUNT(*) AS job_count
FROM jobs
WHERE company IS NOT NULL
GROUP BY role, company
ORDER BY role, job_count DESC;


-- Count recent job postings by city.
SELECT
    city,
    COUNT(*) AS recent_job_count
FROM jobs
WHERE city IS NOT NULL
  AND is_recent = TRUE
GROUP BY city
ORDER BY recent_job_count DESC;