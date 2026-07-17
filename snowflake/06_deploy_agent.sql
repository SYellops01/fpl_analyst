--Define Context
USE WAREHOUSE USAGE_WH;
USE ROLE DB_ENGINEER;
USE DATABASE FPL_ONTOLOGY_DB;
USE SCHEMA FPL_PRESENTATION;

/*
================================================================================================================
1. Deploy agent with instructions and two semantic models
================================================================================================================
*/

CREATE OR REPLACE AGENT FPL_ANALYST_AGENT
  COMMENT = 'FPL data and metadata analyst agent'
  PROFILE = '{"display_name": "FPL Analyst", "avatar": "fpl-icon.png", "color": "green"}'
  FROM SPECIFICATION
  $$
  instructions:
    response: "Answer clearly and concisely using the FPL data model."
    orchestration: "Use query_fpl_data for questions about players, teams, fixtures, gameweeks, or performance stats. Use query_fpl_metadata only for questions about the data model itself (what entities/relationships/properties exist)."
    sample_questions:
      - question: "Who scored the most points this season?"
      - question: "Show me fixtures for arsenal in the last 5 games of the season"
      - question: "Which midfielders under 7m have the best value for money this season?"
      - question: "What entity types exist in the FPL data model?"

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "query_fpl_data"
        description: "Answers concrete questions about players, teams, fixtures, gameweeks, or performance stats"
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "query_fpl_metadata"
        description: "Answers introspection questions about the FPL data model itself"

  tool_resources:
    query_fpl_data:
      semantic_model_file: "@FPL_PRESENTATION.SEMANTIC_MODELS/fpl_semantic_model.yml"
    query_fpl_metadata:
      semantic_model_file: "@FPL_PRESENTATION.SEMANTIC_MODELS/fpl_metadata_model.yml"
  $$;

ALTER AGENT FPL_ANALYST_AGENT
    SET PROFILE = '{"display_name": "FPL Analyst ⚽", "avatar": "football-icon.png", "color": "green"}';
