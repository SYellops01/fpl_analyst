--Define context
USE ROLE DB_ENGINEER;
USE WAREHOUSE LOAD_WH;
USE DATABASE FPL_ONTOLOGY_DB;
USE SCHEMA FPL_PRESENTATION;

/*
================================================================================================================
1. Create flattened views from each node in KG_NODE
================================================================================================================
*/


CREATE OR REPLACE VIEW V_TEAM 
    COMMENT = 'Physical view containing details for each team'
AS 
SELECT
    NODE_ID,
    NAME AS TEAM_NAME,
    PROPS:team_id::INT AS TEAM_ID,
    PROPS:strength::INT AS STRENGTH,
    PROPS:strength_overall_home::INT AS STRENGTH_OVERALL_HOME,
    PROPS:strength_overall_away::INT AS STRENGTH_OVERALL_AWAY,
    PROPS:strength_attack_home::INT AS STRENGTH_ATTACK_HOME,
    PROPS:strength_attack_away::INT AS STRENGTH_ATTACK_AWAY,
    PROPS:strength_defence_home::INT AS STRENGTH_DEFENCE_HOME,
    PROPS:strength_defence_away::INT AS STRENGTH_DEFENCE_AWAY
FROM FPL_KG.KG_NODE
WHERE NODE_TYPE = 'TEAM';
 
CREATE OR REPLACE VIEW V_POSITION 
    COMMENT = 'Physical view containing details for each position'
AS 
SELECT
    NODE_ID,
    NAME AS POSITION_NAME,
    PROPS:position_id::INT AS POSITION_ID,
    PROPS:short_name::VARCHAR(3) AS SHORT_NAME,
    PROPS:num_players::INT AS NUM_PLAYERS
FROM FPL_KG.KG_NODE
WHERE NODE_TYPE = 'POSITION';
 
CREATE OR REPLACE VIEW V_PLAYER
    COMMENT = 'Physical view containing details for each player'
AS 
SELECT
    NODE_ID,
    NAME AS PLAYER_NAME,
    PROPS:player_id::INTEGER AS PLAYER_ID,
    PROPS:first_name::VARCHAR(50) AS FIRST_NAME,
    PROPS:second_name::VARCHAR(50) AS SECOND_NAME,
    PROPS:birth_date::DATE AS BIRTH_DATE,
    PROPS:selected_by_percent::NUMBER(10,2) AS SELECTED_BY_PERCENT
FROM FPL_KG.KG_NODE
WHERE NODE_TYPE = 'PLAYER';
 
CREATE OR REPLACE VIEW V_GAMEWEEK
    COMMENT = 'Physical view containing details for each gameweek'
AS
SELECT
    NODE_ID,
    NAME AS GAMEWEEK_NAME,
    PROPS:gameweek_id::INT AS GAMEWEEK_ID,
    PROPS:deadline_time::TIMESTAMP_NTZ AS DEADLINE_TIME,
    PROPS:average_entry_score::INT AS AVERAGE_ENTRY_SCORE,
    PROPS:highest_score::INT AS HIGHEST_SCORE,
    PROPS:transfers_made::INT AS TRANSFERS_MADE
FROM FPL_KG.KG_NODE
WHERE NODE_TYPE = 'GAMEWEEK';
 
CREATE OR REPLACE VIEW V_FIXTURE
    COMMENT = 'Physical view containing details for each fixture'
AS
SELECT
    NODE_ID,
    PROPS:fixture_id::INT AS FIXTURE_ID,
    PROPS:kickoff_time::TIMESTAMP_NTZ AS KICKOFF_TIME,
    PROPS:home_team_score::INT AS TEAM_H_SCORE,
    PROPS:away_team_score::INT AS TEAM_A_SCORE
FROM FPL_KG.KG_NODE
WHERE NODE_TYPE = 'FIXTURE';
 

CREATE OR REPLACE VIEW V_PERFORMANCE 
    COMMENT = 'Physical view containing details for player performance in each fixture'
AS
SELECT
    NODE_ID,
    PROPS:starts::INT = 1 AS STARTED,
    PROPS:minutes::INT AS MINUTES,
    PROPS:goals_scored::INT AS GOALS_SCORED,
    PROPS:assists::INT AS ASSISTS,
    PROPS:clean_sheets::INT AS CLEAN_SHEETS,
    PROPS:goals_conceded::INT AS GOALS_CONCEDED,
    PROPS:own_goals::INT AS OWN_GOALS,
    PROPS:penalties_saved::INT AS PENALTIES_SAVED,
    PROPS:penalties_missed::INT AS PENALTIES_MISSED,
    PROPS:yellow_cards::INT AS YELLOW_CARDS,
    PROPS:red_cards::INT AS RED_CARDS,
    PROPS:saves::INT AS SAVES,
    PROPS:bonus::INT AS BONUS,
    PROPS:bps::INT AS BPS,
    PROPS:influence::NUMBER(10,2) AS INFLUENCE,
    PROPS:creativity::NUMBER(10,2) AS CREATIVITY,
    PROPS:threat::NUMBER(10,2) AS THREAT,
    PROPS:ict_index::NUMBER(10,2) AS ICT_INDEX,
    PROPS:total_points::INT AS TOTAL_POINTS,
    PROPS:defensive_contribution::INT AS DEFENSIVE_CONTRIBUTION,
    PROPS:expected_goals::NUMBER(10,2) AS EXPECTED_GOALS,
    PROPS:expected_assists::NUMBER(10,2) AS EXPECTED_ASSISTS,
    PROPS:expected_goal_involvements::NUMBER(10,2) AS EXPECTED_GOAL_INVOLVEMENTS,
    PROPS:expected_goals_conceded::NUMBER(10,2) AS EXPECTED_GOALS_CONCEDED,
    PROPS AS ALL_STATS
FROM FPL_KG.KG_NODE
WHERE NODE_TYPE = 'PERFORMANCE';


/*
================================================================================================================
2. Create flattened views from each relationship in KG_EDGE
================================================================================================================
*/


CREATE OR REPLACE VIEW V_PLAYS_FOR 
    COMMENT = 'Physical view containing relationship between player and team'
AS
SELECT 
    SRC_ID AS PLAYER_NODE_ID, 
    DST_ID AS TEAM_NODE_ID
FROM FPL_KG.KG_EDGE 
WHERE EDGE_TYPE = 'PLAYS_FOR';
 
CREATE OR REPLACE VIEW V_HAS_POSITION
    COMMENT = 'Physical view containing relationship between player and position'
AS
SELECT
    SRC_ID AS PLAYER_NODE_ID,
    DST_ID AS POSITION_NODE_ID
FROM FPL_KG.KG_EDGE 
WHERE EDGE_TYPE = 'HAS_POSITION';
 
CREATE OR REPLACE VIEW V_HOME_TEAM
    COMMENT = 'Physical view containing relationship between fixture and home team'
AS
SELECT
    SRC_ID AS FIXTURE_NODE_ID, 
    DST_ID AS TEAM_NODE_ID
FROM FPL_KG.KG_EDGE 
WHERE EDGE_TYPE = 'HOME_TEAM';
 
CREATE OR REPLACE VIEW V_AWAY_TEAM
    COMMENT = 'Physical view containing relationship between fixture and away team'
AS
SELECT 
    SRC_ID AS FIXTURE_NODE_ID,
    DST_ID AS TEAM_NODE_ID
FROM FPL_KG.KG_EDGE 
WHERE EDGE_TYPE = 'AWAY_TEAM';
 
CREATE OR REPLACE VIEW V_FIXTURE_IN_GAMEWEEK
    COMMENT = 'Physical view containing relationship between fixture and gameweek'
AS
SELECT
    SRC_ID AS FIXTURE_NODE_ID, 
    DST_ID AS GAMEWEEK_NODE_ID
FROM FPL_KG.KG_EDGE
WHERE EDGE_TYPE = 'IN_GAMEWEEK';
 
CREATE OR REPLACE VIEW V_PERFORMED_IN_GAMEWEEK
    COMMENT = 'Physical view containing relationship between player performance and gameweek'
AS
SELECT
    SRC_ID AS PERFORMANCE_NODE_ID,
    DST_ID AS GAMEWEEK_NODE_ID
FROM FPL_KG.KG_EDGE
WHERE EDGE_TYPE = 'PERFORMED_IN_GAMEWEEK';
 
CREATE OR REPLACE VIEW V_RECORDED_FOR
    COMMENT = 'Physical view containing relationship between performance and player'
AS
SELECT 
    SRC_ID AS PERFORMANCE_NODE_ID,
    DST_ID AS PLAYER_NODE_ID
FROM FPL_KG.KG_EDGE 
WHERE EDGE_TYPE = 'RECORDED_FOR';
 
CREATE OR REPLACE VIEW V_IN_FIXTURE
    COMMENT = 'Physical view containing relationship between player performance and fixture'
AS
SELECT
    SRC_ID AS PERFORMANCE_NODE_ID, 
    DST_ID AS FIXTURE_NODE_ID
FROM FPL_KG.KG_EDGE 
WHERE EDGE_TYPE = 'IN_FIXTURE';
 
CREATE OR REPLACE VIEW V_MOST_CAPTAINED
    COMMENT = 'Physical view containing relationship between gameweek and most captained player'
AS
SELECT 
    SRC_ID AS GAMEWEEK_NODE_ID, 
    DST_ID AS PLAYER_NODE_ID
FROM FPL_KG.KG_EDGE 
WHERE EDGE_TYPE = 'MOST_CAPTAINED';
 
CREATE OR REPLACE VIEW V_MOST_VICE_CAPTAINED
    COMMENT = 'Physical view containing relationship between gameweek and most vice captained player'
AS
SELECT 
    SRC_ID AS GAMEWEEK_NODE_ID, 
    DST_ID AS PLAYER_NODE_ID
FROM FPL_KG.KG_EDGE 
WHERE EDGE_TYPE = 'MOST_VICE_CAPTAINED';
 
CREATE OR REPLACE VIEW V_MOST_TRANSFERRED_IN 
    COMMENT = 'Physical view containing relationship between gameweek and most transferred in player'
AS
SELECT 
    SRC_ID AS GAMEWEEK_NODE_ID, 
    DST_ID AS PLAYER_NODE_ID
FROM FPL_KG.KG_EDGE 
WHERE EDGE_TYPE = 'MOST_TRANSFERRED_IN';

CREATE OR REPLACE VIEW V_MOST_SELECTED 
    COMMENT = 'Physical view containing relationship between gameweek and most selected player'
AS
SELECT 
    SRC_ID AS GAMEWEEK_NODE_ID, 
    DST_ID AS PLAYER_NODE_ID
FROM FPL_KG.KG_EDGE 
WHERE EDGE_TYPE = 'MOST_SELECTED';


/*
================================================================================================================
3. Create single, consolidated view for the semantic model to sit on, ensuring speed (otherwise multiple joins required by analyst) - not performant
================================================================================================================
*/


CREATE OR REPLACE VIEW V_FPL_GAMEWEEK_PERFORMANCE
    COMMENT = 'Consolidated view with all details regarding a player performance in a given fixture'
AS
SELECT
    perf.NODE_ID AS PERFORMANCE_NODE_ID,
    p.PLAYER_ID,
    p.PLAYER_NAME,
    pos.POSITION_NAME,
    pos.SHORT_NAME AS POSITION_SHORT_NAME,
    t.TEAM_ID,
    t.TEAM_NAME,
    gw.GAMEWEEK_ID,
    gw.GAMEWEEK_NAME,
    gw.DEADLINE_TIME,
    fx.FIXTURE_ID,
    fx.KICKOFF_TIME,
    perf.STARTED,
    perf.MINUTES,
    perf.GOALS_SCORED,
    perf.ASSISTS,
    perf.CLEAN_SHEETS,
    perf.GOALS_CONCEDED,
    perf.YELLOW_CARDS,
    perf.RED_CARDS,
    perf.SAVES,
    perf.BONUS,
    perf.BPS,
    perf.ICT_INDEX,
    perf.TOTAL_POINTS,
    perf.DEFENSIVE_CONTRIBUTION,
    perf.EXPECTED_GOALS,
    perf.EXPECTED_ASSISTS,
    perf.EXPECTED_GOAL_INVOLVEMENTS,
    perf.EXPECTED_GOALS_CONCEDED
FROM V_PERFORMANCE perf
    JOIN V_RECORDED_FOR rf ON perf.NODE_ID = rf.PERFORMANCE_NODE_ID
    JOIN V_PLAYER p ON rf.PLAYER_NODE_ID = p.NODE_ID
    JOIN V_HAS_POSITION hp ON p.NODE_ID = hp.PLAYER_NODE_ID
    JOIN V_POSITION pos ON hp.POSITION_NODE_ID = pos.NODE_ID
    JOIN V_PLAYS_FOR pf ON p.NODE_ID = pf.PLAYER_NODE_ID
    JOIN V_TEAM t ON pf.TEAM_NODE_ID = t.NODE_ID
    JOIN V_PERFORMED_IN_GAMEWEEK pg ON perf.NODE_ID = pg.PERFORMANCE_NODE_ID
    JOIN V_GAMEWEEK gw ON pg.GAMEWEEK_NODE_ID = gw.NODE_ID
    LEFT JOIN V_IN_FIXTURE inf ON perf.NODE_ID = inf.PERFORMANCE_NODE_ID
    LEFT JOIN V_FIXTURE fx ON inf.FIXTURE_NODE_ID = fx.NODE_ID
;
