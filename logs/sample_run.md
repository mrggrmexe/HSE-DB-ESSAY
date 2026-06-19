# Пример запуска эксперимента

Команды рассчитаны на PostgreSQL и `psql`.

```bash
createdb hse_db_essay
psql -d hse_db_essay -v row_count=100000 -f sql/run_all.sql
```

Для более показательного сравнения можно увеличить объем данных:

```bash
psql -d hse_db_essay -v row_count=1000000 -f sql/run_all.sql
```

Для проверки влияния порядка загрузки:

```bash
psql -d hse_db_essay -v row_count=100000 -v load_bigserial_first=true -f sql/run_all.sql
```

В выводе нужно сохранить:

- время вставки в `event_log_uuid`;
- время вставки в `event_log_bigserial`;
- размер таблиц;
- суммарный размер индексов;
- размер первичного ключа и индекса `(actor_id, id)`;
- планы `EXPLAIN (ANALYZE, BUFFERS)`.

Интерпретация не должна опираться на один прогон. Для аккуратного вывода
сценарий стоит выполнить несколько раз, меняя порядок вставки или перезапуская
тестовую базу, потому что кэш ОС и PostgreSQL может заметно влиять на время.

## Локальный smoke-test

Скрипты были проверены локально на PostgreSQL 18.3 через временный кластер
PostgreSQL. Объем проверки: `row_count=100000`.

Ключевые фрагменты обычного порядка загрузки:

```text
Preparing 100000 deterministic source rows
SELECT 100000
Time: 61.543 ms

Loading 100000 rows into pk_benchmark.event_log_uuid first
INSERT 0 100000
Time: 2191.526 ms

Loading 100000 rows into pk_benchmark.event_log_bigserial second
INSERT 0 100000
Time: 1894.692 ms
```

Фрагменты обратного порядка загрузки:

```text
Preparing 100000 deterministic source rows
SELECT 100000
Time: 188.235 ms

Loading 100000 rows into pk_benchmark.event_log_bigserial first
INSERT 0 100000
Time: 1656.826 ms

Loading 100000 rows into pk_benchmark.event_log_uuid second
INSERT 0 100000
Time: 1302.558 ms
```

```text
 key_strategy | table_size | table_bytes | indexes_size | indexes_bytes | total_size | total_bytes
--------------+------------+-------------+--------------+---------------+------------+-------------
 bigserial    | 8248 kB    |     8445952 | 8744 kB      |       8953856 | 17 MB      |    17440768
 uuid         | 9096 kB    |     9314304 | 12 MB        |      12378112 | 21 MB      |    21733376
```

```text
      tablename      |              indexname              | index_size | index_bytes
---------------------+-------------------------------------+------------+-------------
 event_log_bigserial | event_log_bigserial_actor_id_id_idx | 4328 kB    |     4431872
 event_log_bigserial | event_log_bigserial_occurred_at_idx | 2208 kB    |     2260992
 event_log_bigserial | event_log_bigserial_pkey            | 2208 kB    |     2260992
 event_log_uuid      | event_log_uuid_actor_id_id_idx      | 5568 kB    |     5701632
 event_log_uuid      | event_log_uuid_occurred_at_idx      | 2208 kB    |     2260992
 event_log_uuid      | event_log_uuid_pkey                 | 4312 kB    |     4415488
```

```text
       sequence_name        | sequence_size | sequence_bytes
----------------------------+---------------+----------------
 event_log_bigserial_id_seq | 8192 bytes    |           8192
```

`sql/run_all.sql` также выполняет `sql/05_explain_queries.sql`. Пример UUID
lookup после выбора sample key:

```text
Index Scan using event_log_uuid_pkey on event_log_uuid e
  Index Cond: (id = '7ad4437c-b2c8-4d30-b3ca-509ed17b8b16'::uuid)
```

Вывод по smoke-test: размерные метрики стабильно показывают более крупные
индексы у UUID-варианта, а время вставки заметно зависит от порядка и прогрева
среды. Поэтому время `INSERT` в работе рассматривается как сравниваемая
метрика, но не как единственное доказательство.
