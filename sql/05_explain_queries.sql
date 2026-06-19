\set ON_ERROR_STOP on

\if :{?actor_from}
\else
\set actor_from 100
\endif

\if :{?actor_to}
\else
\set actor_to 200
\endif

\pset pager off

\echo Symmetric UUID secondary-index range query
EXPLAIN (ANALYZE, BUFFERS, COSTS, SUMMARY, TIMING)
SELECT count(*)
FROM pk_benchmark.event_log_uuid
WHERE actor_id BETWEEN :actor_from AND :actor_to;

\echo Symmetric BIGSERIAL secondary-index range query
EXPLAIN (ANALYZE, BUFFERS, COSTS, SUMMARY, TIMING)
SELECT count(*)
FROM pk_benchmark.event_log_bigserial
WHERE actor_id BETWEEN :actor_from AND :actor_to;

\echo BIGSERIAL primary-key range locality example; not a symmetric UUID comparison
EXPLAIN (ANALYZE, BUFFERS, COSTS, SUMMARY, TIMING)
SELECT id, actor_id, event_type, occurred_at
FROM pk_benchmark.event_log_bigserial
WHERE id BETWEEN 10000 AND 10100
ORDER BY id;

\echo UUID primary-key point lookup example; not a symmetric BIGSERIAL range comparison
SELECT id AS uuid_lookup_id
FROM pk_benchmark.event_log_uuid
LIMIT 1
\gset

EXPLAIN (ANALYZE, BUFFERS, COSTS, SUMMARY, TIMING)
SELECT e.id, e.actor_id, e.event_type, e.occurred_at
FROM pk_benchmark.event_log_uuid AS e
WHERE e.id = :'uuid_lookup_id'::uuid;
