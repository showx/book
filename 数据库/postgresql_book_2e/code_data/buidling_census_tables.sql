-- A lesson on dynamic inserts with DO
set search_path=census;
DROP TABLE IF EXISTS lu_fact_types;
CREATE TABLE lu_fact_types(fact_type_id serial
, category varchar(100)
, fact_subcats varchar(255)[], short_name varchar(50)
, CONSTRAINT pk_lu_fact_types PRIMARY KEY (fact_type_id) );
DO language plpgsql $$
DECLARE var_sql text;
BEGIN
var_sql := string_agg('INSERT INTO lu_fact_types( category,
fact_subcats, short_name )
SELECT ''Housing'', array_agg(s' || lpad(i::text,2,'0') || ') As fact_subcats
, ' || quote_literal('s' || lpad(i::text,2,'0') ) || ' As short_name
FROM staging.factfinder_import
WHERE s' || lpad(i::text,2,'0') || ' ~ ''^[a-zA-Z]+'' ', ';')
FROM generate_series(1,51) As i ;
var_sql := var_sql || ';' || 
  string_agg('INSERT INTO lu_fact_types( category,
fact_subcats, short_name )
SELECT ''Population'', array_agg(d' || lpad(i::text,3,'0') || ') As fact_subcats
, ' || quote_literal('d' || lpad(i::text,3,'0') ) || ' As short_name
FROM staging.pop_import
WHERE d' || lpad(i::text,3,'0') || ' ~ ''^[a-zA-Z]+'' ', ';')
FROM generate_series(1,17) As i ;
RAISE NOTICE '%', var_sql;
EXECUTE var_sql;
END$$;

-- No longer in book Building Facts
set search_path=census;
DROP TABLE IF EXISTS facts;
CREATE TABLE IF NOT EXISTS facts(fact_type_id integer
, tract_id varchar(11)
, yr integer
,val numeric(12,3)
, perc numeric(6,2)
, CONSTRAINT pk_facts PRIMARY KEY (fact_type_id, tract_id, yr) );
DO language plpgsql $$
DECLARE var_sql text;
BEGIN
var_sql := string_agg('INSERT INTO facts(
fact_type_id, tract_id, yr, val, perc )
  SELECT ' || ft.fact_type_id::text || ', geo_id2
 , 2011, s' || lpad(i::text,2,'0') || '::integer As val
 , CASE WHEN s' || lpad(i::text,2,'0')
|| '_perc LIKE ''(X%'' THEN NULL ELSE s' || lpad(i::text,2,'0')
|| '_perc END::numeric(5,2) As perc
FROM staging.factfinder_import AS ff
WHERE s' || lpad(i::text,2,'0') || ' ~ ''^[0-9]+'' ', ';')
FROM generate_series(1,51) As i
INNER JOIN lu_fact_types AS ft ON ( ('s' || lpad(i::text,2,'0')) = ft.short_name ) ;

var_sql := var_sql || ';' || string_agg('INSERT INTO facts(
fact_type_id, tract_id, yr, val)
  SELECT ' || ft.fact_type_id::text || ', geo_id2
 , 2011, d' || lpad(i::text,3,'0') || '::integer As val
FROM staging.pop_import AS ff
WHERE d' || lpad(i::text,3,'0') || ' ~ ''^[0-9]+'' ', ';')
FROM generate_series(1,17) As i
INNER JOIN lu_fact_types AS ft ON ( ('d' || lpad(i::text,3,'0')) = ft.short_name ) ;
EXECUTE var_sql;
END$$;

--builind lu_tracts --
set search_path=census;
CREATE TABLE IF NOT EXISTS lu_tracts(tract_id varchar(11), tract_long_id varchar(25)
, tract_name varchar(150)
, CONSTRAINT pk_lu_tracts PRIMARY KEY (tract_id));
INSERT INTO lu_tracts( tract_id, tract_long_id, tract_name)
SELECT geo_id2, geo_id, geo_display
FROM staging.factfinder_import
WHERE geo_id2 ~ '^[0-9]+';