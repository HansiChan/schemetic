#!/usr/bin/env bash
set -euo pipefail

# Initialize MSSQL: create login/user and database schemas.
# Expects env vars: MSSQL_SA_PASSWORD, MSSQL_DATABASE

echo "[init] Running MSSQL initialization for DB: ${MSSQL_DATABASE:-<unset>}"

# Create login/user and permissions (idempotence should be handled inside SQL if re-run)
/opt/mssql-tools/bin/sqlcmd -b \
  -S localhost \
  -U sa \
  -P "${MSSQL_SA_PASSWORD}" \
  -d master \
  -v MSSQL_DATABASE="${MSSQL_DATABASE}" \
  -i sql/setup-user.sql

# Create database and base schemas
/opt/mssql-tools/bin/sqlcmd -b \
  -S localhost \
  -U sa \
  -P "${MSSQL_SA_PASSWORD}" \
  -d master \
  -v MSSQL_DATABASE="${MSSQL_DATABASE}" \
  -i sql/setup-db.sql

echo "[init] MSSQL initialization completed."
