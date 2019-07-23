#!/usr/bin/env python3
import argparse
import os
import contextlib
import tarfile

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



if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='下载 GitLab 项目源代码。')
    parser.add_argument(
        "--dry-run", action='store_true', default=False,
        help='输出将要下载代码的项目，不进行代码下载。',
    )
    parser.add_argument(
        "--ref", required=True,
        help="将要下载的分支名或者TAG名。"
    )
    parser.add_argument(
        "--gitlab-url",
        default=os.environ.get("GITLAB_URL", "https://git.nx-code.com"),
        help='GitLab URL',
    )
    parser.add_argument(
        "--gitlab-private-token",
        default=os.environ.get("GITLAB_PRIVATE_TOKEN", ""),
        help='GitLab private access token',
    )
    parser.add_argument(
        "--output",
        help="输出文件路径",
    )
    run(parser.parse_args())
