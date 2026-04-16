import os
from pathlib import Path
from dagster_dbt import DbtProject

dbt_project_dir = Path(__file__).joinpath("..", "..", "dbt_project").resolve()

# We specify dbt project configurations here
paimon_dbt_project = DbtProject(
    project_dir=dbt_project_dir,
)

# During development, you might want to auto-compile
# In production, this path points to the pre-compiled target/manifest.json
paimon_dbt_project.prepare_if_dev()
