-- ============================================================
-- SQL examples from: hour-6-query-tuning
-- ============================================================
-- ----------------------------
-- Slide 4: What is EXPLAIN?
-- ----------------------------

EXPLAIN SELECT * FROM bluebox.film WHERE vote_average > 8;


-- ---------------------------
-- Slide 5: EXPLAIN Options
-- ---------------------------

-- Basic plan (estimated only)
EXPLAIN SELECT * FROM bluebox.film WHERE vote_average > 8;

-- With actual execution times
EXPLAIN ANALYZE SELECT * FROM bluebox.film WHERE vote_average > 8;

-- With buffer/IO statistics
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM bluebox.film WHERE vote_average > 8;

-- All the details in text format
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) 
SELECT * FROM bluebox.film WHERE vote_average > 8;


-- ----------------------------------
-- Slide 6: EXPLAIN Output Formats
-- ----------------------------------

-- Default text format
EXPLAIN (FORMAT TEXT) SELECT * FROM bluebox.film LIMIT 5;

-- JSON - great for programmatic parsing
EXPLAIN (FORMAT JSON) SELECT * FROM bluebox.film LIMIT 5;

-- YAML - human readable structured output
EXPLAIN (FORMAT YAML) SELECT * FROM bluebox.film LIMIT 5;

-- XML - for XML tooling
EXPLAIN (FORMAT XML) SELECT * FROM bluebox.film LIMIT 5;


-- --------------------------------
-- Slide 7: EXPLAIN YAML Example
-- --------------------------------

EXPLAIN (ANALYZE, FORMAT YAML) 
SELECT title, vote_average FROM bluebox.film WHERE vote_average > 8;


-- ---------------------------
-- Slide 9: EXPLAIN ANALYZE
-- ---------------------------

EXPLAIN ANALYZE 
SELECT * FROM bluebox.film WHERE vote_average > 8;


-- ------------------------------------------
-- Slide 10: Warning About EXPLAIN ANALYZE
-- ------------------------------------------

-- This will DELETE your data!
EXPLAIN ANALYZE DELETE FROM bluebox.customer;

-- Use ROLLBACK for data-modifying queries
BEGIN;
EXPLAIN ANALYZE DELETE FROM bluebox.customer;
ROLLBACK;


-- ---------------------------------
-- Slide 11: EXPLAIN with BUFFERS
-- ---------------------------------

EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM bluebox.film WHERE vote_average > 8;


-- ------------------------------------------
-- Slide 17: Join Operations - Nested Loop
-- ------------------------------------------

EXPLAIN SELECT f.title, p.name FROM bluebox.film f
JOIN bluebox.film_cast fc ON f.film_id = fc.film_id
JOIN bluebox.person p ON fc.person_id = p.person_id
WHERE f.film_id = 155;


-- ---------------------------------
-- Slide 21: Finding Slow Queries
-- ---------------------------------

-- Add to shared_preload_libraries
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';

-- Then create the extension
CREATE EXTENSION pg_stat_statements;


-- -----------------------------------------
-- Slide 22: Generate Some Query Activity
-- -----------------------------------------

-- Some fast queries
SELECT count(*) FROM bluebox.film;
SELECT title FROM bluebox.film WHERE vote_average > 8 LIMIT 10;
SELECT * FROM bluebox.customer LIMIT 5;

-- A slower query
SELECT f.title, count(*) as cast_count
FROM bluebox.film f
JOIN bluebox.film_cast fc ON f.film_id = fc.film_id
GROUP BY f.title
ORDER BY cast_count DESC LIMIT 10;

-- Run a few times to build up call counts
SELECT title FROM bluebox.film ORDER BY popularity DESC LIMIT 20;
SELECT title FROM bluebox.film ORDER BY popularity DESC LIMIT 20;
SELECT title FROM bluebox.film ORDER BY popularity DESC LIMIT 20;


-- --------------------------------------
-- Slide 23: Top Queries by Total Time
-- --------------------------------------

SELECT 
    LEFT(query, 60) as query,
    calls,
    ROUND(total_exec_time::numeric, 2) as total_ms,
    ROUND(mean_exec_time::numeric, 2) as avg_ms,
    ROUND((100 * total_exec_time / 
        SUM(total_exec_time) OVER ())::numeric, 2) as pct
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;


-- ----------------------------------------
-- Slide 24: Top Queries by Average Time
-- ----------------------------------------

SELECT 
    LEFT(query, 60) as query,
    calls,
    ROUND(mean_exec_time::numeric, 2) as avg_ms,
    ROUND(stddev_exec_time::numeric, 2) as stddev_ms
FROM pg_stat_statements
WHERE calls > 100  -- Exclude rare queries
ORDER BY mean_exec_time DESC
LIMIT 10;


-- ----------------------------------
-- Slide 25: Queries with Most I/O
-- ----------------------------------

SELECT 
    LEFT(query, 60) as query,
    calls,
    shared_blks_hit + shared_blks_read as total_blks,
    ROUND(100.0 * shared_blks_hit / 
        NULLIF(shared_blks_hit + shared_blks_read, 0), 2) as hit_pct
FROM pg_stat_statements
WHERE shared_blks_hit + shared_blks_read > 1000
ORDER BY shared_blks_read DESC
LIMIT 10;


-- -----------------------------
-- Slide 26: Reset Statistics
-- -----------------------------

-- Reset all stats (do periodically)
SELECT pg_stat_statements_reset();

-- Good practice: reset after deploying changes
-- Compare before/after performance


-- ------------------------------------------------
-- Slide 28: Setup: Make Sure Logging is Running
-- ------------------------------------------------

-- Check logging is on
SHOW logging_collector;  -- Should be 'on'


-- --------------------------------
-- Slide 29: Enable auto_explain
-- --------------------------------

-- Load the extension for this session
LOAD 'auto_explain';

-- Log plans for queries over 100ms (low for demo)
SET auto_explain.log_min_duration = '100ms';

-- Include actual execution times
SET auto_explain.log_analyze = on;


-- -----------------------------
-- Slide 30: Run a Slow Query
-- -----------------------------

-- This should trigger auto_explain (takes > 100ms)
SELECT f.title, count(*) as cast_count
FROM bluebox.film f
JOIN bluebox.film_cast fc ON f.film_id = fc.film_id
JOIN bluebox.person p ON fc.person_id = p.person_id
GROUP BY f.title
ORDER BY cast_count DESC;


-- -----------------------------------
-- Slide 34: B-Tree Index (Default)
-- -----------------------------------

-- BEFORE: Check the plan without an index
EXPLAIN ANALYZE 
SELECT title FROM bluebox.film WHERE vote_average > 8;
-- Seq Scan on film  (cost=0.00..941.95)
--   Filter: (vote_average > 8)


-- --------------------------------
-- Slide 35: B-Tree Index: After
-- --------------------------------

-- Create the index
CREATE INDEX idx_film_vote_avg ON bluebox.film(vote_average);

-- AFTER: Check the plan with the index
EXPLAIN ANALYZE 
SELECT title FROM bluebox.film WHERE vote_average > 8;
-- Bitmap Index Scan on idx_film_vote_avg  (cost=0.29..8.42)
--   Index Cond: (vote_average > 8)


-- ----------------------
-- Slide 36: GIN Index
-- ----------------------

-- BEFORE: Full-text search without GIN index
EXPLAIN ANALYZE 
SELECT title FROM bluebox.film 
WHERE to_tsvector('english', overview) @@ to_tsquery('hero');
-- Seq Scan on film  (cost=0.00..2341.00)
--   Filter: (to_tsvector(...) @@ to_tsquery('hero'))


-- -----------------------------
-- Slide 37: GIN Index: After
-- -----------------------------

-- Create GIN index on the text vector
CREATE INDEX idx_film_overview_gin ON bluebox.film 
USING gin(to_tsvector('english', overview));

-- AFTER: Same query with GIN index
EXPLAIN ANALYZE 
SELECT title FROM bluebox.film 
WHERE to_tsvector('english', overview) @@ to_tsquery('hero');
-- Bitmap Index Scan on idx_film_overview_gin  (cost=0.12..8.14)


-- -----------------------
-- Slide 38: GiST Index
-- -----------------------

-- BEFORE: Spatial query without GiST index
EXPLAIN ANALYZE 
SELECT store_id FROM bluebox.store 
WHERE ST_DWithin(geog, 
    ST_MakePoint(-73.9857, 40.7484)::geography, 50000);
-- Seq Scan on store  (cost=0.00..125.00)
--   Filter: ST_DWithin(geog, ...)


-- ------------------------------
-- Slide 39: GiST Index: After
-- ------------------------------

-- Create GiST index on geography column
CREATE INDEX idx_store_geog ON bluebox.store USING gist(geog);

-- AFTER: Same spatial query with GiST
EXPLAIN ANALYZE 
SELECT store_id FROM bluebox.store 
WHERE ST_DWithin(geog, 
    ST_MakePoint(-73.9857, 40.7484)::geography, 50000);
-- Index Scan using idx_store_geog  (cost=0.14..8.16)


-- ------------------------------
-- Slide 42: Composite Indexes
-- ------------------------------

-- Index on multiple columns
CREATE INDEX idx_rental_cust_period 
    ON bluebox.rental(customer_id, lower(rental_period));

-- Column order matters!
-- This index helps:
WHERE customer_id = 1                                    ✓
WHERE customer_id = 1 AND lower(rental_period) > '2024' ✓
WHERE lower(rental_period) > '2024'                     ✗


-- ---------------------------------------
-- Slide 43: Covering Indexes (INCLUDE)
-- ---------------------------------------

-- Include non-key columns for index-only scans
CREATE INDEX idx_film_rating_cover 
    ON bluebox.film(vote_average) 
    INCLUDE (title, release_date);

-- Now this can be an index-only scan:
EXPLAIN SELECT title, release_date 
FROM bluebox.film 
WHERE vote_average > 8;


-- ----------------------------
-- Slide 44: Partial Indexes
-- ----------------------------

-- Index only rows you'll query (unreturned rentals)
CREATE INDEX idx_active_rentals 
    ON bluebox.rental(lower(rental_period)) 
    WHERE upper(rental_period) IS NULL;

-- Much smaller than full index
-- Only useful when WHERE matches
SELECT * FROM bluebox.rental 
WHERE upper(rental_period) IS NULL 
  AND lower(rental_period) > '2024-01-01';


-- -------------------------------
-- Slide 45: Expression Indexes
-- -------------------------------

-- Index on expression result
CREATE INDEX idx_film_year 
    ON bluebox.film(EXTRACT(year FROM release_date));

-- Index on calculated value (8.25% sales tax)
CREATE INDEX idx_payment_with_tax 
    ON bluebox.payment((amount * 1.0825));

-- Query must match expression exactly
SELECT * FROM bluebox.payment 
WHERE (amount * 1.0825) > 10.00;


-- ------------------------------------
-- Slide 47: Finding Missing Indexes
-- ------------------------------------

-- Tables with high sequential scan ratio
SELECT 
    schemaname, relname,
    seq_scan, idx_scan,
    ROUND(100.0 * seq_scan / NULLIF(seq_scan + idx_scan, 0), 2) as seq_pct
FROM pg_stat_user_tables
WHERE seq_scan + idx_scan > 1000
ORDER BY seq_scan DESC
LIMIT 10;


-- ---------------------------------------------------
-- Slide 48: HypoPG - Test Indexes Without Creating
-- ---------------------------------------------------

CREATE EXTENSION hypopg;


-- -----------------------------------------
-- Slide 49: HypoPG Example: Before Index
-- -----------------------------------------

-- First, check current plan
EXPLAIN SELECT * FROM bluebox.film WHERE vote_average > 8;


-- ------------------------------------------------------
-- Slide 50: HypoPG Example: Create Hypothetical Index
-- ------------------------------------------------------

-- Create a hypothetical index (no actual index created!)
SELECT * FROM hypopg_create_index(
  'CREATE INDEX ON bluebox.film(vote_average)'
);


-- ---------------------------------------------------------
-- Slide 51: HypoPG Example: Test With Hypothetical Index
-- ---------------------------------------------------------

-- Now check the plan again
EXPLAIN SELECT * FROM bluebox.film WHERE vote_average > 8;


-- --------------------------------------------
-- Slide 52: HypoPG Example: Composite Index
-- --------------------------------------------

-- Test a composite index
SELECT * FROM hypopg_create_index(
  'CREATE INDEX ON bluebox.rental(customer_id, lower(rental_period))'
);

-- Check if it helps this query
EXPLAIN SELECT * FROM bluebox.rental 
WHERE customer_id = 100 
  AND lower(rental_period) > '2024-01-01';


-- ----------------------------------------
-- Slide 53: HypoPG: Cleanup and Compare
-- ----------------------------------------

-- List all hypothetical indexes
SELECT * FROM hypopg_list_indexes;

-- Remove all hypothetical indexes
SELECT hypopg_reset();

-- If the index helped, create it for real!
CREATE INDEX idx_film_vote_avg ON bluebox.film(vote_average);


-- ---------------------------------
-- Slide 55: Pattern: N+1 Queries
-- ---------------------------------

-- GOOD: Single query
SELECT c.*, r.* 
FROM bluebox.customer c 
LEFT JOIN bluebox.rental r ON c.customer_id = r.customer_id;


-- ------------------------------
-- Slide 56: Pattern: SELECT *
-- ------------------------------

-- BAD: Gets all columns
SELECT * FROM bluebox.film WHERE vote_average > 8;

-- GOOD: Only needed columns
SELECT film_id, title, vote_average 
FROM bluebox.film 
WHERE vote_average > 8;


-- -------------------------------------------
-- Slide 57: Pattern: OFFSET for Pagination
-- -------------------------------------------

-- BAD: Must scan 10000 rows to skip them
SELECT * FROM bluebox.rental 
ORDER BY rental_id 
OFFSET 10000 LIMIT 20;

-- GOOD: Use index
SELECT * FROM bluebox.rental 
WHERE rental_id > 10000 
ORDER BY rental_id 
LIMIT 20;


-- --------------------------------------------------
-- Slide 58: Pattern: Functions on Indexed Columns
-- --------------------------------------------------

-- BAD: Can't use index efficiently  
SELECT * FROM bluebox.payment 
WHERE DATE(payment_date) = '2024-01-15';

-- GOOD: Can use index
SELECT * FROM bluebox.payment 
WHERE payment_date >= '2024-01-15' 
  AND payment_date < '2024-01-16';


-- -----------------------------------
-- Slide 59: Pattern: OR Conditions
-- -----------------------------------

-- Might not use index efficiently
SELECT * FROM bluebox.film 
WHERE vote_average = 8 OR EXTRACT(year FROM release_date) = 2024;

-- Each part can use its own index
SELECT * FROM bluebox.film WHERE vote_average = 8
UNION
SELECT * FROM bluebox.film WHERE EXTRACT(year FROM release_date) = 2024;
