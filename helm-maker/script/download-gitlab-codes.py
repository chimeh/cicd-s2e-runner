#!/usr/bin/env python3
import argparse
import os
import contextlib
import tarfile
from tempfile import TemporaryDirectory

import gitlab


def run(args):
    gl = gitlab.Gitlab(args.gitlab_url, private_token=args.gitlab_private_token)
    gl.auth()

    print("正在获取项目列表。。。")

    targets = []
    for project in gl.projects.list(as_list=False):
        with contextlib.suppress(gitlab.GitlabError):
            project.branches.get(args.ref)
            targets.append(project)

        with contextlib.suppress(gitlab.GitlabError):
            project.tags.get(args.ref)
            targets.append(project)

    if args.dry_run:
        print("将获取以下项目的源代码：")
        for project in targets:
            print(f"  {project.path_with_namespace}")
    else:
        with TemporaryDirectory() as t:
            print(f"开始下载项目源代码，总计：{len(targets)}")
            for i, project in enumerate(targets):
                print(f"[{i+1}/{len(targets)}] 下载 {project.path_with_namespace}")
                os.makedirs(
                    os.path.join(t, os.path.dirname(project.path_with_namespace))
                )
                with open(
                    os.path.join(t, project.path_with_namespace + ".tar.gz"), mode="wb"
                ) as f:
                    project.repository_archive(
                        sha=args.ref, streamed=True, action=f.write
                    )

            with tarfile.open(args.output, mode="w|gz") as tar:
                tar.add(t, arcname="source-codes")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="下载 GitLab 项目源代码。")
    parser.add_argument(
        "--dry-run", action="store_true", default=False, help="输出将要下载代码的项目，不进行代码下载。"
    )
    parser.add_argument("--ref", required=True, help="将要下载的分支名或者TAG名。")
    parser.add_argument(
        "--gitlab-url",
        default=os.environ.get("GITLAB_URL", "https://git.nx-code.com"),
        help="GitLab URL",
    )
    parser.add_argument(
        "--gitlab-private-token",
        default=os.environ.get("GITLAB_PRIVATE_TOKEN", ""),
        help="GitLab private access token",
    )
    parser.add_argument("--output", required=True, help="输出文件路径")
    run(parser.parse_args())
