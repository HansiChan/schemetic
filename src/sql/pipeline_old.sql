-- Create and select catalog
CREATE CATALOG ${CATALOG} WITH (
  'type' = 'paimon',
  'warehouse' = '${WAREHOUSE}',
  's3.endpoint' = '${S3_ENDPOINT}',
  's3.access-key' = '${S3_ACCESS_KEY}',
  's3.secret-key' = '${S3_SECRET_KEY}',
  's3.path.style.access' = '${S3_PATH_STYLE}'
);

USE CATALOG ${CATALOG};

-- Create and use database
CREATE DATABASE IF NOT EXISTS ${DATABASE};
USE ${DATABASE};

-- Target table
CREATE TABLE IF NOT EXISTS page_views_per_minute (
  minute_start TIMESTAMP(0),
  page STRING,
  cnt BIGINT,
  PRIMARY KEY (minute_start, page) NOT ENFORCED
) PARTITIONED BY (minute_start) WITH (
  'bucket' = '3',
  'file.format' = 'parquet'
);

-- Source table (datagen)
CREATE TEMPORARY TABLE clicks (
  user_id BIGINT,
  page STRING,
  ts TIMESTAMP(3),
  WATERMARK FOR ts AS ts - INTERVAL '5' SECOND
) WITH (
  'connector' = 'datagen',
  'rows-per-second' = '5'
);

-- Pipeline insert
INSERT INTO page_views_per_minute
SELECT
  CAST(TUMBLE_START(ts, INTERVAL '1' MINUTE) AS TIMESTAMP(0)) AS minute_start,
  page,
  COUNT(*) AS cnt
FROM clicks
GROUP BY
  TUMBLE(ts, INTERVAL '1' MINUTE),
  page;
