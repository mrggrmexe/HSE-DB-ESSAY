\set ON_ERROR_STOP on

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DROP SCHEMA IF EXISTS pk_benchmark CASCADE;
CREATE SCHEMA pk_benchmark;

COMMENT ON SCHEMA pk_benchmark IS
    'Experiment comparing UUID and BIGSERIAL primary keys for event_log tables.';
