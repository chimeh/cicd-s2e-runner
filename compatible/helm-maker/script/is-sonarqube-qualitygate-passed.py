#!/usr/bin/env python3
from urllib.parse import urljoin
import argparse
import sys

import requests


def run(sonarqube_url, ce_task_id):

    while True:
        ce_task = requests.get(
            urljoin(sonarqube_url, "/api/ce/task"), params={"id": ce_task_id}
        ).json()
        status = ce_task["task"]["status"]

        if status == "SUCCESS":
            break

        if status == "CANCELED":
            print("Task canceled!", file=sys.stderr)
            exit(1)

        if status == "FAILED":
            print("Task failed!", file=sys.stderr)
            exit(1)

        time.sleep(3)

    analysis_id = ce_task["task"]["analysisId"]
    qualitygate = requests.get(
        urljoin(sonarqube_url, "/api/qualitygates/project_status"),
        params={"analysisId": analysis_id},
    ).json()

    status = qualitygate["projectStatus"]["status"]
    if status == "ERROR":
        print("Failed to pass the quality gate!", file=sys.stderr)
        exit(1)

    print("Passed!")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--sonarqube-url", required=True, help="SonarQube URL")
    parser.add_argument("--ce-task-id", required=True, help="report-task.txt: ceTaskId")
    args = parser.parse_args()
    run(args.sonarqube_url, args.ce_task_id)
