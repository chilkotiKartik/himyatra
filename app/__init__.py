import os
from flask import Flask, render_template
from app.database import init_app


def create_app():
    """Minimal application factory."""
    app = Flask(__name__, instance_relative_config=True)

    app.config.from_mapping(
        SECRET_KEY=os.environ.get("SECRET_KEY", "himyatra-dev-key"),
        DATABASE=os.path.join(app.instance_path, "himyatra.db"),
    )

    try:
        os.makedirs(app.instance_path, exist_ok=True)
    except OSError:
        pass

    init_app(app)

    @app.route("/")
    def index():
        return render_template("index.html")

    return app
