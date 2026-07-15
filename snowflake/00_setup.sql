/*
================================================================================================================
This SQL file sets up the database, schema, objects and role requirements for the FPL knowledge graph
================================================================================================================
*/


/*
================================================================================================================
1. Create Database, Warehouse and Schema Objects
================================================================================================================
*/
USE ROLE SYSADMIN;

--Database
CREATE DATABASE IF NOT EXISTS FPL_ONTOLOGY_DB
    COMMENT = 'Database for FPL ontology model and analyst';
USE DATABASE FPL_ONTOLOGY_DB;

--Schemas
CREATE SCHEMA IF NOT EXISTS FPL_STAGING
    COMMENT = 'Schema for raw FPL API extracts before adding into knowledge graphs.';
CREATE SCHEMA IF NOT EXISTS FPL_KG
    COMMENT = 'Schema for the universal node/edge model required in internal knowledge graph.';
CREATE SCHEMA IF NOT EXISTS FPL_PRESENTATION
    COMMENT = 'Schema for presenting semantic models and denormalised views for Cortex Analyst';

--Warehouse (LOAD)
CREATE WAREHOUSE IF NOT EXISTS LOAD_WH
    WAREHOUSE_SIZE ='X-SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    COMMENT = 'Warehouse used to load data for FPL Knowledge Graph'
    ;   
--Warehouse (USAGE)
CREATE WAREHOUSE IF NOT EXISTS USAGE_WH
    WAREHOUSE_SIZE ='X-SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    COMMENT = 'Usage warehouse to interact with final analyst'
    ;

/*
================================================================================================================
2. Create engineer role and analyst role, configure permissions and grant to current user
================================================================================================================
*/
USE ROLE USERADMIN;

CREATE ROLE IF NOT EXISTS DB_ENGINEER
    COMMENT = 'Role to be used to load API data into Snowflake and for development';
CREATE ROLE IF NOT EXISTS DB_ANALYST
    COMMENT = 'Role to be used by end user connecting to FPL Agent';

USE ROLE SECURITYADMIN;

--DB_ENGINEER permissions
GRANT USAGE ON WAREHOUSE LOAD_WH TO ROLE DB_ENGINEER;
GRANT USAGE ON DATABASE FPL_ONTOLOGY_DB TO ROLE DB_ENGINEER;
GRANT ALL ON ALL SCHEMAS IN DATABASE FPL_ONTOLOGY_DB TO ROLE DB_ENGINEER;
GRANT ALL ON FUTURE SCHEMAS IN DATABASE FPL_ONTOLOGY_DB TO ROLE DB_ENGINEER;
GRANT ALL ON ALL TABLES IN DATABASE FPL_ONTOLOGY_DB TO ROLE DB_ENGINEER;
GRANT ALL ON FUTURE TABLES IN DATABASE FPL_ONTOLOGY_DB TO ROLE DB_ENGINEER;
GRANT ALL ON ALL VIEWS IN DATABASE FPL_ONTOLOGY_DB TO ROLE DB_ENGINEER;
GRANT ALL ON FUTURE VIEWS IN DATABASE FPL_ONTOLOGY_DB TO ROLE DB_ENGINEER;
GRANT ALL ON ALL STAGES IN DATABASE FPL_ONTOLOGY_DB TO ROLE DB_ENGINEER;
GRANT ALL ON FUTURE STAGES IN DATABASE FPL_ONTOLOGY_DB TO ROLE DB_ENGINEER;

--DB_ANALYST permissions;
GRANT USAGE ON WAREHOUSE USAGE_WH TO ROLE DB_ANALYST;
GRANT USAGE ON DATABASE FPL_ONTOLOGY_DB TO ROLE DB_ANALYST;
GRANT USAGE ON SCHEMA FPL_ONTOLOGY_DB.FPL_PRESENTATION TO ROLE DB_ANALYST;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_ANALYST_USER TO ROLE DB_ANALYST;
GRANT SELECT ON ALL TABLES IN SCHEMA FPL_ONTOLOGY_DB.FPL_PRESENTATION TO ROLE DB_ANALYST;
GRANT SELECT ON FUTURE TABLES IN SCHEMA FPL_ONTOLOGY_DB.FPL_PRESENTATION TO ROLE DB_ANALYST;
GRANT SELECT ON ALL VIEWS IN SCHEMA FPL_ONTOLOGY_DB.FPL_PRESENTATION TO ROLE DB_ANALYST;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA FPL_ONTOLOGY_DB.FPL_PRESENTATION TO ROLE DB_ANALYST;
GRANT READ ON ALL STAGES IN SCHEMA FPL_ONTOLOGY_DB.FPL_PRESENTATION TO ROLE DB_ANALYST;

--Grant roles to current user
DECLARE
    username STRING DEFAULT CURRENT_USER();
BEGIN
    EXECUTE IMMEDIATE
        'GRANT ROLE DB_ENGINEER TO USER "' || username || '"';

    EXECUTE IMMEDIATE
        'GRANT ROLE DB_ANALYST TO USER "' || username || '"';
END;

/*
================================================================================================================
4. Create stage and file formats for FPL API data from 01_load_to_staging.py
================================================================================================================
*/

USE ROLE DB_ENGINEER;
USE SCHEMA FPL_STAGING;

CREATE STAGE IF NOT EXISTS FPL_DATA_STAGE;

--File format for CSV export data (all except per gameweek stats)
CREATE FILE FORMAT IF NOT EXISTS FPL_CSV_FORMAT
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('', 'NULL', 'None')
    EMPTY_FIELD_AS_NULL = TRUE
    DATE_FORMAT = 'AUTO'
    TIMESTAMP_FORMAT = 'AUTO';

--Per gameweek stats are in JSON format due to nested dictionary values
CREATE FILE FORMAT IF NOT EXISTS FPL_JSON_FORMAT
    TYPE = JSON
    STRIP_OUTER_ARRAY = FALSE;

--Schema for semantic model .yml files
USE SCHEMA FPL_ONTOLOGY_DB.FPL_PRESENTATION;
CREATE STAGE IF NOT EXISTS SEMANTIC_MODELS DIRECTORY = (ENABLE = TRUE);

/*
================================================================================================================
4. Create Staging Tables for FPL API data in FPL_STAGING schema using engineer role
================================================================================================================
*/
USE ROLE DB_ENGINEER;

USE SCHEMA FPL_STAGING;

CREATE TABLE IF NOT EXISTS RAW_GAMEWEEKS 
(
    GAMEWEEK_ID INTEGER,
    GAMEWEEK_NAME VARCHAR(20),
    DEADLINE_TIME TIMESTAMP_NTZ,
    AVERAGE_ENTRY_SCORE INTEGER,
    HIGHEST_SCORE INTEGER,
    MOST_SELECTED_PLAYER_ID INTEGER,
    MOST_TRANSFERRED_IN_PLAYER_ID INTEGER,
    TRANSFERS_MADE INTEGER,
    MOST_CAPTAINED_PLAYER_ID INTEGER,
    MOST_VICE_CAPTAINED_PLAYER_ID INTEGER
)
    COMMENT = 'Raw data relating to each FPL gameweek - output from fetch_gameweeks() function'
;

CREATE TABLE IF NOT EXISTS RAW_TEAMS 
(
    TEAM_ID INTEGER,
    TEAM_NAME VARCHAR(30),
    STRENGTH INTEGER,
    STRENGTH_OVERALL_HOME INTEGER,
    STRENGTH_OVERALL_AWAY INTEGER,
    STRENGTH_ATTACK_HOME INTEGER,
    STRENGTH_ATTACK_AWAY INTEGER,
    STRENGTH_DEFENCE_HOME INTEGER,
    STRENGTH_DEFENCE_AWAY INTEGER
)
    COMMENT = 'Raw data relating to each team - output from fetch_teams() function'
;

CREATE TABLE IF NOT EXISTS RAW_POSITIONS 
(
    POSITION_ID INTEGER,
    SINGULAR_NAME VARCHAR(20),
    SINGULAR_NAME_SHORT VARCHAR(3),
    NUM_PLAYERS INTEGER
)
    COMMENT = 'Raw data relating to FPL positions - output from fetch_positions() function'
;

CREATE TABLE IF NOT EXISTS RAW_PLAYERS 
(
    PLAYER_ID INTEGER,
    POSITION_ID INTEGER,
    FIRST_NAME VARCHAR(50),
    SECOND_NAME VARCHAR(50),
    TEAM_ID INTEGER,
    BIRTH_DATE DATE,
    SELECTED_BY_PERCENT NUMBER(10,2)
)
    COMMENT = 'Raw data relating to FPL Player - output from fetch_players() function'
;

CREATE TABLE IF NOT EXISTS RAW_FIXTURES 
(
    FIXTURE_ID INTEGER,
    GAMEWEEK_ID INTEGER,
    KICKOFF_TIME TIMESTAMP_NTZ,
    TEAM_H INTEGER,
    TEAM_H_SCORE INTEGER,
    TEAM_A INTEGER,
    TEAM_A_SCORE INTEGER
)
    COMMENT = 'Raw data relating to fixtures scheduled - output from fetch_fixtures() function'
;

CREATE TABLE IF NOT EXISTS RAW_GW_STATS 
(
    PLAYER_ID INTEGER,
    GAMEWEEK_ID INTEGER,
    FIXTURE_ID INTEGER,
    STATS VARIANT
)
    COMMENT = 'Raw data for player performance and stats in a gameweek. Stats stored as variant for efficiency and flexibility - output from fetch_gw_stats() function'
;


/*
================================================================================================================
5. Create Tables for entities (KG_NODE) and relationships (EDGE) using DB_ENGINEER role
================================================================================================================
*/

USE SCHEMA FPL_KG;

CREATE TABLE IF NOT EXISTS KG_NODE
(
    NODE_ID STRING NOT NULL,
    NODE_TYPE STRING NOT NULL,
    NAME STRING,
    PROPS VARIANT,
    PRIMARY KEY (NODE_ID)
)
    COMMENT = 'Table for every entity (team, player, position, gameweek, fixture, performance)'
;

CREATE TABLE IF NOT EXISTS KG_EDGE
(
    EDGE_ID STRING NOT NULL,
    SRC_ID STRING NOT NULL,
    DST_ID STRING NOT NULL,
    EDGE_TYPE STRING NOT NULL,
    PROPS VARIANT,
    PRIMARY KEY (EDGE_ID)
)
    COMMENT = 'Table containing relationships between entities'
;

--Define cluster key on commonly filtered columns for performance
ALTER TABLE KG_NODE CLUSTER BY (NODE_TYPE);
ALTER TABLE KG_EDGE CLUSTER BY (EDGE_ID, SRC_ID);


/*
================================================================================================================
5. Create Tables for ontology metadata using DB_ENGINEER role, defining the context and business definitions that can be directly queried
================================================================================================================
*/

CREATE TABLE IF NOT EXISTS ONT_CLASS (
    CLASS_NAME          STRING PRIMARY KEY,
    IS_ABSTRACT         BOOLEAN,
    PARENT_CLASS_NAME   STRING,
    DESCRIPTION         STRING
)
    COMMENT = 'Catalog of entity (node) types and purpose, powering any questions related to metadata'
;
 
CREATE TABLE IF NOT EXISTS ONT_RELATION_DEF (
    RELATION_NAME       STRING PRIMARY KEY,
    SOURCE_CLASS_NAME   STRING,
    TARGET_CLASS_NAME   STRING,
    CARDINALITY         STRING,
    DESCRIPTION         STRING,
    INVERSE_OF          STRING
)
    COMMENT = 'Catalog of relationships defined in KG_EDGE, powering any questions related to metadata'
;
 
CREATE TABLE IF NOT EXISTS ONT_PROPERTY (
    CLASS_NAME          STRING,
    PROPERTY_NAME       STRING,
    DATA_TYPE           STRING,
    DESCRIPTION         STRING,
    IS_MEASURE          BOOLEAN,
    PRIMARY KEY (CLASS_NAME, PROPERTY_NAME)
)
    COMMENT = 'Catalog of queryable attributes for each entity (node), powering any questions related to metadata'
;
