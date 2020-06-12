#!/usr/bin/env python
# -*- coding: utf-8 -*-
# author jimin.huang@benload.com


import os
import re
import openshift
import kubernetes
from kubernetes.client.rest import ApiException
import yaml
import json





def makeconfigmap_from_file(proj, image, rawfile):
    cmd = " oc create configmap %s --from-file %s --dry-run -o yaml" % (image, rawfile)
    print cmd
    rv = os.popen(cmd).read()
    configmap =  yaml.load(rv)
    return configmap



        
def cfg_sync_into_openshift(api, proj, image, cfg):
    configmap_name = image
    configmap_data = cfg
    exist = 0
    try:
        resp = api.read_namespaced_config_map(name=configmap_name, namespace=proj)
        exist = 1
    except ApiException as e:
        resp = api.create_namespaced_config_map(body=configmap_data, namespace=proj)
        exist = 0
    finally:
        if exist == 1:
            resp = api.replace_namespaced_config_map(name=configmap_name, body=configmap_data, namespace=proj)
      



def main():
    kubernetes.config.load_kube_config()
    api = kubernetes.client.CoreV1Api()
    
    CFG_ROOT = os.environ.get("CFG_ROOT", '~/cfg/raw')
    projs = [f for f in os.listdir(CFG_ROOT) if not re.match(r'openshift|default|kube|logging', f)]
    for p in projs:
    #    print p
        images = [f for f in os.listdir(os.path.join(CFG_ROOT, p)) if not re.match(r'-TOBEFILL--', f)]
        for i in images:
            cfg = os.path.join(CFG_ROOT, p, i, "env.txt")
            print("project %s image %s's config %s importting" % (p, i, cfg))
            configmap = makeconfigmap_from_file(p, i, cfg)
            print yaml.dump(configmap)
            cfg_sync_into_openshift(api, p, i, configmap)
    #        cfg_sync_into_k8s(p, i, cfg)
    #        print env   

if __name__ == '__main__':
    main()
