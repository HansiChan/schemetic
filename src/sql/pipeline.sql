-- ============================================
-- Flink SQL 测试脚本 - 不依赖外部表
-- 用于验证 Paimon + S3 环境配置
-- ============================================

SET 'execution.runtime-mode' = 'batch';

-- 创建 Paimon Catalog
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

-- ============================================
-- 测试 1: 创建简单表并写入数据
-- ============================================
CREATE TABLE IF NOT EXISTS test_simple (
    id INT,
    name STRING,
    value DOUBLE,
    created_at TIMESTAMP(3),
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'bucket' = '1'
);

-- 插入测试数据
INSERT INTO test_simple VALUES
    (1, 'Alice', 100.5, TIMESTAMP '2026-01-01 10:00:00'),
    (2, 'Bob', 200.75, TIMESTAMP '2026-01-01 11:00:00'),
    (3, 'Charlie', 300.25, TIMESTAMP '2026-01-01 12:00:00');

-- ============================================
-- 测试 2: 使用 VALUES 生成数据并创建表
-- ============================================
CREATE TABLE IF NOT EXISTS test_generated AS
SELECT 
    id,
    CONCAT('user_', CAST(id AS STRING)) AS username,
    id * 10.5 AS score,
    CURRENT_TIMESTAMP AS created_at
FROM (VALUES (1), (2), (3), (4), (5)) AS t(id);

-- ============================================
-- 测试 3: 日期时间函数测试
-- ============================================
CREATE TABLE IF NOT EXISTS test_datetime AS
SELECT
    1 AS id,
    CURRENT_DATE AS today,
    CURRENT_TIMESTAMP AS now,
    CURRENT_DATE - INTERVAL '1' DAY AS yesterday,
    CURRENT_DATE + INTERVAL '7' DAY AS next_week,
    CAST(CURRENT_TIMESTAMP AS DATE) AS date_only;

-- ============================================
-- 测试 4: 字符串和数学函数测试
-- ============================================
CREATE TABLE IF NOT EXISTS test_functions AS
SELECT
    1 AS id,
    UPPER('hello world') AS upper_str,
    LOWER('HELLO WORLD') AS lower_str,
    SUBSTRING('abcdefg', 2, 3) AS sub_str,
    CHAR_LENGTH('测试字符串') AS str_len,
    TRIM('  spaces  ') AS trimmed,
    ABS(-100) AS abs_val,
    ROUND(3.14159, 2) AS rounded,
    POWER(2, 10) AS power_val,
    MOD(17, 5) AS mod_val;

-- ============================================
-- 测试 5: 聚合函数测试
-- ============================================
CREATE TABLE IF NOT EXISTS test_aggregation AS
SELECT
    category,
    COUNT(*) AS cnt,
    SUM(amount) AS total,
    AVG(amount) AS average,
    MIN(amount) AS min_val,
    MAX(amount) AS max_val
FROM (
    VALUES 
        ('A', 100),
        ('A', 200),
        ('A', 150),
        ('B', 300),
        ('B', 250)
) AS t(category, amount)
GROUP BY category;

-- ============================================
-- 测试 6: 窗口函数测试
-- ============================================
CREATE TABLE IF NOT EXISTS test_window AS
SELECT
    id,
    category,
    amount,
    SUM(amount) OVER (PARTITION BY category ORDER BY id) AS running_total,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY amount DESC) AS rank_in_category,
    LAG(amount, 1) OVER (PARTITION BY category ORDER BY id) AS prev_amount
FROM (
    VALUES 
        (1, 'A', 100),
        (2, 'A', 200),
        (3, 'A', 150),
        (4, 'B', 300),
        (5, 'B', 250)
) AS t(id, category, amount);

-- ============================================
-- 测试完成！
-- 可以用 SELECT * FROM test_xxx 验证结果
-- ============================================
