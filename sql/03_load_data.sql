\set ON_ERROR_STOP on

\if :{?row_count}
\else
\set row_count 100000
\endif

\if :{?load_bigserial_first}
\else
\set load_bigserial_first false
\endif

\timing on

TRUNCATE TABLE
    pk_benchmark.event_log_uuid,
    pk_benchmark.event_log_bigserial
RESTART IDENTITY;

\echo Preparing :row_count deterministic source rows
CREATE TEMP TABLE benchmark_events AS
SELECT
    ((gs - 1) % 10000) + 1 AS actor_id,
    (ARRAY['created', 'updated', 'deleted', 'viewed'])[1 + ((gs - 1) % 4)::integer] AS event_type,
    TIMESTAMPTZ '2026-01-01 00:00:00+00'
        + ((gs - 1) % 2592000) * INTERVAL '1 second' AS occurred_at,
    (ARRAY['api', 'worker', 'import'])[1 + ((gs - 1) % 3)::integer] AS source_system
FROM generate_series(1, :row_count::bigint) AS gs;

\if :load_bigserial_first

\echo Loading :row_count rows into pk_benchmark.event_log_bigserial first
INSERT INTO pk_benchmark.event_log_bigserial (
    actor_id,
    event_type,
    occurred_at,
    source_system
)
SELECT
    actor_id,
    event_type,
    occurred_at,
    source_system
FROM benchmark_events;

\echo Loading :row_count rows into pk_benchmark.event_log_uuid second
INSERT INTO pk_benchmark.event_log_uuid (
    actor_id,
    event_type,
    occurred_at,
    source_system
)
SELECT
    actor_id,
    event_type,
    occurred_at,
    source_system
FROM benchmark_events;

\else

\echo Loading :row_count rows into pk_benchmark.event_log_uuid first
INSERT INTO pk_benchmark.event_log_uuid (
    actor_id,
    event_type,
    occurred_at,
    source_system
)
SELECT
    actor_id,
    event_type,
    occurred_at,
    source_system
FROM benchmark_events;

\echo Loading :row_count rows into pk_benchmark.event_log_bigserial second
INSERT INTO pk_benchmark.event_log_bigserial (
    actor_id,
    event_type,
    occurred_at,
    source_system
)
SELECT
    actor_id,
    event_type,
    occurred_at,
    source_system
FROM benchmark_events;

\endif

VACUUM (ANALYZE) pk_benchmark.event_log_uuid;
VACUUM (ANALYZE) pk_benchmark.event_log_bigserial;
