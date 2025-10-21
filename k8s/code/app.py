import os
import sys
import traceback
import logging
from pyflink.table import EnvironmentSettings, TableEnvironment

logging.basicConfig(level=logging.INFO, format="[%(asctime)s] %(levelname)s %(message)s")
LOG = logging.getLogger("pyflink-paimon-demo")


def get_cfg():
    return {
        "warehouse": os.getenv("PAIMON_WAREHOUSE", "s3://paimon/"),
        "s3_endpoint": os.getenv("S3_ENDPOINT", "https://minio.minio-tenant.svc.cluster.local"),
        "s3_access_key": os.getenv("S3_ACCESS_KEY", ""),
        "s3_secret_key": os.getenv("S3_SECRET_KEY", ""),
        "s3_path_style": os.getenv("S3_PATH_STYLE", "true"),
        "catalog": os.getenv("PAIMON_CATALOG", "paimon_catalog"),
        "database": os.getenv("PAIMON_DATABASE", "demo"),
        "pipeline_name": os.getenv("PIPELINE_NAME", "pyflink-paimon-page-views-per-minute"),
        "ckpt_interval": os.getenv("CHECKPOINT_INTERVAL", "10 s"),
    }


def main():
    cfg = get_cfg()
    redacted = {k: ("***" if "KEY" in k else v) for k, v in cfg.items()}
    LOG.info("Starting with cfg: %s", redacted)

    t_env = TableEnvironment.create(EnvironmentSettings.in_streaming_mode())
    t_env.get_config().set("pipeline.name", cfg["pipeline_name"])
    t_env.get_config().set("execution.runtime-mode", "streaming")
    t_env.get_config().set("execution.checkpointing.interval", cfg["ckpt_interval"])

    t_env.get_config().set("fs.s3a.endpoint", cfg["s3_endpoint"])
    t_env.get_config().set("fs.s3a.path.style.access", cfg["s3_path_style"])
    if cfg["s3_access_key"]:
        t_env.get_config().set("fs.s3a.access.key", cfg["s3_access_key"])
    if cfg["s3_secret_key"]:
        t_env.get_config().set("fs.s3a.secret.key", cfg["s3_secret_key"])
    t_env.get_config().set("fs.s3a.aws.credentials.provider", "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider")

    t_env.execute_sql(f"""
    CREATE CATALOG {cfg['catalog']} WITH (
      'type'='paimon',
      'warehouse'='{cfg['warehouse']}',
      's3.endpoint'='{cfg['s3_endpoint']}',
      's3.access-key'='{cfg['s3_access_key']}',
      's3.secret-key'='{cfg['s3_secret_key']}',
      's3.path.style.access'='{cfg['s3_path_style']}'
    )
    """)
    t_env.execute_sql(f"USE CATALOG {cfg['catalog']}")
    t_env.execute_sql(f"CREATE DATABASE IF NOT EXISTS {cfg['database']}")
    t_env.execute_sql(f"USE {cfg['database']}")

    t_env.execute_sql("""
    CREATE TABLE IF NOT EXISTS page_views_per_minute (
      minute_start TIMESTAMP(0),
      page STRING,
      cnt BIGINT,
      PRIMARY KEY (minute_start, page) NOT ENFORCED
    ) PARTITIONED BY (minute_start) WITH (
      'bucket'='3',
      'file.format'='parquet'
    )
    """)

    t_env.execute_sql("""
    CREATE TEMPORARY TABLE clicks (
      user_id BIGINT,
      page STRING,
      ts TIMESTAMP(3),
      WATERMARK FOR ts AS ts - INTERVAL '5' SECOND
    ) WITH (
      'connector' = 'datagen',
      'rows-per-second' = '5'
    )
    """)

    insert_sql = """
    INSERT INTO page_views_per_minute
    SELECT
      CAST(TUMBLE_START(ts, INTERVAL '1' MINUTE) AS TIMESTAMP(0)) AS minute_start,
      page,
      COUNT(*) AS cnt
    FROM clicks
    GROUP BY TUMBLE(ts, INTERVAL '1' MINUTE), page
    """
    LOG.info("Submitting INSERT ...")

    table_result = t_env.execute_sql(insert_sql)

    job_client = table_result.get_job_client()
    if job_client is not None:
        job_client.get_job_execution_result().result()


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print("\n=== PYFLINK APP CRASH ===", file=sys.stderr)
        print("Error:", repr(e), file=sys.stderr)
        traceback.print_exc()
        print("PYTHON:", sys.executable, file=sys.stderr)
        print("PYTHONPATH:", os.environ.get("PYTHONPATH"), file=sys.stderr)
        sys.exit(1)
