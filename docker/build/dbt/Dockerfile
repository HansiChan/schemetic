FROM python:3.10-slim

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /opt/dagster/app

# Set environment variables
ENV DAGSTER_HOME=/opt/dagster/dagster_home
ENV DBT_PROJECT_DIR=/opt/dagster/app/dbt_project
ENV DAGSTER_DBT_PARSE_PROJECT_ON_LOAD=1

# Create Dagster home
RUN mkdir -p $DAGSTER_HOME

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy dbt and dagster projects
COPY dbt_project/ ${DBT_PROJECT_DIR}/
COPY dagster_project/ /opt/dagster/app/dagster_project/

# Add default dagster.yaml
RUN echo "telemetry:\n  enabled: false" > $DAGSTER_HOME/dagster.yaml

# Create Dagster workspace.yaml
RUN echo "load_from:\n  - python_file:\n      relative_path: dagster_project/definitions.py\n      attribute: defs\n      working_directory: /opt/dagster/app/" > $DAGSTER_HOME/workspace.yaml

# Expose port for the dagster webserver
EXPOSE 3000

# Start Dagster Webserver by default
CMD ["dagster-webserver", "-h", "0.0.0.0", "-p", "3000"]
