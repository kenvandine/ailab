"""ailab: LXD-based sandboxes for running AI tools safely on Ubuntu."""

try:
    from importlib.metadata import version
    __version__ = version("ailab")
except Exception:
    __version__ = "0.0.0"
