"""
Loads the 5 raw CSVs into a local SQLite database (db/game.db).
Run this once (or whenever raw data changes) from the project root:

    python db/build_db.py
"""
import sqlite3
from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = ROOT / "data" / "raw"
DB_PATH = ROOT / "db" / "game.db"

FILES = {
    "player_profile": RAW_DIR / "player_profile.csv",
    "player_day": RAW_DIR / "player_day.csv",
    "purchase": RAW_DIR / "purchase.csv",
    "currency_spend": RAW_DIR / "currency_spend.csv",
    "ad_view": RAW_DIR / "ad_view.csv",
}


def build():
    conn = sqlite3.connect(DB_PATH)
    for table, path in FILES.items():
        df = pd.read_csv(path)
        df.to_sql(table, conn, if_exists="replace", index=False)
        print(f"Loaded {table}: {df.shape[0]:,} rows, {df.shape[1]} cols")
    conn.commit()
    conn.close()
    print(f"\nDatabase built at {DB_PATH}")


if __name__ == "__main__":
    build()
