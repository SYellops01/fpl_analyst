--Define context
USE ROLE DB_ENGINEER;
USE WAREHOUSE LOAD_WH;
USE DATABASE FPL_ONTOLOGY_DB;
USE SCHEMA FPL_KG;

/*
================================================================================================================
1. Truncate and load metadata into ontology metadata tables
================================================================================================================
*/

TRUNCATE TABLE ONT_CLASS;
INSERT INTO ONT_CLASS (CLASS_NAME, IS_ABSTRACT, PARENT_CLASS_NAME, DESCRIPTION) VALUES
    ('TEAM', FALSE, NULL, 'A Premier League club.'),
    ('POSITION', FALSE, NULL, 'A playing position as categorised by the FPL game: Goalkeeper, Defender, Midfielder, Forward.'),
    ('PLAYER', FALSE, NULL, 'An individual footballer able to be selected in the FPL game.'),
    ('GAMEWEEK', FALSE, NULL, 'A single round of fixtures in the FPL season calendar.'),
    ('FIXTURE', FALSE, NULL, 'A Premier League match taking place between two teams.'),
    ('PERFORMANCE', FALSE, NULL, 'A player''s recorded statistics for one fixture (goals, assists, points, minutes played etc.).');


TRUNCATE TABLE ONT_RELATION_DEF;
INSERT INTO ONT_RELATION_DEF (RELATION_NAME, SOURCE_CLASS_NAME, TARGET_CLASS_NAME, CARDINALITY, DESCRIPTION, INVERSE_OF) VALUES
    ('PLAYS_FOR', 'PLAYER', 'TEAM', 'MANY_TO_ONE', 'The team a player is currently registered to.', NULL),
    ('HAS_POSITION', 'PLAYER', 'POSITION', 'MANY_TO_ONE', 'The playing position assigned to a player.', NULL),
    ('HOME_TEAM', 'FIXTURE', 'TEAM', 'MANY_TO_ONE', 'The home team in a fixture.', NULL),
    ('AWAY_TEAM', 'FIXTURE', 'TEAM', 'MANY_TO_ONE', 'The away team in a fixture.', NULL),
    ('IN_GAMEWEEK', 'FIXTURE', 'GAMEWEEK', 'MANY_TO_ONE', 'The gameweek a fixture belongs to.', NULL),
    ('PERFORMED_IN_GAMEWEEK','PERFORMANCE', 'GAMEWEEK', 'MANY_TO_ONE', 'The gameweek a performance was recorded in.', NULL),
    ('RECORDED_FOR', 'PERFORMANCE', 'PLAYER', 'MANY_TO_ONE',  'The player a performance record describes.', NULL),
    ('IN_FIXTURE', 'PERFORMANCE', 'FIXTURE', 'MANY_TO_ONE', 'The fixture a performance record was recorded in.', NULL),
    ('MOST_CAPTAINED', 'GAMEWEEK', 'PLAYER', 'MANY_TO_ONE',  'The player captained by the most FPL managers in a gameweek.', NULL),
    ('MOST_VICE_CAPTAINED', 'GAMEWEEK', 'PLAYER', 'MANY_TO_ONE', 'The player vice-captained by the most FPL managers in a gameweek.', NULL),
    ('MOST_TRANSFERRED_IN', 'GAMEWEEK', 'PLAYER', 'MANY_TO_ONE', 'The player transferred in by the most FPL managers in a gameweek.', NULL),
    ('MOST_SELECTED', 'GAMEWEEK', 'PLAYER', 'MANY_TO_ONE', 'The player selected by the most FPL managers in a gameweek.', NULL)
;


--Truncate and load properties, excluding identifiers such as names, id's
TRUNCATE TABLE ONT_PROPERTY;
INSERT INTO ONT_PROPERTY (CLASS_NAME, PROPERTY_NAME, DATA_TYPE, DESCRIPTION, IS_MEASURE) VALUES
    -- TEAM
    ('TEAM', 'STRENGTH', 'INTEGER', 'Overall club difficulty rating on a scale of 1-5 used by the FPL algorithm - 1 denotes easiest teams and 5 the hardest', FALSE),
    ('TEAM', 'STRENGTH_OVERALL_HOME', 'INTEGER', 'Overall ELO strength rating for home fixtures - higher ELO for better teams', TRUE),
    ('TEAM', 'STRENGTH_OVERALL_AWAY', 'INTEGER', 'Overall ELO strength rating for away fixtures - higher ELO for better teams', TRUE),
    ('TEAM', 'STRENGTH_ATTACK_HOME', 'INTEGER', 'Attacking ELO strength rating for home fixtures - higher ELO for better teams', TRUE),
    ('TEAM', 'STRENGTH_ATTACK_AWAY', 'INTEGER', 'Attacking ELO strength rating for away fixtures - higher ELO for better teams', TRUE),
    ('TEAM', 'STRENGTH_DEFENCE_HOME', 'INTEGER', 'Defensive ELO strength rating for home fixtures - higher ELO for better teams', TRUE),
    ('TEAM', 'STRENGTH_DEFENCE_AWAY', 'INTEGER', 'Defensive ELO strength rating for away fixtures - higher ELO for better teams', TRUE),
 
    -- POSITION
    ('POSITION', 'SHORT_NAME', 'VARCHAR(3)', 'Position abbreviation, e.g. GKP/DEF/MID/FWD.', FALSE),
    ('POSITION', 'NUM_PLAYERS', 'INTEGER', 'Number of players currently assigned to this position.', TRUE),
 
    -- PLAYER
    ('PLAYER', 'SELECTED_BY_PERCENT', 'NUMBER(10,2)', 'Percent of FPL managers who currently own this player.', TRUE),
    ('PLAYER', 'BIRTH_DATE', 'DATE', 'The player''s date of birth.', FALSE),
 
    -- GAMEWEEK
    ('GAMEWEEK', 'DEADLINE_TIME', 'TIMESTAMP', 'The transfer deadline for this gameweek.', FALSE),
    ('GAMEWEEK', 'AVERAGE_ENTRY_SCORE', 'INTEGER', 'Average FPL points scored by all managers this gameweek.', TRUE),
    ('GAMEWEEK', 'HIGHEST_SCORE', 'INTEGER', 'Highest FPL points scored by any manager this gameweek.', TRUE),
    ('GAMEWEEK', 'TRANSFERS_MADE', 'INTEGER', 'Total number of transfers made across all managers this gameweek.', TRUE),
 
    -- FIXTURE
    ('FIXTURE', 'KICKOFF_TIME', 'TIMESTAMP', 'The scheduled kickoff time for the match.', FALSE),
    ('FIXTURE', 'TEAM_H_SCORE', 'INTEGER', 'Total number of goals scored by the home team.', TRUE),
    ('FIXTURE', 'TEAM_A_SCORE', 'INTEGER', 'Total number of goals scored by the away team.', TRUE),
 
    -- PERFORMANCE
    ('PERFORMANCE', 'STARTED', 'BOOLEAN', 'Boolean value signalling if the player was in the starting XI.', TRUE),
    ('PERFORMANCE', 'MINUTES', 'INTEGER', 'Minutes played in the fixture.', TRUE),
    ('PERFORMANCE', 'GOALS_SCORED', 'INTEGER', 'Goals scored in the fixture.', TRUE),
    ('PERFORMANCE', 'ASSISTS', 'INTEGER', 'Assists made in the fixture.', TRUE),
    ('PERFORMANCE', 'CLEAN_SHEETS', 'INTEGER', 'Clean sheets kept in the fixture (relevant for GKP/DEF/MID points).', TRUE),
    ('PERFORMANCE', 'GOALS_CONCEDED', 'INTEGER', 'Goals conceded while the player was on the pitch (relevant for GKP/DEF points).', TRUE),
    ('PERFORMANCE', 'OWN_GOALS', 'INTEGER', 'Own goals scored in the fixture.', TRUE),
    ('PERFORMANCE', 'PENALTIES_SAVED', 'INTEGER', 'Penalties saved in the fixture.', TRUE),
    ('PERFORMANCE', 'PENALTIES_MISSED', 'INTEGER', 'Penalties missed in the fixture.', TRUE),
    ('PERFORMANCE', 'YELLOW_CARDS', 'INTEGER', 'Yellow cards received in the fixture.', TRUE),
    ('PERFORMANCE', 'RED_CARDS', 'INTEGER', 'Red cards received in the fixture.', TRUE),
    ('PERFORMANCE', 'SAVES', 'INTEGER', 'Saves made in the fixture (goalkeepers).', TRUE),
    ('PERFORMANCE', 'BONUS', 'INTEGER', 'Bonus points awarded in the fixture (0-3 points available).', TRUE),
    ('PERFORMANCE', 'BPS', 'INTEGER', 'Bonus Points System score for the fixture.', TRUE),
    ('PERFORMANCE', 'INFLUENCE', 'NUMBER(10,2)', 'FPL Influence sub-score for the fixture.', TRUE),
    ('PERFORMANCE', 'CREATIVITY', 'NUMBER(10,2)', 'FPL Creativity sub-score for the fixture.', TRUE),
    ('PERFORMANCE', 'THREAT', 'NUMBER(10,2)', 'FPL Threat sub-score for the fixture.', TRUE),
    ('PERFORMANCE', 'ICT_INDEX', 'NUMBER(10,2)', 'Influence/Creativity/Threat composite index for the fixture.', TRUE),
    ('PERFORMANCE', 'TOTAL_POINTS', 'INTEGER', 'Total FPL points scored in the fixture.', TRUE),
    ('PERFORMANCE', 'DEFENSIVE_CONTRIBUTION', 'INTEGER', 'The number of defensive contributions made by a player in a fixture (2 additional points awarded to defenders with 10+ and to other players with 12+) ', TRUE),
    ('PERFORMANCE', 'EXPECTED_GOALS', 'NUMBER(10,2)', 'The number of expected goals for a player in a fixture', TRUE),
    ('PERFORMANCE', 'EXPECTED_ASSISTS', 'NUMBER(10,2)', 'The number of expected assists for a player in a fixture', TRUE),
    ('PERFORMANCE', 'EXPECTED_GOAL_INVOLVEMENTS', 'NUMBER(10,2)', 'The number of expected goal involvements for a player in a fixture (sum of expected goals and assists)', TRUE),
    ('PERFORMANCE', 'EXPECTED_GOALS_CONCEDED', 'NUMBER(10,2)', 'The number of expected goals against a player in a fixture', TRUE)
;

/*
================================================================================================================
2. Add views to FPL_PRESENTATION layer for querying by Cortex Analyst
================================================================================================================
*/

USE SCHEMA FPL_PRESENTATION;

CREATE OR REPLACE VIEW V_ONT_CLASS
    COMMENT = 'View containing the entity (node) types defined in the FPL ontology.'
AS
SELECT * FROM FPL_KG.ONT_CLASS;

CREATE OR REPLACE VIEW V_ONT_RELATION_DEF
    COMMENT = 'View containing the relationship (edge) types defined in the FPL ontology.'
AS
SELECT * FROM FPL_KG.ONT_RELATION_DEF;

CREATE OR REPLACE VIEW V_ONT_PROPERTY
    COMMENT = 'View containing the properties/attributes defined for each entity type.'
AS
SELECT * FROM FPL_KG.ONT_PROPERTY;

SELECT RELATION_NAME, SOURCE_CLASS_NAME, TARGET_CLASS_NAME, DESCRIPTION
      FROM FPL_PRESENTATION.V_ONT_RELATION_DEF
      WHERE RELATION_NAME = 'PLAYS_FOR';
