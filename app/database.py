"""Database connection manager and lifecycle hooks for SQLite 3."""

import sqlite3
import click
from flask import current_app, g


def get_db() -> sqlite3.Connection:
    """Open or reuse a thread-local SQLite connection with foreign keys enabled."""
    if "db" not in g:
        g.db = sqlite3.connect(
            current_app.config["DATABASE"],
            detect_types=sqlite3.PARSE_DECLTYPES,
            timeout=30.0,
        )
        g.db.row_factory = sqlite3.Row
        g.db.execute("PRAGMA foreign_keys = ON;")
        # Enable WAL mode for concurrent read performance (ignored in in-memory test databases)
        if current_app.config["DATABASE"] != ":memory:":
            try:
                g.db.execute("PRAGMA journal_mode = WAL;")
            except sqlite3.OperationalError:
                pass
    return g.db


def close_db(e=None) -> None:
    """Close connection at the end of the request context."""
    db = g.pop("db", None)
    if db is not None:
        db.close()


def init_db() -> None:
    """Read and execute schema.sql to create tables and indexes."""
    db = get_db()
    with current_app.open_resource("schema.sql") as f:
        db.executescript(f.read().decode("utf-8"))


@click.command("init-db")
def init_db_command() -> None:
    """CLI command: Clear existing data and create new tables."""
    init_db()
    click.echo("Initialized the HimYatra SQLite database.")


def init_app(app) -> None:
    """Register database teardown and CLI commands on the Flask app."""
    app.teardown_appcontext(close_db)
    app.cli.add_command(init_db_command)
