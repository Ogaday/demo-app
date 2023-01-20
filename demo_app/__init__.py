from importlib import metadata

try:
    __version__ = metadata.version("demo_app")
except metadata.PackageNotFoundError:
    __version__ = "0.0.0"
