SET 'execution.runtime-mode' = 'batch';

CREATE CATALOG ${CATALOG} WITH (
  'type' = 'paimon',
  'warehouse' = '${WAREHOUSE}',
  's3.endpoint' = '${S3_ENDPOINT}',
  's3.access-key' = '${S3_ACCESS_KEY}',
  's3.secret-key' = '${S3_SECRET_KEY}',
  's3.path.style.access' = '${S3_PATH_STYLE}'
);

USE CATALOG ${CATALOG};
CREATE DATABASE IF NOT EXISTS ${DATABASE};
USE ${DATABASE};

CREATE TABLE IF NOT EXISTS dwd_tg_trading_date
AS
SELECT
    CAST(table_number AS INT) AS TableNum
    ,trading_date AS TradingDate
    ,CASE WHEN last_cms_trading_end_time IS NOT NULL
        THEN (
            CASE WHEN CAST(last_cms_trading_end_time AS DATE) BETWEEN (trading_date - INTERVAL '1' DAY) AND trading_date
                THEN (last_cms_trading_end_time + INTERVAL '0.001' SECOND)
                ELSE cms_trading_start_time
            END
        )
        ELSE cms_trading_start_time
    END AS Trading_start
    ,COALESCE(cms_trading_end_time, CURRENT_TIMESTAMP) AS Trading_end
    ,cms_trading_start_time AS CMS_Trading_start
    ,cms_trading_end_time AS CMS_Trading_end
    ,0 AS is_historical
FROM (
    SELECT
        *
        ,LAG(cms_trading_end_time, 1) OVER (PARTITION BY table_number ORDER BY trading_date ASC) AS last_cms_trading_end_time
    FROM (
        SELECT
            SUBSTRING(TRIM(TableName), CHAR_LENGTH(TRIM(TableName)) - 4) AS table_number
            ,CAST(TradingDate AS DATE) AS trading_date
            ,MIN(CASE WHEN TableTxnTypeCode = 'O' THEN TransactionDateTime END) AS cms_trading_start_time
            ,MAX(CASE WHEN TableTxnTypeCode = 'CL' THEN TransactionDateTime END) AS cms_trading_end_time
        FROM TableTrx
        WHERE
            TableTxnTypeCode IN ('O', 'CL')
            AND SUBSTRING(TableName, 1, CHAR_LENGTH(TableName) - 5) IN ('NCB', 'MD')
        GROUP BY
            TradingDate
            ,TableName
    ) t
) t1
WHERE
    (CASE WHEN last_cms_trading_end_time IS NOT NULL
        THEN (
            CASE WHEN CAST(last_cms_trading_end_time AS DATE) BETWEEN (trading_date - INTERVAL '1' DAY) AND trading_date
                THEN (last_cms_trading_end_time + INTERVAL '0.001' SECOND)
                ELSE cms_trading_start_time
            END
        )
        ELSE cms_trading_start_time
    END) IS NOT NULL;