\set ON_ERROR_STOP on

\pset pager off
\pset null '[null]'

\echo Row counts
SELECT 'uuid' AS key_strategy, count(*) AS rows
FROM pk_benchmark.event_log_uuid
UNION ALL
SELECT 'bigserial' AS key_strategy, count(*) AS rows
FROM pk_benchmark.event_log_bigserial
ORDER BY key_strategy;

\echo Relation size summary
WITH rels AS (
    SELECT
        'uuid' AS key_strategy,
        'pk_benchmark.event_log_uuid'::regclass AS relid
    UNION ALL
    SELECT
        'bigserial' AS key_strategy,
        'pk_benchmark.event_log_bigserial'::regclass AS relid
)
SELECT
    key_strategy,
    pg_size_pretty(pg_relation_size(relid)) AS table_size,
    pg_relation_size(relid) AS table_bytes,
    pg_size_pretty(pg_indexes_size(relid)) AS indexes_size,
    pg_indexes_size(relid) AS indexes_bytes,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
    pg_total_relation_size(relid) AS total_bytes
FROM rels
ORDER BY key_strategy;

\echo Index size details
SELECT
    tablename,
    indexname,
    pg_size_pretty(
        pg_relation_size((quote_ident(schemaname) || '.' || quote_ident(indexname))::regclass)
    ) AS index_size,
    pg_relation_size((quote_ident(schemaname) || '.' || quote_ident(indexname))::regclass) AS index_bytes
FROM pg_indexes
WHERE schemaname = 'pk_benchmark'
  AND tablename IN ('event_log_uuid', 'event_log_bigserial')
ORDER BY tablename, indexname;

\echo Sequence size details
SELECT
    c.relname AS sequence_name,
    pg_size_pretty(pg_relation_size(c.oid)) AS sequence_size,
    pg_relation_size(c.oid) AS sequence_bytes
FROM pg_class AS c
JOIN pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname = 'pk_benchmark'
  AND c.relkind = 'S'
ORDER BY c.relname;

\echo Constraint check examples
SELECT conrelid::regclass AS table_name, conname, contype
FROM pg_constraint
WHERE connamespace = 'pk_benchmark'::regnamespace
ORDER BY conrelid::regclass::text, conname;
