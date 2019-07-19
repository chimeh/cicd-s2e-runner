import os

NGINX_URL = os.environ.get("NGINX_URL", "http://x.ops")
OUTPUT_DIR = os.environ.get("OUTPUT_DIR", "/tmp/xopsx")

GITLAB_URL = os.environ.get("GITLAB_URL", "https://git.nx-code.com")
GITLAB_PRIVATE_TOKEN = os.environ.get("GITLAB_PRIVATE_TOKEN", "")
