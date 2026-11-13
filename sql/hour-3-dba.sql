-- ============================================================
-- SQL examples from: hour-3-dba
-- ============================================================
-- ---------------------------------
-- Slide 24: 🔧 Hands-On: View WAL
-- ---------------------------------

-- Current WAL position (Log Sequence Number)
SELECT pg_current_wal_lsn();
--  0/3A8B9D0

-- WAL stats
SELECT wal_records, wal_bytes, 
       pg_size_pretty(wal_bytes) as wal_size
FROM pg_stat_wal;


-- -------------------------------------------
-- Slide 47: Step 1: Prepare the Subscriber
-- -------------------------------------------

CREATE DATABASE bluebox;
\c bluebox
CREATE SCHEMA bluebox;

-- Create custom mpaa_rating type
CREATE TYPE mpaa_rating AS ENUM (
    'G',
    'PG',
    'PG-13',
    'R',
    'NC-17',
    'NR'
);

[.column]

-- Create the table structure (no data)
CREATE TABLE bluebox.film (
    film_id bigint primary key,
    title text,
    overview text,
    release_date date,
    genre_ids integer[],
    original_language text,
    rating mpaa_rating,
    popularity real,
    vote_count integer,
    vote_average real,
    budget bigint,
    revenue bigint,
    runtime integer,
    fulltext tsvector
);


-- ---------------------------------------
-- Slide 48: Step 2: Create Publication
-- ---------------------------------------

-- Create publication for the film table
CREATE PUBLICATION film_pub FOR TABLE bluebox.film;

-- Verify
SELECT * FROM pg_publication;
SELECT * FROM pg_publication_tables;


-- ----------------------------------------
-- Slide 49: Step 3: Create Subscription
-- ----------------------------------------

-- Subscribe to the publisher (use Docker service name)
CREATE SUBSCRIPTION film_sub
CONNECTION 'host=postgres port=5432 dbname=bluebox user=postgres password=training'
PUBLICATION film_pub;

-- Check status
SELECT * FROM pg_stat_subscription;


-- ----------------------------------------
-- Slide 50: Step 4: Watch It Replicate!
-- ----------------------------------------

-- On subscriber (5433)
SELECT count(*) FROM bluebox.film;
-- Should match publisher!

SELECT title, vote_average 
FROM bluebox.film 
ORDER BY vote_average DESC 
LIMIT 5;


-- ------------------------------------------
-- Slide 51: Step 5: Test Live Replication
-- ------------------------------------------

-- Update a film's rating
UPDATE bluebox.film 
SET vote_average = 9.9 
WHERE title = 'The Dark Knight';

SELECT title, vote_average 
FROM bluebox.film 
WHERE title = 'The Dark Knight';
-- vote_average is now 9.9!


-- ---------------------------------------
-- Slide 52: Monitor Replication Status
-- ---------------------------------------

-- On subscriber: check replication lag
SELECT 
    subname,
    received_lsn,
    latest_end_lsn,
    last_msg_receipt_time
FROM pg_stat_subscription;

-- On publisher: see active replication slots
SELECT slot_name, active, restart_lsn 
FROM pg_replication_slots;


-- --------------------------------
-- Slide 53: Clean Up (Optional)
-- --------------------------------

-- On subscriber: drop subscription
DROP SUBSCRIPTION film_sub;

-- On publisher: drop publication
DROP PUBLICATION film_pub;


-- --------------------------------
-- Slide 55: Connection Settings
-- --------------------------------

-- postgresql.conf
max_connections = 100        -- Maximum concurrent connections
reserved_connections = 0 -- pg_use_reserved_connections
superuser_reserved_connections = 3

-- View current connections
SELECT count(*) FROM pg_stat_activity;

-- View connection details
SELECT usename, application_name, client_addr, state
FROM pg_stat_activity
WHERE datname = 'bluebox';


-- -----------------------------------
-- Slide 56: The Connection Problem
-- -----------------------------------

SELECT pid, usename, state, query_start, state_change
FROM pg_stat_activity 
WHERE state = 'idle'
ORDER BY state_change;


-- ------------------------------------
-- Slide 61: PgBouncer Admin Console
-- ------------------------------------

-- Show all available commands
SHOW HELP;


-- ------------------------------------
-- Slide 62: Monitor Pool Statistics
-- ------------------------------------

-- From PgBouncer admin console
SHOW POOLS;


-- ----------------------------
-- Slide 65: What is Vacuum?
-- ----------------------------

-- Manual vacuum
VACUUM bluebox.rental;

-- Vacuum with analysis
VACUUM ANALYZE bluebox.rental;

-- Full vacuum (rewrites table, locks!)
VACUUM FULL bluebox.rental;


-- -----------------------
-- Slide 66: Autovacuum
-- -----------------------

-- Key settings
autovacuum = on
autovacuum_vacuum_threshold = 50
autovacuum_vacuum_scale_factor = 0.2

-- 20% of rows changed + 50 = trigger vacuum


-- -----------------------------------
-- Slide 67: Monitoring Table Bloat
-- -----------------------------------

-- Check dead tuples
SELECT 
    schemaname,
    relname,
    n_dead_tup,
    n_live_tup,
    round(n_dead_tup::numeric / NULLIF(n_live_tup, 0) * 100, 2) as dead_pct
FROM pg_stat_user_tables
WHERE n_dead_tup > 0
ORDER BY n_dead_tup DESC
LIMIT 10;


-- ----------------------------------
-- Slide 68: Table and Index Bloat
-- ----------------------------------

-- pg_bloat_check or pgstattuple extension
CREATE EXTENSION pgstattuple;

SELECT * FROM pgstattuple('bluebox.rental');


-- ----------------------------------
-- Slide 69: Disk Space Monitoring
-- ----------------------------------

SELECT pg_size_pretty(pg_database_size('bluebox'));
-- Result: 876 MB

SELECT relname, pg_size_pretty(pg_total_relation_size(relid)) as size
FROM pg_stat_user_tables WHERE schemaname = 'bluebox'
ORDER BY pg_total_relation_size(relid) DESC LIMIT 5;


-- -------------------------------------------
-- Slide 74: 🔧 Hands-On: Range Partitioning
-- -------------------------------------------

-- Create partitioned table
CREATE TABLE bluebox.payment_history (
    payment_id SERIAL,
    payment_date TIMESTAMPTZ NOT NULL,
    customer_id INT,
    amount NUMERIC(5,2)
) PARTITION BY RANGE (payment_date);

-- Create partitions for each year
CREATE TABLE payment_2024 PARTITION OF bluebox.payment_history
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE payment_2025 PARTITION OF bluebox.payment_history
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');


-- ----------------------------------------------
-- Slide 75: Insert & Query Partitioned Tables
-- ----------------------------------------------

-- Insert goes to correct partition automatically
INSERT INTO bluebox.payment_history (payment_date, customer_id, amount)
VALUES ('2025-06-15', 12345, 4.99);

-- Query the parent - PostgreSQL prunes partitions
EXPLAIN SELECT * FROM bluebox.payment_history
WHERE payment_date >= '2025-01-01';
-- Shows: Scans only payment_2025!


-- --------------------------------
-- Slide 76: Managing Partitions
-- --------------------------------

-- Add a new partition (before data arrives!)
CREATE TABLE payment_2026 PARTITION OF bluebox.payment_history
    FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');

-- Archive old data: detach and drop
ALTER TABLE bluebox.payment_history 
    DETACH PARTITION payment_2024;
DROP TABLE payment_2024;  -- or archive to cold storage
