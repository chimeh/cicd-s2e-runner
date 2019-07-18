import os

NGINX_URL = os.environ.get("NGINX_URL", "http://x.ops")
OUTPUT_DIR = os.environ.get("OUTPUT_DIR", "/tmp/xopsx")
