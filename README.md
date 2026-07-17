# Project Overview

This project wholly implements a Snowflake-native ontology platform that transforms Snowflake from a warehouse into a platform that can model real-world concepts. For this project, I use data from the Fantasy Premier League API to create an FPL Assistant which can be directly queried, enabling managers to directly query FPL data, enabling transfer decisions to be quickly backed by decision intelligence:

- *In the last three gameweeks, which defeneders most frequently reached 10 defensive contributions?*
- *Which three teams have the easiest fixtures in the next three gameweeks?*

<img width="1068" height="561" alt="image" src="https://github.com/user-attachments/assets/b9be5f0e-496a-401c-8e2e-a4635eae0342" />



# Key Features
- Script fetching data from FPL API.
- Physical storage of entities (nodes) and relationships (edges).
- Metadata-driven ontology view creation.
- Two specialised Cortex Analyst semantic models powering a single Cortex Agent.
- Scalable cloud warehouse powered by Snowflake.

# Setup
## Prerequisites
- Local machine with Python installed
- Snowflake Account (https://signup.snowflake.com/)

## Running the pipeline
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
3. Run **local/01_load_to_staging.py** to stage API data and YAML files in Snowflake stages.
4. Run **snowflake/02_staging_to_physical.sql** to pass staged data into FPL_STAGING tables.
5. Run **snowflake/03_generate_ontology_metadata.sql** to populate metadata tables for governance agent.
6. Run **snowflake/04_generate_ontology_views.sql** to automatically create ontology views from metadata.
7. Run **snowflake/05_create_consolidated_view.sql** to create a single, queryable view for Cortex Analyst
8. Run **snowflake/06_deploy_agent.sql** to deploy the agent to Snowflake Intelligence.

## API Documentation
- Get Bootstrap Data - https://www.postman.com/fplassist/fpl-assist/request/jwu0n11/boostrap-static
- Get Fixtures - https://www.postman.com/fplassist/fpl-assist/request/e3jbwhk/gameweek-fixtures
- Get Player Performance - https://www.postman.com/fplassist/fpl-assist/request/fyydugb/element-summary

# Solution Architecture
## Overall Architecture
<img width="1099" height="627" alt="image" src="https://github.com/user-attachments/assets/3f40bc64-d5f7-4622-97f5-3941faf6dae0" />

**Layer Summary:**
- Layer 5 - Cortex Agent: Orchestrates semantic models and graph analytics tools
- Layer 4 - Semantic Models: Knowledge Graph and Metadata
- Layer 3 - Generated Views: Auto-generated ontology views from metadata.
- Layer 2 - Ontology Metadata: Classes, relationships between classes, properties
- Layer 1 - Physical Storage: KG_NODE (entities) + KG_EDGE (relationships)

## Naming Conventions
- Views are prefixed with 'V_'.
- Knowledge graph tables are prefixed with 'KG_'.
- Ontologies are prefixed with 'ONT_'.
- Raw data from stages is prefixed with 'RAW_'
- Within the FPL_ONTOLOGY_DB database, schemas follow the following naming: FPL_**LAYER**, where **LAYER** is STAGING, KG or PRESENTATION.

## Snowflake Semantic Layer
<img width="845" height="562" alt="image" src="https://github.com/user-attachments/assets/8e6f8091-ed9a-45f3-85b8-9e099c576fd2" />


## Example Questions

#### FPL Query Agent
The FPL query agent answers questions relating to players, teams, fixtures and gameweek stats, providing insight required for squad planning:

***Q: "Which midfielders under 7m have been the best value for money this season?"***
<img width="1804" height="476" alt="image" src="https://github.com/user-attachments/assets/f2787be1-2a9f-43f8-8a65-ec2e98d39179" />

***Q: "Which forwards under the age of 25 have dcored the most FPL points in gameweeks 30-35?"***
<img width="1794" height="448" alt="image" src="https://github.com/user-attachments/assets/f0ed4f72-89ce-486f-a8be-08a3d23558c4" />

***Q: "In gameweeks 30-34, which defenders most frequently hit 10 DEFCONs?"***
<img width="1793" height="345" alt="image" src="https://github.com/user-attachments/assets/5d65332d-b39a-4865-ab4b-e8082b69cb85" />

***Q: "Which 3 teams have the easiest fixtures in gameweeks 10-14? Give me three recommendations for players to buy from each of these and their positions - I have a budget of 7.5m. When making this suggestion, consider the performance of these players in the previous 3 weeks"***
<img width="1800" height="466" alt="image" src="https://github.com/user-attachments/assets/19e203db-472b-4270-a853-a5ecf9112210" />



#### FPL Metadata Agent
The FPL metadata agent answers questions relating to what entities are available, what relationships exist and what attributes can be queried:

***Q: "What entities exist in the FPL data?"***
<img width="1394" height="361" alt="image" src="https://github.com/user-attachments/assets/6b1fc637-9449-4e47-af90-13f639ba713f" />

***Q: "What performance attributes are available in the FPL data to compare?"***
<img width="1379" height="475" alt="image" src="https://github.com/user-attachments/assets/bccd7268-0191-48f8-9437-efe6e95a59aa" />




