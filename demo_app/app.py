from flask import Flask

from demo_app import __version__

app = Flask(__name__)


@app.route("/")
def root():
    return {"__version__": __version__}
