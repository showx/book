-- Example 6-1. Basic Create Table
CREATE TABLE logs(
log_id serial primary key
, user_name varchar(50)
, description text
, log_ts timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE INDEX idx_logs_log_ts ON logs USING btree(log_ts);

-- Example 6-2. Defining an inherited table
CREATE TABLE logs_2011(primary key(log_id)) INHERITS (logs);
CREATE INDEX idx_logs_2011_log_ts ON logs USING btree(log_ts);
ALTER TABLE logs_2011
ADD CONSTRAINT chk_y2011 CHECK (log_ts BETWEEN '2011-01-01 00:00:00'::timestamptz AND
'2011-12-31 23:59:59'::timestamptz);

-- Example 6-3. Defining an unlogged table
CREATE UNLOGGED TABLE web_sessions(
session_id text PRIMARY KEY
, add_ts timestamp
, upd_ts timestamp
, session_state xml);

-- Example 6-4. Using multi-row consructor to insert data
INSERT INTO logs_2011(user_name, description, log_ts)
VALUES ('robe', 'logged in', '2011-01-10 10:15 AM'),
('lhsu', 'logged out', '2011-01-11 10:20 AM');

-- example: Creating lookup and insert non-numeric data
CREATE SCHEMA census;
set search_path=census;
CREATE TABLE lu_tracts(tract_id varchar(11)
, tract_long_id varchar(25)
, tract_name varchar(150)
, CONSTRAINT pk_lu_tracts PRIMARY KEY (tract_id)
);
INSERT INTO lu_tracts(
  tract_id, tract_long_id, tract_name)
SELECT geo_id2, geo_id, geo_display
 FROM staging.factfinder_import
 WHERE geo_id2 ~ '^[0-9]+';