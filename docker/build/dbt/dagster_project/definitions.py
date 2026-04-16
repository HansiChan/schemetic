import os
from dagster import Definitions
from dagster_dbt import DbtCliResource, load_assets_from_dbt_project
from .project import paimon_dbt_project

# Load dbt assets based on the manifest
dbt_assets = load_assets_from_dbt_project(
    project_dir=paimon_dbt_project.project_dir,
    profiles_dir=paimon_dbt_project.project_dir,
)

defs = Definitions(
    assets=dbt_assets,
    resources={
        "dbt": DbtCliResource(project_dir=paimon_dbt_project),
    },
)
