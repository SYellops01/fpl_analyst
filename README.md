# fpl_analyst
Implementation of ontology on Snowflake, applied to Fantasy Premier League


# Running the pipeline
The pipeline can be run manually in the following order:

1. Run **snowflake/00_setup.sql** to configure Snowflake.
2. Clone **local** folder - navigate to this as root folder and run in terminal:
   ```
   pip install virtualenv
   python -m venv pl_analyst
   .\pl_analyst\Scripts\activate
   pip install -r requirements.txt
   ::Add Snowflake credentials to credentials.py
   ```
3. Run **local/01_load_to_staging.py** to stage API data in Snowflake
4. Run **snowflake/02_staging_to_physical.sql** to pass staged data into FPL_STAGING tables.
