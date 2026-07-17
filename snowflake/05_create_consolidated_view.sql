/*
================================================================================================================
Create single, consolidated view for the semantic model to sit on, ensuring speed (otherwise multiple joins required by analyst) - not performant
================================================================================================================
*/

--Define context
USE ROLE DB_ENGINEER;
USE WAREHOUSE LOAD_WH;
USE DATABASE FPL_ONTOLOGY_DB;
USE SCHEMA FPL_PRESENTATION;

--Create view
CREATE OR REPLACE VIEW V_FPL_GAMEWEEK_PERFORMANCE
    COMMENT = 'Consolidated view with all details regarding a player performance in a given fixture'
AS
SELECT
    perf.NODE_ID AS PERFORMANCE_NODE_ID,
    p.PLAYER_ID,
    p.PLAYER_NAME,
    P.PRICE,
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
