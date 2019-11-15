import argparse
import os
import logging
import hashlib
from urllib.parse import urljoin
import nacos-sdk-python

import yaml
import requests

def wait_for_nacos_config_content_changed(nacos_url, data_id, content):
    api = urljoin(nacos_url, "/nacos/v1/cs/configs/listener")
    content_md5 = hashlib.md5(content.encode("utf-8")).hexdigest()

    while True:
        logging.info("Is nacos configuration changed?")
        res = requests.post(
            api,
            headers={"Long-Pulling-Timeout": "30000"},
            data={"Listening-Configs": f"{data_id}\2DEFAULT_GROUP\2{content_md5}\1"},
        )
        assert res.ok, res.text
        if res.text:
            logging.info("Yes!")
            break

def main():
    parser = argparse.ArgumentParser(description="cli tool to deploy multi image into kubernetes namespace")

    parser.add_argument("-d", "--dir", action="store", nargs=1, dest="dir",
                        required=True,
                        default="images.yaml",
                        help="contain name and docker image url for every kubernetes deployment")
    parser.add_argument("-f", "--file", action="store", nargs=1, dest="file",
                        required=False,
                        default="",
                        help="the file to import into nacos")
    parser.add_argument("-u", "--url", action="store", nargs=1, dest="url",
                        required=True,
                        help="the nacos url")
    args = parser.parse_args()



if __name__ == '__main__':
    main()