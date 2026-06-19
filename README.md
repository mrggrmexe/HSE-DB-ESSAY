# HSE DB Essay: UUID против BIGSERIAL

Репозиторий содержит готовый комплект для сдачи по заданию курса
«Конструирование баз данных».

Основной файл для сдачи:

-- `essay.md` — единый документ с логами работы с AI, независимой верификацией, техническим приложением и финальным текстом
  доклада.

Вспомогательные артефакты:

-- `sql/00_setup.sql` — подготовка расширения и схемы эксперимента.

-- `sql/01_ddl_uuid.sql` — DDL таблицы `event_log_uuid`.

-- `sql/02_ddl_bigserial.sql` — DDL таблицы `event_log_bigserial`.

-- `sql/03_load_data.sql` — массовая вставка одинакового набора событий.

-- `sql/04_metrics.sql` — запросы размеров таблиц и индексов.

-- `sql/05_explain_queries.sql` — дополнительные `EXPLAIN`-запросы.

-- `sql/run_all.sql` — полный сценарий запуска через `psql`.

-- `diagrams/experiment_er.mmd` — Mermaid-схема экспериментальной модели.

-- `logs/sample_run.md` — команды запуска и место для фиксации результата.

## Проверка

Требуется PostgreSQL с расширением `pgcrypto`.

```bash
createdb hse_db_essay
psql -d hse_db_essay -v row_count=100000 -f sql/run_all.sql
```

Параметр `row_count` можно увеличить, например до `1000000`, если нужна
более показательная нагрузка.

Чтобы проверить влияние порядка загрузки на время вставки, выполните второй
прогон с обратным порядком:

```bash
psql -d hse_db_essay -v row_count=100000 -v load_bigserial_first=true -f sql/run_all.sql
```
