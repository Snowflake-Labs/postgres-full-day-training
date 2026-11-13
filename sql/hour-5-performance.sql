-- ============================================================
-- SQL examples from: hour-5-performance
-- ============================================================
-- --------------------------
-- Slide 9: Shared Buffers
-- --------------------------

-- Check current value
SHOW shared_buffers;

-- Set in postgresql.conf
shared_buffers = 8GB   -- For 32GB RAM system

-- Requires restart to change


-- ---------------------------------
-- Slide 11: Effective Cache Size
-- ---------------------------------

-- Set higher = planner prefers index scans
-- Set lower = planner prefers sequential scans

effective_cache_size = 16GB  -- For 32GB system


-- ----------------------------
-- Slide 12: Cache Hit Ratio
-- ----------------------------

SELECT datname, blks_hit, blks_read,
    ROUND(100.0 * blks_hit / 
          NULLIF(blks_hit + blks_read, 0), 2) as hit_ratio
FROM pg_stat_database WHERE datname = 'bluebox';


-- ----------------------------------------
-- Slide 13: What's in the Buffer Cache?
-- ----------------------------------------

-- Install pg_buffercache extension
CREATE EXTENSION pg_buffercache;

-- See what's cached
SELECT 
    c.relname,
    count(*) as buffers,
    pg_size_pretty(count(*) * 8192) as size
FROM pg_buffercache b
JOIN pg_class c ON b.relfilenode = c.relfilenode
WHERE b.reldatabase = (SELECT oid FROM pg_database WHERE datname = current_database())
GROUP BY c.relname
ORDER BY count(*) DESC
LIMIT 10;


-- ------------------------------
-- Slide 15: What is work_mem?
-- ------------------------------

SHOW work_mem;  -- Default: 4MB


-- ------------------------------
-- Slide 16: work_mem Behavior
-- ------------------------------

-- This query might use 4 x work_mem
SELECT f.title, p.name, COUNT(*) as appearances
FROM bluebox.film f
JOIN bluebox.film_cast fc ON f.film_id = fc.film_id  -- hash join
JOIN person p ON fc.person_id = p.person_id  -- hash join
GROUP BY f.title, p.name                      -- hash aggregate
ORDER BY appearances DESC;                    -- sort


-- -----------------------------
-- Slide 17: Setting work_mem
-- -----------------------------

-- Global setting (conservative)
work_mem = 64MB

-- Increase for specific session
SET work_mem = '256MB';
-- Run complex analytical query
RESET work_mem;


-- --------------------------------------
-- Slide 18: When to Increase work_mem
-- --------------------------------------

-- Check for disk sorts
EXPLAIN (ANALYZE, BUFFERS) SELECT ...

-- Look for:
-- Sort Method: external merge  ← disk sort, increase work_mem
-- Sort Method: quicksort      ← memory sort, good!


-- ------------------------------------
-- Slide 19: Maintenance Work Memory
-- ------------------------------------

maintenance_work_mem = 1GB

-- Affects:
-- VACUUM
-- CREATE INDEX
-- ALTER TABLE ADD FOREIGN KEY


-- ------------------------
-- Slide 20: Checkpoints
-- ------------------------

-- How often (in WAL segments or time)
checkpoint_timeout = 15min
max_wal_size = 4GB

-- How fast (spread I/O over time)
checkpoint_completion_target = 0.9


-- -------------------------------------------
-- Slide 22: Sequential vs Random I/O Costs
-- -------------------------------------------

-- Tells planner relative costs
seq_page_cost = 1.0      -- Sequential read cost
random_page_cost = 4.0   -- Random read cost (default)

-- For SSDs, reduce random_page_cost
random_page_cost = 1.1   -- SSDs have nearly equal random/sequential


-- ------------------------------------
-- Slide 24: Parallel Query Defaults
-- ------------------------------------

-- Check current settings
SHOW max_parallel_workers_per_gather;  -- Default: 2
SHOW max_parallel_workers;             -- Default: 8
SHOW max_worker_processes;             -- Default: 8
SHOW parallel_tuple_cost;              -- Default: 0.1
SHOW min_parallel_table_scan_size;     -- Default: 8MB


-- ----------------------------------------
-- Slide 25: Increasing Parallel Workers
-- ----------------------------------------

-- Allow more workers per query (requires restart for max_worker_processes)
ALTER SYSTEM SET max_worker_processes = 16;
ALTER SYSTEM SET max_parallel_workers = 12;

-- More workers per query operation
ALTER SYSTEM SET max_parallel_workers_per_gather = 4;

-- Apply changes
SELECT pg_reload_conf();


-- --------------------------------------
-- Slide 26: Parallel Query in EXPLAIN
-- --------------------------------------

EXPLAIN ANALYZE SELECT count(*) FROM bluebox.film;


-- --------------------------------------------------
-- Slide 32: Check Dead Tuples Waiting for Cleanup
-- --------------------------------------------------

SELECT 
    relname AS table_name,
    n_dead_tup AS dead_rows,
    n_live_tup AS live_rows,
    last_autovacuum,
    last_vacuum
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC
LIMIT 10;


-- ---------------------------------
-- Slide 33: Tuning: Scale Factor
-- ---------------------------------

-- Vacuum more frequently (10% instead of 20%)
ALTER TABLE big_table 
SET (autovacuum_vacuum_scale_factor = 0.1);

-- Or use absolute threshold for huge tables
ALTER TABLE huge_table 
SET (autovacuum_vacuum_threshold = 1000000);


-- ------------------------------------------
-- Slide 34: Tuning: Cost-Based Throttling
-- ------------------------------------------

-- Increase delay between vacuum operations (default 2ms)
ALTER TABLE busy_table 
SET (autovacuum_vacuum_cost_delay = '5ms');

-- Lower cost limit = more frequent pauses
ALTER TABLE busy_table 
SET (autovacuum_vacuum_cost_limit = 100);


-- --------------------------------------
-- Slide 35: Transaction ID Wraparound
-- --------------------------------------

-- Check oldest unfrozen transaction age
SELECT datname, age(datfrozenxid) 
FROM pg_database 
ORDER BY age DESC;


-- -------------------------------
-- Slide 41: Table Partitioning
-- -------------------------------

-- Example: partitioning payment by date
CREATE TABLE bluebox.payment_partitioned (
    payment_id SERIAL,
    payment_date TIMESTAMPTZ NOT NULL,
    customer_id INT,
    amount NUMERIC(5,2)
) PARTITION BY RANGE (payment_date);

CREATE TABLE payment_2024 PARTITION OF bluebox.payment_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE payment_2025 PARTITION OF bluebox.payment_partitioned
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');


-- --------------------------------
-- Slide 45: Where Settings Live
-- --------------------------------

-- Show config file locations
SHOW config_file;     -- Main: postgresql.conf
SHOW hba_file;        -- Access: pg_hba.conf
SHOW data_directory;  -- Data directory


-- ------------------------------
-- Slide 46: Changing Settings
-- ------------------------------

SELECT name, setting, unit, context
FROM pg_settings WHERE name IN 
('shared_buffers', 'work_mem', 'effective_cache_size');


-- -----------------------------
-- Slide 47: Applying Changes
-- -----------------------------

-- Reload configuration (no downtime)
SELECT pg_reload_conf();

-- Or from command line
pg_ctl reload -D /var/lib/postgresql/17/main

-- Check pending changes
SELECT name, setting, pending_restart
FROM pg_settings
WHERE pending_restart;


-- -------------------------
-- Slide 48: ALTER SYSTEM
-- -------------------------

-- Modify settings without editing file
ALTER SYSTEM SET work_mem = '128MB';

-- Written to postgresql.auto.conf
-- Takes effect after reload (or restart)
SELECT pg_reload_conf();

-- Reset to default
ALTER SYSTEM RESET work_mem;


-- -----------------------------------------
-- Slide 49: Starting Point Configuration
-- -----------------------------------------

-- For a dedicated 32GB database server:

shared_buffers = 8GB
effective_cache_size = 24GB
work_mem = 64MB
maintenance_work_mem = 2GB

max_connections = 200
max_wal_size = 4GB
checkpoint_timeout = 15min

random_page_cost = 1.1        -- SSD
effective_io_concurrency = 200 -- SSD
