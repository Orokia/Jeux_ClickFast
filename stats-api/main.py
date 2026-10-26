
import os

import psycopg2
from fastapi import FastAPI, HTTPException

app = FastAPI(title="ClickFast Stats API")


def get_connection():
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=os.environ.get("DB_PORT", "5432"),
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        connect_timeout=3,
    )


@app.get("/")
def health():
    return {"status": "ok", "service": "stats-api"}


@app.get("/stats")
def get_stats():
    connection = None

    try:
        connection = get_connection()

        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT
                    COALESCE(MAX(score), 0) AS best_score,
                    COUNT(*) AS total_games,
                    COUNT(DISTINCT username) AS distinct_players
                FROM scores
                """
            )
            row = cursor.fetchone()

        return {
            "best_score": row[0],
            "total_games": row[1],
            "distinct_players": row[2],
        }

    except psycopg2.Error:
        raise HTTPException(
            status_code=503,
            detail="La base de données est indisponible.",
        )

    finally:
        if connection is not None:
            connection.close()
