#!/usr/bin/env python3
import os
import sys
import argparse
from urllib.parse import quote

import gitlab


def run(args):
    gl = gitlab.Gitlab(args.gitlab_url, private_token=args.gitlab_private_token)
    gl.auth()

    # 推断 commit
    try:
        image_name, tag = args.image.split(":")
        project_name = image_name.split("/")[-1]

        try:
            # tag: VERSION-BRANCH-REF-X-BUILD
            ref = tag.split("-")[-3]
        except IndexError:
            # tag: COMMIT
            ref = tag

    except ValueError:
        print(f"[ERROR] {args.image} 缺少版本 tag ，无法确认 commit ！", file=sys.stderr)
        sys.exit(1)

    # 推断 project id
    if args.gitlab_group:
        group = gl.groups.get(quote(args.gitlab_group), safe="")
        matched_projects = group.projects.list(
            search=project_name, include_subgroups=True, all=True
        )
    else:
        matched_projects = gl.projects.list(search=project_name, all=True)


    matched_projects = [x for x in matched_projects if x.name == project_name]
    if not matched_projects:
        print(f"[ERROR] 项目 {project_name} 未找到！", file=sys.stderr)
        sys.exit(1)


    try:
        project, = matched_projects
    except ValueError:
        print(f"[ERROR] {project_name}: 存在多个同名的项目：{[i.path_with_namespace for i in matched_projects]} ！", file=sys.stderr)
        sys.exit(1)

    project = gl.projects.get(project.id)

    try:
        commit = project.commits.get(ref)
    except gitlab.GitlabError:
        print(f"[ERROR] {project.path_with_namespace} 不存在 commit {ref} ！", file=sys.stderr)
        sys.exit(1)

    print(f"CI_PROJECT_ID={project.id}")
    print(f"CI_COMMIT_SHA={commit.id}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser("镜像名转 srcmeta.txt")
    parser.add_argument("--image", required=True, help="镜像名。")
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
