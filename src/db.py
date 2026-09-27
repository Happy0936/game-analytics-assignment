"""Shared DB connection helper so every notebook connects the same way."""
import sqlite3
from pathlib import Path
import pandas as pd

DB_PATH = Path(__file__).resolve().parent.parent / "db" / "game.db"


def get_connection():
    return sqlite3.connect(DB_PATH)


def run_sql_file(path, conn=None):
    """Run a .sql file and return the result as a DataFrame."""
    own_conn = conn is None
    conn = conn or get_connection()
    query = Path(path).read_text()
    df = pd.read_sql_query(query, conn)
    if own_conn:
        conn.close()
    return df
