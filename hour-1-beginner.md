autoscale: true


[.footer: Slide 1 / 65]

## PostgreSQL for the Absolute Beginner
<br>
<br>
## Hour 1 of PostgreSQL Training Day

---


[.footer: Slide 2 / 65]

## About This Training

- Full day PostgreSQL training
- 6 hours with 90 minute lunch break
- Sample code and exercises available
- 3 experts to answer your questions

---


[.footer: Slide 3 / 65]

## Today's Agenda

| Hour | Topic |
|------|-------|
| 1 | PostgreSQL for the Absolute Beginner |
| 2 | Getting Started with SQL in Postgres |
| 3 | Postgres DBA Basics |
| 4 | Postgres Troubleshooting |
| 5 | Configuration and Performance Tuning |
| 6 | Query Tuning |

---


[.footer: Slide 4 / 65]

## Training Materials

[.column]

All slides, exercises, and Docker setup:

### github.com/elizabeth-christensen/postgres-full-day-training

Sample database:

### github.com/ryanbooz/bluebox


[.column]

postgres.app for macs will create a psql connection



---


[.footer: Slide 5 / 65]

## Let's Get Connected!

## Setup Overview

1. Start PostgreSQL (Docker)
2. Install a psql client
3. Connect and load sample data
4. Verify everything works

~10-15 minutes

---


[.footer: Slide 6 / 65]

## Prerequisites

You need **Docker Desktop** installed and running

- **Mac/Windows**: docker.com/products/docker-desktop
- **Linux**: Docker Engine + Docker Compose

Verify it's working:

```bash
docker --version
docker compose version
```

---


[.footer: Slide 7 / 65]

## Step 1: Clone the Repository

```bash
## Clone the training repo
git clone https://github.com/Snowflake-Labs/postgres-full-day-training.git

## Navigate into the folder
cd postgres-full-day-training
```

Or download as ZIP from GitHub if you don't have git.

---

[.footer: Slide 8 / 65]

## Step 2: Start PostgreSQL

```bash
## Start PostgreSQL container
docker compose up -d

## Verify it's running
docker ps
```

You should see `postgres-training` running on port 5432.

```
CONTAINER ID   IMAGE                    STATUS         PORTS
abc123...      postgis/postgis:18-3.6   Up 10 seconds  0.0.0.0:5432->5432/tcp
```

---

[.footer: Slide 9 / 65]

## Step 3: Install a psql Client

You need a way to connect to PostgreSQL. Choose one:

[.column]

Mac
- `brew install libpq` (client only)
- `brew install postgresql@18`
- Postgres.app (includes psql)

Windows
- PostgreSQL installer (postgresql.org)
- pgAdmin (standalone)

[.column]

Linux
- `apt install postgresql-client`
- `yum install postgresql`

Cross-Platform GUIs
- pgAdmin
- DBeaver
- TablePlus
- Azure Data Studio
- Beekeeper Studio

---

[.footer: Slide 10 / 65]

## Mac: Homebrew (Recommended)

```bash
## Install just the client tools (no server)
brew install libpq

## Add to your PATH
echo 'export PATH="/opt/homebrew/opt/libpq/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

## Verify
psql --version
```

Alternative: Install Postgres.app and use its bundled psql.

---

[.footer: Slide 11 / 65]

## Windows / GUI Users

**pgAdmin** is a great option:

1. Download from pgadmin.org
2. Add a new server connection:
   - Host: `localhost`
   - Port: `5432`
   - Username: `postgres`
   - Password: `training`

pgAdmin includes a Query Tool that works like psql.

---

[.footer: Slide 12 / 65]

## Step 4: Connect to PostgreSQL

```bash
## Connect using psql
psql postgresql://postgres:training@localhost:5432/postgres
```

You should see:

```
psql (18.x)
Type "help" for help.

postgres=#
```

You're connected! 🎉

---

[.footer: Slide 13 / 65]

## Step 5: Create Database and Load Bluebox

From psql, create the database:

```sql
CREATE DATABASE bluebox;
\c bluebox
CREATE EXTENSION postgis;
```

Then exit psql (`\q`) and load the data:

```bash
## Download Bluebox files
curl -LO https://raw.githubusercontent.com/ryanbooz/bluebox/main/bluebox_schema.sql
curl -LO https://raw.githubusercontent.com/ryanbooz/bluebox/main/bluebox_data.sql.gz
gunzip bluebox_data.sql.gz

## Load schema and data
psql postgresql://postgres:training@localhost:5432/bluebox -f bluebox_schema.sql
psql postgresql://postgres:training@localhost:5432/bluebox -f bluebox_data.sql
```

---

[.footer: Slide 14 / 65]

## Step 6: Verify Your Setup

Connect to the bluebox database:

```bash
psql postgresql://postgres:training@localhost:5432/bluebox
```

Run a test query:

```sql
SELECT COUNT(*) FROM bluebox.film;
```

```
 count 
-------
  7836
```

If you see 7836 films, you're all set! ✅

---

[.footer: Slide 15 / 65]

## Troubleshooting: Last Resort

If you can't install psql locally, use Docker:

```bash
## Connect via docker exec
docker exec -it postgres-training psql -U postgres -d bluebox
```

This works but isn't ideal for learning psql workflows.

**Common issues:**
- Docker not running → Start Docker Desktop
- Port conflict → Check if another Postgres is using 5432
- Permission denied → Run Docker Desktop as admin (Windows)

---

[.footer: Slide 16 / 65]

## Why Postgres?

[.column]

- **Open Source** - No licensing costs, ever
- **Standards compliant** - SQL standard with powerful extensions
- **Mature** - 35+ years of active development
- **Extensible** - PostGIS, pgvector, time series, and more
- **Reliable** - ACID compliant, battle-tested
- **Career** - Most loved database by developers

[.column]

![inline](diagrams/stack-overflow-survey-2025.png)

---

[.footer: Slide 17 / 65]

## Running Postgres

## Where can you run Postgres?

---

[.footer: Slide 18 / 65]

## Running Postgres - Options

[.column]

### Local
- **Docker** (what we're using today)
- **Postgres.app** (macOS)
- **Homebrew** - `brew install postgresql@18`
- **Community packages** - postgresql.org/download

[.column]

### Cloud / Managed
- **AWS RDS** / Aurora
- **Azure Database**
- **Google Cloud SQL**
- **Crunchy Bridge** / Neon / Supabase

---

[.footer: Slide 19 / 65]

## Connecting to PostgreSQL

```bash
## Basic connection
psql -h localhost -p 5432 -U postgres -d bluebox

## Connection string format (what we've been using)
psql postgresql://postgres:training@localhost:5432/bluebox
```

Connection to remote locations
<br>
![inline 70%](diagrams/connection-strings.png)

---

[.footer: Slide 20 / 65]

## GUI Tools

[.column]

### pgAdmin
- Official GUI tool
- Web-based interface
- Free and open source

[.column]

### DBeaver
- Multi-database support
- ER diagrams
- Free community edition

^ Feel free to use your own tool here.

---

[.footer: Slide 21 / 65]

## psql Introduction

---

[.footer: Slide 22 / 65]

## psql - The Postgres CLI

The most powerful way to interact with Postgres

```
psql (18.x)
Type "help" for help.

bluebox=#
```

---

[.footer: Slide 23 / 65]

## Essential psql Commands

| Command | Description |
|---------|-------------|
| `\l` | List all databases |
| `\c dbname` | Connect to database |
| `\dt` | List tables |
| `\d tablename` | Describe table |
| `\dn` | List schemas |

* `\d` stands for "describe"

---

[.footer: Slide 24 / 65]

## More psql Commands

| Command | Description |
|---------|-------------|
| `\du` | List users/roles |
| `\di` | List indexes |
| `\df` | List functions |
| `\x` | Toggle expanded display |
| `\timing` | Toggle query timing |

---

[.footer: Slide 25 / 65]

## psql Tips

```sql
-- Edit in your favorite editor
\e

-- Run SQL from a file
\i /path/to/script.sql

-- Output to file
\o output.txt
SELECT * FROM film;
\o

-- Get help on SQL commands
\h CREATE TABLE
```

---

[.footer: Slide 26 / 65]

## psql Formatting

Default output can be messy when columns are wide:

```
 id | name  | email           | long_column_that_wraps...
----+-------+-----------------+---------------------------
  1 | Alice | alice@test.com  | this text wraps and becomes
    |       |                 | hard to read
```

**Solution**: `\x auto` - automatically switches to record format!

---

[.footer: Slide 27 / 65]

## Expanded Display: \x auto

```sql
\x auto   -- Let psql decide (recommended!)
\x on     -- Always record
\x off    -- Always horizontal (default)
```

Expanded view shows one column per line:

```
-[ RECORD 1 ]----------------
id    | 1
name  | Alice
email | alice@test.com
```

**Pro tip**: Put `\x auto` in your `~/.psqlrc` file!

---

[.footer: Slide 28 / 65]

## Pretty Unicode Borders

```sql
\pset linestyle unicode
\pset border 2
```

```
┌────┬───────┬─────┐
│ id │ name  │ age │
├────┼───────┼─────┤
│  1 │ Alice │  30 │
│  2 │ Bob   │  25 │
└────┴───────┴─────┘
```

Makes output much easier to read!

---

[.footer: Slide 29 / 65]

## More Useful psql Settings

```sql
\timing              -- Show query execution time
\conninfo            -- Show current connection info
\pset pager off      -- Turn off page-by-page scrolling
```

```
bluebox=# \timing
Timing is on.
bluebox=# SELECT COUNT(*) FROM film;
 count 
-------
  7836
(1 row)
Time: 2.145 ms

bluebox=# \conninfo
You are connected to database "bluebox" as user "postgres" 
on host "localhost" at port "5432".
```

---

[.footer: Slide 30 / 65]

## Making NULLs Visible

By default, NULL displays as blank - easy to confuse with empty string!

```sql
\pset null '☘️'
SELECT title, budget FROM bluebox.film WHERE budget IS NULL LIMIT 3;
```

```
     title      | budget 
----------------+--------
 Dune: Part Two |    ☘️
 Migration      |    ☘️
 Mean Girls     |    ☘️
```

Now you can clearly see which values are actually NULL!

---

[.footer: Slide 31 / 65]

## Users and Permissions

---

[.footer: Slide 32 / 65]

## Postgres Roles

In Postgres, **users** and **groups** are both **roles**

```sql
-- Create a user (role with login)
CREATE ROLE app_user WITH LOGIN PASSWORD 'secure_password';

-- Create a group (role without login)
CREATE ROLE readonly;
```

---

[.footer: Slide 33 / 65]

## Role Attributes

```sql
CREATE ROLE app_user WITH 
  LOGIN 
  PASSWORD 'secure_password'
  CREATEDB 
  CREATEROLE;
```

Common attributes:
- `LOGIN` / `NOLOGIN`
- `SUPERUSER` / `NOSUPERUSER`
- `CREATEDB` / `NOCREATEDB`
- `CREATEROLE` / `NOCREATEROLE`

---

[.footer: Slide 34 / 65]

## ⚠️ Password Security: Don't Do This!

```sql
-- This works, BUT the password may be logged in plaintext!
CREATE ROLE app_user WITH PASSWORD 'secret123!' LOGIN;
```

If you use `pg_audit` or any query logging, the plaintext password is now in your logs! 😱

**Instead, use `\password`:**

```
\password app_user
Enter new password: ********
Enter it again: ********
```

`\password` hashes the password **before** sending to the server

---

[.footer: Slide 35 / 65]

## Password Hashing in Postgres

Postgres uses **SCRAM-SHA-256** (since v10):

- **Hashing ≠ Encryption** - Hashing is one-way, cannot be reversed
- **Salt** - Random data added before hashing, so identical passwords produce different hashes
- **Challenge-Response** - Password never sent in plaintext over the network

Hashed passwords are stored in `pg_authid.rolpassword`

---

[.footer: Slide 36 / 65]

## Password Best Practices

✅ **Use `\password`** to create/change passwords (pre-hashes)

✅ **Use SCRAM-SHA-256** (default since Postgres 10)

✅ **Migrate old MD5 passwords** - MD5 is deprecated in Postgres 18!

✅ **Enforce password policies** - length, complexity, rotation

```sql
-- Check if you have old MD5 passwords
SELECT rolname, rolpassword 
FROM pg_authid 
WHERE rolpassword LIKE 'md5%';
```

---

[.footer: Slide 37 / 65]

## Granting Privileges

```sql
-- Grant connection to database
GRANT CONNECT ON DATABASE bluebox TO app_user;

-- Grant schema usage
GRANT USAGE ON SCHEMA bluebox TO app_user;

-- Grant table privileges
GRANT SELECT ON ALL TABLES IN SCHEMA bluebox TO app_user;

-- Grant specific privileges
GRANT SELECT, INSERT, UPDATE ON bluebox.rental TO app_user;
```

---

[.footer: Slide 38 / 65]

## Manage Privileges with Groups

Roles can be members of other roles (like groups!)

```sql
-- Create a group role for data analytics team
CREATE ROLE data_analytics NOLOGIN;

-- Grant read access on Bluebox to the group
GRANT CONNECT ON DATABASE bluebox TO data_analytics;
GRANT USAGE ON SCHEMA bluebox TO data_analytics;
GRANT SELECT ON ALL TABLES IN SCHEMA bluebox TO data_analytics;
```

---

[.footer: Slide 39 / 65]

## Grant Users Role Membership

```sql
-- Create a user for an analyst
CREATE ROLE maria LOGIN;
\password maria

-- Add maria to the data_analytics group
GRANT data_analytics TO maria;

-- Maria now inherits all permissions from data_analytics!
```

---

[.footer: Slide 40 / 65]

## View Role Memberships

```sql
\du
```

```
                             List of roles
   Role name    |         Attributes          |   Member of    
----------------+-----------------------------+----------------
 data_analytics | Cannot login                | {}
 maria          |                             | {data_analytics}
 app_user       |                             | {}
 postgres       | Superuser, Create role, ... | {}
```

Maria is a member of `data_analytics` - she inherits its permissions!

---

[.footer: Slide 41 / 65]

## Schemas

![inline](diagrams/instance-cluster-schema.png)

---

[.footer: Slide 42 / 65]

## What is a Schema?

A **schema** is a namespace within a database

- Organizes database objects (tables, views, functions)
- Provides access control boundaries
- Avoids naming conflicts

---

[.footer: Slide 43 / 65]

## Default Schema

```sql
-- The default schema is 'public'
CREATE TABLE my_table (id int);

-- Same as:
CREATE TABLE public.my_table (id int);
```

---

[.footer: Slide 44 / 65]

## Creating Schemas

```sql
-- Bluebox already has its schema, but you could create more:
CREATE SCHEMA reporting;

-- Then create tables in that schema
CREATE TABLE reporting.daily_stats (...);
```

Bluebox uses `bluebox` schema to organize all its tables

---

[.footer: Slide 45 / 65]

## Schema Search Path

```sql
-- View current search path
SHOW search_path;
-- Output: "$user", public

-- Set search path
SET search_path TO bluebox, public;

-- Now queries will look in bluebox first
SELECT * FROM film;  -- Same as bluebox.film
```

---

[.footer: Slide 46 / 65]

## Bluebox Schema

The Bluebox database uses a `bluebox` schema with 17 tables:

```sql
SET search_path TO bluebox, public;
\dt
```

```
 Schema  |        tablename        
---------+-------------------------
 bluebox | customer      (186,740 rows)
 bluebox | film          (7,836 rows)
 bluebox | person        (258,772 rows)
 bluebox | store         (196 rows)
 ...and 13 more tables
```

---

[.footer: Slide 47 / 65]

## ALTER User Search Path

```sql
-- Set search path
ALTER USER maria SET search_path TO bluebox, public;

-- From next login, queries will look in bluebox first
SELECT * FROM film;  -- Same as bluebox.film
```

---

[.footer: Slide 48 / 65]

## Object and Data Types

---

[.footer: Slide 49 / 65]

## Database Objects

- **Tables** - Store data in rows and columns
- **Views** - Saved queries that act like tables
- **Indexes** - Speed up data retrieval
- **Sequences** - Auto-incrementing number generators
- **Functions** - Reusable SQL/procedural code

---

[.footer: Slide 50 / 65]

## Common Data Types

[.column]

Numeric
- `INTEGER` / `BIGINT`
- `NUMERIC(p,s)`
- `REAL` / `DOUBLE`

Character
- `TEXT` (preferred)
- `VARCHAR(n)`

[.column]

Date/Time
- `DATE` / `TIME`
- `TIMESTAMP`
- `TIMESTAMPTZ` ⭐
- `INTERVAL`

Other
- `BOOLEAN`
- `UUID`
- `JSON` / `JSONB`
- array of any other type, e.g. `int[]`, `text[]`

---

[.footer: Slide 51 / 65]

## ⏰ Time: Use TIMESTAMPTZ!

`TIMESTAMP` vs `TIMESTAMPTZ` - always prefer **TIMESTAMPTZ**

```sql
-- TIMESTAMP: No timezone info (dangerous!)
CREATE TABLE events (event_time TIMESTAMP);

-- TIMESTAMPTZ: Stores in UTC, converts on display ✓
CREATE TABLE events (event_time TIMESTAMPTZ);
```

```sql
-- What time is it?
SELECT NOW();  -- 2026-01-16 10:30:00-08
```

TIMESTAMPTZ handles daylight saving automatically!

---

[.footer: Slide 52 / 65]

## 💰 Use NUMERIC, Not MONEY!

```sql
-- DON'T use the MONEY type
price MONEY  -- ❌ Locale-dependent, rounding issues

-- DO use NUMERIC for currency
price NUMERIC(10,2)  -- ✓ Exact precision, no surprises
```

Bluebox uses `NUMERIC` for payment amounts:

```sql
SELECT amount FROM bluebox.payment LIMIT 3;
```

```
 amount 
--------
   1.99
   1.99
   3.98
```

NUMERIC stores exact values - no floating point errors!

---

[.footer: Slide 53 / 65]

## 🎯 Custom Data Types: ENUM

Postgres lets you create custom types!

Bluebox uses an ENUM for MPAA ratings:

```sql
CREATE TYPE mpaa_rating AS ENUM (
    'G', 'PG', 'PG-13', 'R', 'NC-17', 'NR'
);

-- Used in the film table
SELECT title, rating FROM bluebox.film 
WHERE rating = 'PG-13' LIMIT 3;
```

```
                 title                 | rating 
---------------------------------------+--------
 Are You There God? It's Me, Margaret. | PG-13
 Love at First Sight                   | PG-13
 Batman Returns                        | PG-13
```

---

[.footer: Slide 54 / 65]

## Creating a Table

Let's add a customer reviews feature to Bluebox!

```sql
CREATE TABLE bluebox.customer_review (
    review_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES bluebox.customer(customer_id),
    film_id BIGINT REFERENCES bluebox.film(film_id),
    rating SMALLINT CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

[.footer: Slide 55 / 65]

## Add Yourself as a Customer

```sql
-- Add yourself to the Bluebox database
INSERT INTO bluebox.customer 
    (customer_id, store_id, full_name, email)
VALUES (
    (SELECT MAX(customer_id) + 1 FROM bluebox.customer),
    1,                          -- Store #1
    'Your Name Here',           -- Your name!
    'you@example.com'
)
RETURNING customer_id, full_name;
```

```
 customer_id |   full_name    
-------------+----------------
      205026 | Your Name Here   ← Save this ID!
```

Note: this is a great use of the Postgres feature `RETURNING`

---

[.footer: Slide 56 / 65]

## Find Films to Review

```sql
-- Find some popular films to review
SELECT film_id, title FROM bluebox.film 
WHERE title IN ('The Dark Knight', 'Inception', 
                'Interstellar', 'Dune: Part Two');
```

```
 film_id |      title      
---------+-----------------
     155 | The Dark Knight
   27205 | Inception
  157336 | Interstellar
  693134 | Dune: Part Two
```

---

[.footer: Slide 57 / 65]

## Insert Your Reviews

Replace `205026` with your actual customer_id!

```sql
-- Use YOUR customer_id from the previous step!
INSERT INTO bluebox.customer_review 
    (customer_id, film_id, rating, review_text)
VALUES 
    (205026, 155, 5, 'Heath Ledger was incredible!'),
    (205026, 27205, 5, 'Mind-bending! Had to watch twice'),
    (205026, 693134, 5, 'Even better than the first Dune!');
```


---

[.footer: Slide 58 / 65]

## Querying Your Reviews

```sql
-- See your reviews with a JOIN
SELECT c.full_name, f.title, r.rating, 
       LEFT(r.review_text, 30) as review
FROM bluebox.customer_review r
JOIN bluebox.customer c ON r.customer_id = c.customer_id
JOIN bluebox.film f ON r.film_id = f.film_id
ORDER BY r.created_at DESC;
```

```
   full_name    |      title      | rating |           review            
----------------+-----------------+--------+-----------------------------
 Your Name      | The Dark Knight |      5 | Heath Ledger was incredible
 Your Name      | Inception       |      5 | Mind-bending! Had to watch 
 Your Name      | Dune: Part Two  |      5 | Even better than the first
```

---

[.footer: Slide 59 / 65]

## Bluebox Tables

```sql
\d bluebox.film
```

```
      Column       |    Type     |          Description
-------------------+-------------+---------------------------
 film_id           | bigint      | Primary key
 title             | text        | Movie title
 overview          | text        | Plot summary
 release_date      | date        | Release date
 vote_average      | real        | TMDB rating (0-10)
 popularity        | real        | TMDB popularity score
 budget            | bigint      | Production budget
 revenue           | bigint      | Box office revenue
```

---

[.footer: Slide 60 / 65]

## Extensions

---

[.footer: Slide 61 / 65]

## What are Extensions?

Extensions add functionality to Postgres:

- New data types
- New functions
- New operators
- New index types

---

[.footer: Slide 62 / 65]

## Contrib Extensions

Bundled with Postgres - just `CREATE EXTENSION name;`

| Extension | What it does |
|-----------|--------------|
| `pg_stat_statements` | Track query performance statistics |
| `pg_trgm` | Fuzzy text search with trigrams |
| `citext` | Case-insensitive text type |
| `hstore` | Key-value store in a column |
| `btree_gist` | GiST index support for common types |
| `uuid-ossp` | Generate UUIDs |
| `tablefunc` | Crosstab / pivot table queries |
| `pgcrypto` | Encryption functions |

^ Run `SELECT * FROM pg_available_extensions;` to see all available extensions

---

[.footer: Slide 63 / 65]

## Popular Third-Party Extensions

- **PostGIS** - Geospatial data and queries
- **pgvector** - Vector similarity search (AI/ML)
- **TimescaleDB** - Time-series data
- **pg_cron** - Job scheduling
- **HypoPG** - Hypothetical indexes

---

[.footer: Slide 64 / 65]

## Hour 1 Summary

- ✅ Setup: Docker, psql client, Bluebox loaded
- ✅ Why Postgres is a great choice
- ✅ Connecting with psql and GUI tools
- ✅ Essential psql commands
- ✅ Users, roles, and permissions
- ✅ Schemas for organization
- ✅ Data types and table creation
- ✅ Extensions for added functionality

---

[.footer: Slide 65 / 65]

## Questions?

<br>
<br>

## Next: Getting Started with SQL in Postgres
