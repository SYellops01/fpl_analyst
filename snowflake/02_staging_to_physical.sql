-- Loads staged FPL data into raw tables and builds a knowledge graph (nodes + edges)
-- Co-authored with CoCo
--Define context
USE ROLE DB_ENGINEER;
USE WAREHOUSE LOAD_WH;
USE DATABASE FPL_ONTOLOGY_DB;
USE SCHEMA FPL_STAGING;

/*
================================================================================================================
1. Load staged data into raw tables
================================================================================================================
*/

--Truncate and load RAW_FIXTURES table (CSV file format)
TRUNCATE TABLE RAW_FIXTURES;
COPY INTO RAW_FIXTURES FROM @FPL_DATA_STAGE/fixtures.csv
    FILE_FORMAT=(FORMAT_NAME=FPL_CSV_FORMAT) 
    ON_ERROR='ABORT_STATEMENT';

--Truncate and load RAW_GAMEWEEKS table (CSV file format)
TRUNCATE TABLE RAW_GAMEWEEKS;
COPY INTO RAW_GAMEWEEKS FROM @FPL_DATA_STAGE/gameweeks.csv
    FILE_FORMAT=(FORMAT_NAME=FPL_CSV_FORMAT) 
    ON_ERROR='ABORT_STATEMENT';

--Truncate and load RAW_GW_STATS table (JSON file format)
TRUNCATE TABLE RAW_GW_STATS;
COPY INTO RAW_GW_STATS (PLAYER_ID, GAMEWEEK_ID, FIXTURE_ID, STATS) 
FROM 
(
SELECT 
    $1:PLAYER_ID::INTEGER, 
    $1:GAMEWEEK_ID::INTEGER, 
    $1:FIXTURE_ID::INTEGER,
    $1:STATS
FROM @FPL_DATA_STAGE/gw_stats.json
)
    FILE_FORMAT=(FORMAT_NAME=FPL_JSON_FORMAT) 
    ON_ERROR='ABORT_STATEMENT';

--Truncate and load RAW_PLAYERS table (CSV file format)
TRUNCATE TABLE RAW_PLAYERS;
COPY INTO RAW_PLAYERS FROM @FPL_DATA_STAGE/players.csv
    FILE_FORMAT=(FORMAT_NAME=FPL_CSV_FORMAT) 
    ON_ERROR='ABORT_STATEMENT';

--Truncate and load RAW_POSITIONS table (CSV file format)
TRUNCATE TABLE RAW_POSITIONS;
COPY INTO RAW_POSITIONS FROM @FPL_DATA_STAGE/positions.csv
    FILE_FORMAT=(FORMAT_NAME=FPL_CSV_FORMAT) 
    ON_ERROR='ABORT_STATEMENT';

--Truncate and load RAW_TEAMS table (CSV file format)
TRUNCATE TABLE RAW_TEAMS;
COPY INTO RAW_TEAMS FROM @FPL_DATA_STAGE/teams.csv
    FILE_FORMAT=(FORMAT_NAME=FPL_CSV_FORMAT) 
    ON_ERROR='ABORT_STATEMENT';


/*
================================================================================================================
2. Truncate and load KG_NODE table
================================================================================================================
*/

--Truncate table
TRUNCATE TABLE FPL_KG.KG_NODE;

--Fixtures
INSERT INTO FPL_KG.KG_NODE (NODE_ID, NODE_TYPE, NAME, PROPS)
SELECT
    'FIX_' || FIXTURE_ID,
    'FIXTURE',
    'Fixture ' || FIXTURE_ID,
    OBJECT_CONSTRUCT(
        'fixture_id', FIXTURE_ID,
        'gameweek_id', GAMEWEEK_ID,
        'kickoff_time', KICKOFF_TIME,
        'home_team', TEAM_H,
        'away_team', TEAM_A,
        'home_team_score', TEAM_H_SCORE,
        'away_team_score', TEAM_A_SCORE
    )
FROM FPL_STAGING.RAW_FIXTURES;

--Gameweeks
INSERT INTO FPL_KG.KG_NODE (NODE_ID, NODE_TYPE, NAME, PROPS)
SELECT
    'GW_' || GAMEWEEK_ID,
    'GAMEWEEK',
    GAMEWEEK_NAME,
    OBJECT_CONSTRUCT(
        'gameweek_id', GAMEWEEK_ID,
        'deadline_time', DEADLINE_TIME,
        'average_entry_score', AVERAGE_ENTRY_SCORE,
        'highest_score', HIGHEST_SCORE,
        'most_selected_player_id', MOST_SELECTED_PLAYER_ID,
        'most_transferred_in_player_id', MOST_TRANSFERRED_IN_PLAYER_ID,
        'transfers_made', TRANSFERS_MADE,
        'most_captained_player_id', MOST_CAPTAINED_PLAYER_ID,
        'most_vice_captained_player_id', MOST_VICE_CAPTAINED_PLAYER_ID
    )
FROM FPL_STAGING.RAW_GAMEWEEKS;

--Raw gameweek stats
INSERT INTO FPL_KG.KG_NODE (NODE_ID, NODE_TYPE, NAME, PROPS)
SELECT
    'PERF_' || PLAYER_ID || '_' || GAMEWEEK_ID || '_' || FIXTURE_ID,
    'PERFORMANCE',
    'Player ' || PLAYER_ID || ' - GW' || GAMEWEEK_ID || ' - FIX' || FIXTURE_ID,
    STATS
FROM FPL_STAGING.RAW_GW_STATS;

--Players
INSERT INTO FPL_KG.KG_NODE (NODE_ID, NODE_TYPE, NAME, PROPS)
SELECT
    'PLAYER_' || PLAYER_ID,
    'PLAYER',
    FIRST_NAME || ' ' || SECOND_NAME,
    OBJECT_CONSTRUCT(
        'player_id', PLAYER_ID,
        'position_id', POSITION_ID,
        'first_name', FIRST_NAME,
        'second_name', SECOND_NAME,
        'team_id', TEAM_ID,
        'birth_date', BIRTH_DATE,
        'selected_by_percent', SELECTED_BY_PERCENT
    )
FROM FPL_STAGING.RAW_PLAYERS;

--Positions
INSERT INTO FPL_KG.KG_NODE (NODE_ID, NODE_TYPE, NAME, PROPS)
SELECT
    'POS_' || POSITION_ID,
    'POSITION',
    SINGULAR_NAME,
    OBJECT_CONSTRUCT(
        'position_id', POSITION_ID,
        'short_name', SINGULAR_NAME_SHORT,
        'num_players', NUM_PLAYERS
    )
FROM FPL_STAGING.RAW_POSITIONS;

--Teams
INSERT INTO FPL_KG.KG_NODE (NODE_ID, NODE_TYPE, NAME, PROPS)
SELECT
    'TEAM_' || TEAM_ID,
    'TEAM',
    TEAM_NAME,
    OBJECT_CONSTRUCT(
        'team_id', TEAM_ID,
        'strength', STRENGTH,
        'strength_overall_home', STRENGTH_OVERALL_HOME,
        'strength_overall_away', STRENGTH_OVERALL_AWAY,
        'strength_attack_home', STRENGTH_ATTACK_HOME,
        'strength_attack_away', STRENGTH_ATTACK_AWAY,
        'strength_defence_home', STRENGTH_DEFENCE_HOME,
        'strength_defence_away', STRENGTH_DEFENCE_AWAY
    )
FROM FPL_STAGING.RAW_TEAMS;


/*
================================================================================================================
3. Truncate and load KG_EDGE table - to define the relationships between entities.

Edge follows the following structure
    EDGE_ID - <a unique string built from the row's keys>,
    SRC_ID - <node id of the "from" entity>,
    DST_ID - <node id of the "to" entity>,
    EDGE_TYPE - '<EDGE_TYPE literal>',
    NULL     
================================================================================================================
*/

--Truncate table
TRUNCATE TABLE FPL_KG.KG_EDGE;

-- PLAYER -> [PLAYS_FOR] -> TEAM
INSERT INTO FPL_KG.KG_EDGE (EDGE_ID, SRC_ID, DST_ID, EDGE_TYPE, PROPS)
SELECT
    'PLAYS_FOR_PLAYER_' || PLAYER_ID || '_TEAM_' || TEAM_ID,
    'PLAYER_' || PLAYER_ID,
    'TEAM_' || TEAM_ID,
    'PLAYS_FOR',
    NULL
FROM FPL_STAGING.RAW_PLAYERS;

-- PLAYER -> [HAS_POSITION] -> POSITION
INSERT INTO FPL_KG.KG_EDGE (EDGE_ID, SRC_ID, DST_ID, EDGE_TYPE, PROPS)
SELECT
    'HAS_POSITION_PLAYER_' || PLAYER_ID || '_POS_' || POSITION_ID,
    'PLAYER_' || PLAYER_ID,
    'POS_' || POSITION_ID,
    'HAS_POSITION',
    NULL
FROM FPL_STAGING.RAW_PLAYERS;

-- FIXTURE -> [HOME_TEAM]-> TEAM
INSERT INTO FPL_KG.KG_EDGE (EDGE_ID, SRC_ID, DST_ID, EDGE_TYPE, PROPS)
SELECT
    'HOME_TEAM_FIX_' || FIXTURE_ID || '_TEAM_' || TEAM_H,
    'FIX_' || FIXTURE_ID,
    'TEAM_' || TEAM_H,
    'HOME_TEAM',
    NULL
FROM FPL_STAGING.RAW_FIXTURES
WHERE TEAM_H IS NOT NULL;

-- FIXTURE -> [AWAY_TEAM] -> TEAM
INSERT INTO FPL_KG.KG_EDGE (EDGE_ID, SRC_ID, DST_ID, EDGE_TYPE, PROPS)
SELECT
    'AWAY_TEAM_FIX_' || FIXTURE_ID || '_TEAM_' || TEAM_A,
    'FIX_' || FIXTURE_ID,
    'TEAM_' || TEAM_A,
    'AWAY_TEAM',
    NULL
FROM FPL_STAGING.RAW_FIXTURES
WHERE TEAM_A IS NOT NULL;

-- FIXTURE -> [IN_GAMEWEEK] -> GAMEWEEK
INSERT INTO FPL_KG.KG_EDGE (EDGE_ID, SRC_ID, DST_ID, EDGE_TYPE, PROPS)
SELECT
    'IN_GAMEWEEK_FIX_' || FIXTURE_ID || '_GW_' || GAMEWEEK_ID,
    'FIX_' || FIXTURE_ID,
    'GW_' || GAMEWEEK_ID,
    'IN_GAMEWEEK',
    NULL
FROM FPL_STAGING.RAW_FIXTURES
WHERE GAMEWEEK_ID IS NOT NULL;

-- PERFORMANCE -> [RECORDED_FOR] -> PLAYER
INSERT INTO FPL_KG.KG_EDGE (EDGE_ID, SRC_ID, DST_ID, EDGE_TYPE, PROPS)
SELECT
    'RECORDED_FOR_PERF_' || PLAYER_ID || '_' || GAMEWEEK_ID || '_' || FIXTURE_ID || '_PLAYER_' || PLAYER_ID,
    'PERF_' || PLAYER_ID || '_' || GAMEWEEK_ID || '_' || FIXTURE_ID,
    'PLAYER_' || PLAYER_ID,
    'RECORDED_FOR',
    NULL
FROM FPL_STAGING.RAW_GW_STATS;

-- PERFORMANCE -> [PERFORMED_IN_GAMEWEEK] -> GAMEWEEK
INSERT INTO FPL_KG.KG_EDGE (EDGE_ID, SRC_ID, DST_ID, EDGE_TYPE, PROPS)
SELECT
    'IN_GAMEWEEK_PERF_' || PLAYER_ID || '_' || GAMEWEEK_ID || '_' || FIXTURE_ID || '_GW_' || GAMEWEEK_ID,
    'PERF_' || PLAYER_ID || '_' || GAMEWEEK_ID || '_' || FIXTURE_ID,
    'GW_' || GAMEWEEK_ID,
    'PERFORMED_IN_GAMEWEEK',
    NULL
FROM FPL_STAGING.RAW_GW_STATS;

-- PERFORMANCE -> [IN_FIXTURE] -> FIXTURE
INSERT INTO FPL_KG.KG_EDGE (EDGE_ID, SRC_ID, DST_ID, EDGE_TYPE, PROPS)
SELECT
    'IN_FIXTURE_PERF_' || PLAYER_ID || '_' || GAMEWEEK_ID || '_' || FIXTURE_ID || '_FIX_' || FIXTURE_ID,
    'PERF_' || PLAYER_ID || '_' || GAMEWEEK_ID || '_' || FIXTURE_ID,
    'FIX_' || FIXTURE_ID,
    'IN_FIXTURE',
    NULL
FROM FPL_STAGING.RAW_GW_STATS
WHERE FIXTURE_ID IS NOT NULL;

-- GAMEWEEK -> [MOST_CAPTAINED] -> PLAYER
INSERT INTO FPL_KG.KG_EDGE (EDGE_ID, SRC_ID, DST_ID, EDGE_TYPE, PROPS)
SELECT
    'MOST_CAPTAINED_GW_' || GAMEWEEK_ID || '_PLAYER_' || MOST_CAPTAINED_PLAYER_ID,
    'GW_' || GAMEWEEK_ID,
    'PLAYER_' || MOST_CAPTAINED_PLAYER_ID,
    'MOST_CAPTAINED',
    NULL
FROM FPL_STAGING.RAW_GAMEWEEKS
WHERE MOST_CAPTAINED_PLAYER_ID IS NOT NULL;

-- GAMEWEEK -> [MOST_VICE_CAPTAINED] -> PLAYER
INSERT INTO FPL_KG.KG_EDGE (EDGE_ID, SRC_ID, DST_ID, EDGE_TYPE, PROPS)
SELECT
    'MOST_VICE_CAPTAINED_GW_' || GAMEWEEK_ID || '_PLAYER_' || MOST_VICE_CAPTAINED_PLAYER_ID,
    'GW_' || GAMEWEEK_ID,
    'PLAYER_' || MOST_VICE_CAPTAINED_PLAYER_ID,
    'MOST_VICE_CAPTAINED',
    NULL
FROM FPL_STAGING.RAW_GAMEWEEKS
WHERE MOST_VICE_CAPTAINED_PLAYER_ID IS NOT NULL;

-- GAMEWEEK -> [MOST_TRANSFERRED_IN] -> PLAYER
INSERT INTO FPL_KG.KG_EDGE (EDGE_ID, SRC_ID, DST_ID, EDGE_TYPE, PROPS)
SELECT
    'MOST_TRANSFERRED_IN_GW_' || GAMEWEEK_ID || '_PLAYER_' || MOST_TRANSFERRED_IN_PLAYER_ID,
    'GW_' || GAMEWEEK_ID,
    'PLAYER_' || MOST_TRANSFERRED_IN_PLAYER_ID,
    'MOST_TRANSFERRED_IN',
    NULL
FROM FPL_STAGING.RAW_GAMEWEEKS
WHERE MOST_TRANSFERRED_IN_PLAYER_ID IS NOT NULL;


-- GAMEWEEK -> [MOST_SELECTED] -> PLAYER
INSERT INTO FPL_KG.KG_EDGE (EDGE_ID, SRC_ID, DST_ID, EDGE_TYPE, PROPS)
SELECT
    'MOST_SELECTED_IN_GW_' || GAMEWEEK_ID || '_PLAYER_' || MOST_SELECTED_PLAYER_ID,
    'GW_' || GAMEWEEK_ID,
    'PLAYER_' || MOST_SELECTED_PLAYER_ID,
    'MOST_SELECTED',
    NULL
FROM FPL_STAGING.RAW_GAMEWEEKS
WHERE MOST_SELECTED_PLAYER_ID IS NOT NULL;
