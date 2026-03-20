import os
import sys
import traceback
import logging
from pathlib import Path
from string import Template
from typing import Dict, Iterable, List
from pyflink.table import EnvironmentSettings, TableEnvironment

logging.basicConfig(level=logging.INFO, format="[%(asctime)s] %(levelname)s %(message)s")
LOG = logging.getLogger("pyflink-paimon-demo")


def get_cfg() -> Dict[str, str]:
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
        # preferred order: image path, then fallback mounted path
        "sql_file": os.getenv("SQL_FILE", "/opt/flink/sql/pipeline.sql"),
    }


def _sql_context(cfg: Dict[str, str]) -> Dict[str, str]:
    return {
        "WAREHOUSE": cfg["warehouse"],
        "S3_ENDPOINT": cfg["s3_endpoint"],
        "S3_ACCESS_KEY": cfg["s3_access_key"],
        "S3_SECRET_KEY": cfg["s3_secret_key"],
        "S3_PATH_STYLE": cfg["s3_path_style"],
        "CATALOG": cfg["catalog"],
        "DATABASE": cfg["database"],
    }


def iter_sql_statements(sql_path: Path, cfg: Dict[str, str]) -> Iterable[str]:
    """Yield SQL statements split by semicolons, supporting multi-line formatting."""
    ctx = _sql_context(cfg)
    buf: List[str] = []
    for raw in sql_path.read_text(encoding="utf-8").splitlines():
        line = raw.split("--", 1)[0].strip()
        if not line:
            continue
        buf.append(line)
        joined = " ".join(buf)
        while ";" in joined:
            stmt, rest = joined.split(";", 1)
            stmt = stmt.strip()
            if stmt:
                yield Template(stmt).substitute(ctx)
            joined = rest.strip()
            buf = [joined] if joined else []
    trailer = " ".join(buf).strip()
    if trailer:
        yield Template(trailer).substitute(ctx)


def is_dml_statement(stmt: str) -> bool:
    """Check if a statement is a DML that triggers job execution."""
    upper = stmt.strip().upper()
    # INSERT statements always trigger execution
    if upper.startswith("INSERT"):
        return True
    # CTAS (CREATE TABLE ... AS SELECT) triggers execution
    if upper.startswith("CREATE TABLE") and " AS " in upper and "SELECT" in upper:
        return True
    return False


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

    sql_path = Path(cfg["sql_file"]).resolve()
    if not sql_path.exists():
        raise FileNotFoundError(f"SQL file not found: {sql_path}")

    LOG.info("Loading SQL statements from %s ...", sql_path)
    
    # Collect statements: DDL executed immediately, DML collected for batch execution
    ddl_statements = []
    dml_statements = []
    
    for stmt in iter_sql_statements(sql_path, cfg):
        if is_dml_statement(stmt):
            dml_statements.append(stmt)
        else:
            ddl_statements.append(stmt)
    
    # Execute DDL statements first (CREATE CATALOG, USE, CREATE TABLE, etc.)
    for stmt in ddl_statements:
        upper = stmt.strip().upper()
        if upper.startswith("SET "):
            # Handle SET statements via config API instead of executeSql()
            # Parse: SET 'key' = 'value'
            try:
                parts = stmt.strip()[4:].strip()  # remove "SET "
                key, value = parts.split("=", 1)
                key = key.strip().strip("'\"")
                value = value.strip().strip("'\"")
                LOG.info("Setting config: %s = %s", key, value)
                t_env.get_config().set(key, value)
            except Exception as e:
                LOG.warning("Failed to parse SET statement, trying executeSql: %s (error: %s)", stmt[:200], e)
                t_env.execute_sql(stmt)
        else:
            LOG.info("Executing DDL: %s", stmt[:200])
            t_env.execute_sql(stmt)
    
    # In Application Mode, we can only execute ONE job
    # If there are multiple DML statements, we need to handle them differently
    if len(dml_statements) == 0:
        LOG.info("No DML statements to execute.")
        return
    elif len(dml_statements) == 1:
        # Single DML - execute directly
        stmt = dml_statements[0]
        LOG.info("Executing single DML: %s", stmt[:200])
        table_result = t_env.execute_sql(stmt)
        job_client = table_result.get_job_client()
        if job_client is not None:
            LOG.info("Waiting for job to complete...")
            job_client.get_job_execution_result().result()
    else:
        # Multiple DML statements - use StatementSet for INSERT statements only
        # Note: CTAS cannot be added to StatementSet, must be executed separately
        insert_stmts = [s for s in dml_statements if s.strip().upper().startswith("INSERT")]
        ctas_stmts = [s for s in dml_statements if not s.strip().upper().startswith("INSERT")]
        
        if ctas_stmts:
            LOG.warning("Found %d CTAS statements. In Application Mode, only ONE can be executed.", len(ctas_stmts))
            LOG.warning("Executing only the first CTAS. Consider restructuring your SQL.")
            stmt = ctas_stmts[0]
            LOG.info("Executing CTAS: %s", stmt[:200])
            table_result = t_env.execute_sql(stmt)
            job_client = table_result.get_job_client()
            if job_client is not None:
                LOG.info("Waiting for CTAS job to complete...")
                job_client.get_job_execution_result().result()
        elif insert_stmts:
            # Use StatementSet for multiple INSERTs
            stmt_set = t_env.create_statement_set()
            for stmt in insert_stmts:
                LOG.info("Adding to StatementSet: %s", stmt[:200])
                stmt_set.add_insert_sql(stmt)
            LOG.info("Executing StatementSet with %d INSERT statements...", len(insert_stmts))
            table_result = stmt_set.execute()
            job_client = table_result.get_job_client()
            if job_client is not None:
                LOG.info("Waiting for job to complete...")
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

