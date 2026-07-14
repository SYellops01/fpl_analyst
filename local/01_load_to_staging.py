#Install dependencies and credentials
import time
import requests
import json
import pandas as pd
from pathlib import Path
import os
import csv
import snowflake.connector
from credentials import (get_sf_username, get_sf_password, get_sf_acc_identifier)

#Define base url and directory for file outputs
base_url = "https://fantasy.premierleague.com/api"
output_dir = Path("./fpl_outputs")


# ---------------------------------------------------------------------------------
# 1. Function to write to csv
# ---------------------------------------------------------------------------------
def _write_csv(rows: list[dict], columns: list[str], path: Path) -> None:
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=columns)
        writer.writeheader()
        writer.writerows(rows)
    print(f"[EXTRACT] wrote {len(rows):>6} rows -> {path}")


# ---------------------------------------------------------------------------------
# 2. Define functions to extract data to CSV/JSON
# ---------------------------------------------------------------------------------

#Bootstrap API response
def extract_bootstrap():
    response = requests.get(f"{base_url}/bootstrap-static/", timeout=15)
    response.raise_for_status()
    return response.json()


def fetch_gameweeks(data, path):
    '''
    Extracts gameweeks from bootstrap API, remaps columns and writes as CSV to the specified output path
    '''
    gameweeks = data["events"]
    col_map = {
        "id": "GAMEWEEK_ID", "name": "GAMEWEEK_NAME", "deadline_time": "DEADLINE_TIME",
        "average_entry_score": "AVERAGE_ENTRY_SCORE", "highest_score": "HIGHEST_SCORE",
        "most_selected": "MOST_SELECTED_PLAYER_ID", "most_transferred_in": "MOST_TRANSFERRED_IN_PLAYER_ID",
        "transfers_made": "TRANSFERS_MADE", "most_captained": "MOST_CAPTAINED_PLAYER_ID",
        "most_vice_captained": "MOST_VICE_CAPTAINED_PLAYER_ID",
    }
    rows = [{v: row.get(k) for k, v in col_map.items()} for row in gameweeks]
    _write_csv(rows, list(col_map.values()), path)

def fetch_teams(data, path):
    '''
    Extracts teams from bootstrap API, remaps columns and writes as CSV to the specified output path
    '''
    teams = data["teams"]
    col_map = {
        "id": "TEAM_ID", "name": "TEAM_NAME", "strength": "STRENGTH",
        "strength_overall_home": "STRENGTH_OVERALL_HOME", "strength_overall_away": "STRENGTH_OVERALL_AWAY",
        "strength_attack_home": "STRENGTH_ATTACK_HOME", "strength_attack_away": "STRENGTH_ATTACK_AWAY",
        "strength_defence_home": "STRENGTH_DEFENCE_HOME", "strength_defence_away": "STRENGTH_DEFENCE_AWAY",
    }
    rows = [{v: row.get(k) for k, v in col_map.items()} for row in teams]
    _write_csv(rows, list(col_map.values()), path)
    
def fetch_positions(data, path):
    '''
    Extracts positions from bootstrap API, remaps columns and writes as CSV to the specified output path
    '''
    positions = data["element_types"]
    col_map = {
        "id": "POSITION_ID", "singular_name": "SINGULAR_NAME",
        "singular_name_short": "SINGULAR_NAME_SHORT", "element_count": "NUM_PLAYERS",
    }
    rows = [{v: row.get(k) for k, v in col_map.items()} for row in positions]
    _write_csv(rows, list(col_map.values()), path)

def fetch_players(data, path):
    '''
    Extracts all players from bootstrap API, remaps columns and writes as CSV to the specified output path
    '''
    players = data["elements"]
    col_map = {
        "id": "PLAYER_ID", "element_type": "POSITION_ID", "first_name": "FIRST_NAME",
        "second_name": "SECOND_NAME", "team": "TEAM_ID", "birth_date": "BIRTH_DATE",
        "selected_by_percent": "SELECTED_BY_PERCENT",
    }
    rows = [{v: row.get(k) for k, v in col_map.items()} for row in players]
    _write_csv(rows, list(col_map.values()), path)
    return [player["id"] for player in players]

def fetch_fixtures(path):
    '''
    Extracts all fixtures from fixtures API, remaps columns and writes as CSV to the specified output path
    '''
    response = requests.get(f"{base_url}/fixtures/", timeout=15)
    response.raise_for_status()
    fixtures = response.json()
    
    col_map = {
        "id": "FIXTURE_ID", "event": "GAMEWEEK_ID", "kickoff_time": "KICKOFF_TIME",
        "team_h": "TEAM_H", "team_h_score": "TEAM_H_SCORE", "team_a": "TEAM_A",
        "team_a_score": "TEAM_A_SCORE",
    }
    rows = [{v: row.get(k) for k, v in col_map.items()} for row in fixtures]
    _write_csv(rows, list(col_map.values()), path)

def fetch_gw_stats(path, player_ids):
    '''
    Extracts all gameweek scores for players from events API for all specified player_ids
    '''
    keep_columns = ['starts', 'minutes','goals_scored','assists','clean_sheets','goals_conceded','own_goals','penalties_saved',
                'penalties_missed','yellow_cards','red_cards', 'saves', 'bonus','bps','influence', 
                'creativity', 'threat', 'ict_index', 'defensive_contribution', 'expected_goals', 
                'expected_assists', 'expected_goal_involvements', 'expected_goals_conceded']
    
    with open(path, "w") as f:
        for player_id in player_ids:
            url = f"{base_url}/element-summary/{player_id}/"
            try:
                response = requests.get(url, timeout=15)
                response.raise_for_status()
                data = response.json()
                
                for fixture in data['history']:
                    stats = {k: v for k, v in fixture.items() if k in keep_columns}
                    record = {
                        "PLAYER_ID": player_id,
                        "GAMEWEEK_ID": fixture["round"],
                        "FIXTURE_ID": fixture["fixture"],
                        "STATS": stats,
                    }
                    f.write(json.dumps(record) + "\n")
            except requests.exceptions.RequestException as e:
                print(f"Player {player_id} error: {e}")
            time.sleep(0.2)


# ---------------------------------------------------------------------------------
# 3. Fetch API data locally
# ---------------------------------------------------------------------------------
print("="*60)
print(" >> Extracting data from FPL API")

output_dir.mkdir(exist_ok=True)
bootstrap = extract_bootstrap()
gameweeks = fetch_gameweeks(bootstrap, output_dir / 'gameweeks.csv')
teams = fetch_teams(bootstrap, output_dir / 'teams.csv')
positions = fetch_positions(bootstrap, output_dir / 'positions.csv')
player_ids = fetch_players(bootstrap, output_dir / 'players.csv')
fixtures = fetch_fixtures(output_dir / 'fixtures.csv')
gw_stats = fetch_gw_stats(output_dir / 'gw_stats.json', player_ids)
print("FPL API data successfully extracted")
print("="*60)

temporary_files = ["gameweeks.csv", "teams.csv", "positions.csv", "players.csv", "fixtures.csv", "gw_stats.json"]

# ---------------------------------------------------------------------------------
# 4. Put to Snowflake stage
# ---------------------------------------------------------------------------------
print("="*60)
print(" >> Creating Snowflake connection")
# Define credentials and set up connection
SNOWFLAKE_USER      = get_sf_username()
SNOWFLAKE_PASSWORD  = get_sf_password()
SNOWFLAKE_ACCOUNT   = get_sf_acc_identifier()
SNOWFLAKE_WAREHOUSE = "LOAD_WH"
SNOWFLAKE_DB        = "FPL_ONTOLOGY_DB"
SNOWFLAKE_SCHEMA    = "FPL_STAGING"
STAGE               = "FPL_DATA_STAGE"

conn = snowflake.connector.connect(
    user=SNOWFLAKE_USER,
    password=SNOWFLAKE_PASSWORD,
    account=SNOWFLAKE_ACCOUNT,
    warehouse=SNOWFLAKE_WAREHOUSE,
    database=SNOWFLAKE_DB,
    schema=SNOWFLAKE_SCHEMA,
)
cur = conn.cursor()
print("Connection to Snowflake successful")
print("="*60)

#for each file in temporary files list, attempt to put to the stage and remove. 
print("="*60)
print(" >> Putting files to Snowflake")
try:
    for file in temporary_files:
        full_path = (output_dir / file).resolve()
        cur.execute(
            f"PUT file://{full_path} @{SNOWFLAKE_DB}.{SNOWFLAKE_SCHEMA}.{STAGE} AUTO_COMPRESS=TRUE OVERWRITE=TRUE"
        )
        print(f">> {file} -> @{STAGE}")
        os.remove(full_path)
        print(f">> Cleaned up {file}")
finally:
    cur.close()
    conn.close()
    os.rmdir(output_dir)

print(f"All files added to Snowflake stage {SNOWFLAKE_DB}.{SNOWFLAKE_SCHEMA}.{STAGE}")
print("="*60)
