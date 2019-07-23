#!/usr/bin/env python3
import argparse
import os
import contextlib

import kubernetes
import gitlab


def run(args):
    gl = gitlab.Gitlab(args.gitlab_url, private_token=args.gitlab_private_token)
    gl.auth()

    targets = set()
    if not args.no_kubernetes:
        kubernetes.config.load_kube_config()
        v1 = kubernetes.client.CoreV1Api()

        for cm in v1.list_namespaced_config_map(args.kubernetes_namespace).items:
            with contextlib.suppress(KeyError):
                meta = {}
                for line in cm.data['srcmeta.txt'].splitlines():
                    key, val = line.partition("=")[::2]
                    meta[key] = val
                targets.add((meta["CI_PROJECT_ID"], meta["CI_COMMIT_SHA"]))

    if args.dry_run:
        print(f"将在以下项目创建 {args.branch_name} 分支：")
        for project_id, _ in targets:
            project = gl.projects.get(project_id)
            print(f"  {project.path_with_namespace}")
    else:
        print(f"创建 {args.branch_name} 分支：")
        for project_id, ref in targets:
            project = gl.projects.get(project_id)
            try:
                project.branches.create({
                    "branch": args.branch_name,
                    "ref": ref,
                })
                print(f"[DONE] {project.path_with_namespace}")
            except gitlab.GitlabError as e:
                print(f"[FAIL] {project.path_with_namespace} -> {e}")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='创建 GitLab 项目分支。')
    parser.add_argument(
        "--dry-run", action='store_true', default=False,
        help='输出将要创建分支的项目，不进行分支创建。',
    )
    parser.add_argument(
        "--branch-name", required=True,
        help='将要创建的分支名。',
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
        "--no-kubernetes", action='store_true', default=False,
        help='不从 kubernetes 获取项目列表。',
    )
    parser.add_argument(
        "--kubernetes-namespace", required=True,
        help='指定 namespace 。',
    )
    run(parser.parse_args())
