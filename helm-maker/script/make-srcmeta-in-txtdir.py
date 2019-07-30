#!/usr/bin/env python3
import argparse
import sys
import subprocess
import os


IMG2SRCMETA_PY = os.path.join(os.path.dirname(__file__), "img2srcmeta.py")


def run(args):
    passed = []
    failed = []

    for dirpath, dirnames, filenames in os.walk(args.txtdir):
        if "img.txt" in filenames:
            image = open(os.path.join(dirpath, "img.txt")).read().strip()
            srcmeta = os.path.join(dirpath, "srcmeta.txt")
            with open(srcmeta, "w") as f:
                completed = subprocess.run(
                    [
                        sys.executable,
                        IMG2SRCMETA_PY,
                        f"--image={image}",
                        f"--gitlab-url={args.gitlab_url}",
                        f"--gitlab-private-token={args.gitlab_private_token}",
                        f"--gitlab-group={args.gitlab_group or ''}",
                    ],
                    stdout=f,
                )

                if completed.returncode == 0:
                    passed.append(srcmeta)
                else:
                    failed.append(srcmeta)

    if passed:
        print("生成成功：")
        for x in passed:
            print(f"  {x}")

    if passed:
        print("生成失败：")
        for x in failed:
            print(f"  {x}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser("根据镜像名生成 txtdir 里的 srcmeta.txt 文件。")
    parser.add_argument("--txtdir", required=True, help="txtdir 文件夹路径")
    parser.add_argument(
        "--gitlab-url",
        default=os.environ.get("GITLAB_URL", "https://git.nx-code.com"),
        help="GitLab 地址。",
    )
    parser.add_argument(
        "--gitlab-private-token",
        default=os.environ.get("GITLAB_PRIVATE_TOKEN", ""),
        help="GitLab 访问 token 。",
    )
    parser.add_argument(
        "--gitlab-group", default=None, help="指定 group ，例如：'ice-v3/ice-v3-infra' 。"
    )
    run(parser.parse_args())
