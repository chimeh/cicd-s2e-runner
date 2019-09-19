#!/usr/bin/env python
# -*- coding: utf-8 -*-
# author jimin.huang@nx-engine.com

import sys
import os
sys.path.append("%s" % (os.path.dirname(os.path.realpath(__file__))))

import re
import kubernetes
from kubernetes.client.rest import ApiException
import yaml
import json
import argparse
import warnings
import glob
import subprocess
import k8s_templatemaker
import k8s_ingress_template

def sync_k8s_ingress_into_k8s(api, proj, name, body):
    exist = 0
    try:
        resp = api.read_namespaced_ingress(name=name, namespace=proj)
        exist = 1
    except ApiException as e:
        resp = api.create_namespaced_ingress(body=body, namespace=proj)
        exist = 0
    finally:
        if exist == 1:
            resp = api.replace_namespaced_ingress(name=name, body=body, namespace=proj)
            
def sync_kong_resourse_into_k8s(api, group, version, proj, plural, name, body):
    exist = 0
    try:
        resp = api.get_namespaced_custom_object(group=group,
                                                version=version, 
                                                namespace=proj,
                                                plural=plural,
                                                name=name)
        exist = 1
    except ApiException as e:
        resp = api.create_namespaced_custom_object(group=group,
                                                version=version, 
                                                namespace=proj,
                                                plural=plural,
                                                body=body)
        exist = 0
    finally:
        if exist == 1:
            body['metadata']['resourceVersion'] = "%d" % (int(resp['metadata']['resourceVersion']))
            yaml.dump(body, os.sys.stdout, default_flow_style=False)
            resp = api.replace_namespaced_custom_object(group=group,
                                                version=version, 
                                                namespace=proj,
                                                plural=plural,
                                                name=name,
                                                body=body)

def sync_cfg_into_k8s(api, proj, name, cfg):
    configmap_name = name
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
      
def sync_deploy_into_k8s(api, proj, name, deployment):
    deploy_name = name
    deploy_data = deployment
    exist = 0
    try:
        resp = api.read_namespaced_deployment(name=deploy_name, namespace=proj, exact=False, async_req=False)
        exist = 1
    except ApiException as e:
        resp = api.create_namespaced_deployment(body=deploy_data, namespace=proj, async_req=False)
        exist = 0
    finally:
        if exist == 1:
            resp = api.replace_namespaced_deployment(name=deploy_name, body=deploy_data, namespace=proj, async_req=False)
            
def sync_service_into_k8s(api, proj, name, service):
    exist = 0
    #try:
    #    resp = api.read_namespaced_service(name=name, namespace=proj, async_req=False)
    #    exist = 1
    #except ApiException as e:
    #    resp = api.create_namespaced_service(body=service, namespace=proj, async_req=False)
    #    exist = 0
    #finally:
    #    if exist == 1:
    #        resp = api.patch_namespaced_service(name=name, body=service, namespace=proj, async_req=False)
    try:
        V1DeleteOptions = kubernetes.client.V1DeleteOptions()
        resp = api.delete_namespaced_service(name=name, namespace=proj, body=V1DeleteOptions, async_req=False)
    except ApiException as e:
        pass
    finally:
        resp = api.create_namespaced_service(body=service, namespace=proj, async_req=False)

def main():
    parser = argparse.ArgumentParser(description='pushing kubernetes resources from k8s deploy/configmap repo center.')
    
    parser.add_argument("-r", "--repo-center", action="store", nargs=1, dest="repo",  
                        required=True,
                        default="deployment",
                        help="the ROOT of kubernetes repo center. namespace match env K8S_DISABLE_NS will ignore")
                        
    parser.add_argument("-t", "--type", action="store", nargs=1, choices=['deployment', 'configmap', 'internal-ingress',"public-ingress", "custom-resource"],
                        dest="type",  
                        required=True,
                        default="deployment",
                        help="the resource TYPE of kubernetes on repo to push into kubernetes platform.")
    args = parser.parse_args()
        
    
    kubernetes.config.load_kube_config()
    corev1api = kubernetes.client.CoreV1Api()
    extensionsv1beta1api = kubernetes.client.ExtensionsV1beta1Api()
    customobjectsapi = kubernetes.client.CustomObjectsApi()
    if args.repo[0] is None:
        CFG_ROOT = os.path.realpath(os.environ.get("CFG_ROOT", '~/cfg/raw'))
    else:
        CFG_ROOT = os.path.realpath(args.repo[0])
    print("start pushing %s from repo %s to kubernetes" % (args.type[0], CFG_ROOT))
    projs = [f for f in os.listdir(CFG_ROOT) if not re.match(r'openshift|kube|logging', f)]
    for p in projs:
        ignore_proj = "%s" % (os.environ.get("K8S_DISABLE_NS", 'openshift|kube|logging'))
        if re.match(ignore_proj, p):
            print "ns %s match K8S_DISABLE_NS %s, ignore, will not pushing into k8s" % (p, ignore_proj)
            continue
        names = [f for f in os.listdir(os.path.join(CFG_ROOT, p)) if not re.match(r'-TOBEFILL--', f)]
        for name in names:
            disable_deploy = os.path.join(CFG_ROOT, p, name, "disable-deploy.txt")
            if os.path.exists(disable_deploy) and args.type[0] != "custom-resource":
                print ("%s exist, only support custom-resource" % ("disable-deploy.txt") )
                continue
            if args.type[0] == "deployment":
                entrypoint_override_path = os.path.join(CFG_ROOT, p, name, "default-entrypoint.sh")
                if os.path.exists(entrypoint_override_path):
                    ep_override = True
                else:
                    ep_override = False
                imagef = os.path.join(CFG_ROOT, p, name, "img.txt")
                with open(imagef, 'r') as f:
                    lines = f.readlines()
                    image_url = lines[0]
                    f.close()
                image_name_from_url  = image_url.split('/')[-1].split(':')[0]
                if image_name_from_url != name:
                    print("warn: highly recommended name %s same as %s from url %s" % (name, image_name_from_url, image_url))
                image_info = k8s_templatemaker.docker_image_inspect(image_url)
                
                print("pushing project %s name %s's %s image %s, entrypoint override: %s" % (p, name, "deployment", image_url.rstrip('\n') , ep_override))
                deploy = k8s_templatemaker.gen_deployment_yaml(image_info, name, ep_override)
#                yaml.dump(deploy, os.sys.stdout, default_flow_style=False)
                sync_deploy_into_k8s(extensionsv1beta1api, p, name, deploy)
                
                print("pushing project %s name %s's %s for %s" % (p, name, "service", image_url))
                service = k8s_templatemaker.gen_service_yaml(image_info, name)
#                yaml.dump(service, os.sys.stdout, default_flow_style=False)
                sync_service_into_k8s(corev1api, p, name, service)
            elif args.type[0] == "configmap":
                entrypoint_override_path = os.path.join(CFG_ROOT, p, name, "default-entrypoint.sh")
                if os.path.exists(entrypoint_override_path):
                    ep_override = True
                else:
                    ep_override = False
                env = os.path.join(CFG_ROOT, p, name, "env.txt")
                if ep_override is True:
                    ep = os.path.join(CFG_ROOT, p, name, "default-entrypoint.sh")
                    print("pushing project %s name %s's %s %s %s" % (p, name, args.type[0], env, ep))
                    configmap = k8s_templatemaker.makeconfigmap_from_2file(name, env, ep)
                
                else:
                    print("pushing project %s name %s's %s %s" % (p, name, args.type[0], env))
                    configmap = k8s_templatemaker.makeconfigmap_from_file(name, env)
                
#                yaml.dump(configmap, os.sys.stdout, default_flow_style=False)
                sync_cfg_into_k8s(corev1api, p, name, configmap)
            elif args.type[0] == "internal-ingress":
                igr_name = "%s-%s" % (name, "internal")
                k8singress = os.path.join(CFG_ROOT, p, name, "internal.k8singress.yaml")
                if os.path.exists(k8singress):
                    print("pushing project %s name %s's %s from img %s" % (p, name, "k8singress", k8singress))
                    k8s_yaml = k8s_ingress_template.gen_k8singress_from_file(k8singress, name=name, ingress_class="kong-ingress-internal")
                else:
                    imagef = os.path.join(CFG_ROOT, p, name, "img.txt")
                    print("pushing project %s name %s's %s %s from yaml %s" % (p, name, args.type[0], "k8singress", imagef))
                    with open(imagef, 'r') as f:
                        lines = f.readlines()
                        image_url = lines[0]
                        f.close()
                    image_info = k8s_templatemaker.docker_image_inspect(image_url)
                    k8singress_dns = os.path.join(CFG_ROOT, p, name, "internal.k8singress-dns.txt")
                    if not os.path.exists(k8singress_dns):
                        print "warn dont provide internal.k8singress.yaml, or internal.k8singress-dns.txt"
                        continue
                    with open(k8singress_dns, 'r') as f:
                        line = f.readline()
                        image_url = lines[0]
                        f.close()
                        dns_suffix = "%s-%s.%s" % (name, p, line.rstrip('\r\n'))
                    k8s_yaml = k8s_ingress_template.gen_k8singress_from_image(image_info, name, "kong-ingress-internal", dns_suffix)
                    
                kongingress = os.path.join(CFG_ROOT, p, name, "internal.kongingress.yaml")
                if os.path.exists(kongingress):
                    print("pushing project %s name %s's %s %s from yaml %s" % (p, name, args.type[0], "kongingress", kongingress))
                    kongingress_yaml = k8s_ingress_template.gen_kongingress_from_file(kongingress, name)
                else:
                    print("pushing project %s name %s's %s %s from default" % (p, name, args.type[0], "kongingress"))
                    kongingress_yaml = k8s_ingress_template.gen_kongingress_default(name)
                kongingress_yaml['metadata']['name'] = igr_name
                k8s_yaml['metadata']['name'] = igr_name
                yaml.dump(kongingress_yaml, os.sys.stdout, default_flow_style=False)
                yaml.dump(k8s_yaml, os.sys.stdout, default_flow_style=False)
                sync_kong_resourse_into_k8s(customobjectsapi, 
                                            group="configuration.konghq.com",
                                            version="v1",
                                            proj=p,
                                            plural="kongingresses",
                                            name= igr_name,
                                            body=kongingress_yaml)            
                sync_k8s_ingress_into_k8s(extensionsv1beta1api, p, igr_name, k8s_yaml)
            elif args.type[0] == "public-ingress":
                igr_name = "%s-%s" % (name, "public")
                k8singress = os.path.join(CFG_ROOT, p, name, "public.k8singress.yaml")
                if os.path.exists(k8singress):
                    print("pushing project %s name %s's %s from img %s" % (p, name, "k8singress", k8singress))
                    k8s_yaml = k8s_ingress_template.gen_k8singress_from_file(k8singress, name, ingress_class="kong-ingress-public")
                else:
                    imagef = os.path.join(CFG_ROOT, p, name, "img.txt")
                    print("pushing project %s name %s's %s %s from yaml %s" % (p, name, args.type[0], "k8singress", imagef))
                    with open(imagef, 'r') as f:
                        lines = f.readlines()
                        image_url = lines[0]
                        f.close()
                    image_info = k8s_templatemaker.docker_image_inspect(image_url)
                    k8singress_dns = os.path.join(CFG_ROOT, p, name, "public.k8singress-dns.txt")
                    if not os.path.exists(k8singress_dns):
                        print "warn dont provide public.k8singress.yaml, or public.k8singress-dns.txt"
                        continue
                    with open(k8singress_dns, 'r') as f:
                        line = f.readline()
                        image_url = lines[0]
                        f.close()
                        dns_suffix = "%s-%s.%s" % (name, p, line.rstrip('\r\n'))
                    k8s_yaml = k8s_ingress_template.gen_k8singress_from_image(image_info, name, "kong-ingress-public", dns_suffix)
                    
                kongingress = os.path.join(CFG_ROOT, p, name, "public.kongingress.yaml")
                if os.path.exists(kongingress):
                    print("pushing project %s name %s's %s %s from yaml %s" % (p, name, args.type[0], "kongingress", kongingress))
                    kongingress_yaml = k8s_ingress_template.gen_kongingress_from_file(kongingress, name)
                else:
                    print("pushing project %s name %s's %s %s from default" % (p, name, args.type[0], "kongingress"))
                    kongingress_yaml = k8s_ingress_template.gen_kongingress_default(name)
                    
                kongingress_yaml['metadata']['name'] = igr_name
                k8s_yaml['metadata']['name'] = igr_name
                yaml.dump(kongingress_yaml, os.sys.stdout, default_flow_style=False)
                yaml.dump(k8s_yaml, os.sys.stdout, default_flow_style=False)
                sync_kong_resourse_into_k8s(customobjectsapi, 
                                            group="configuration.konghq.com",
                                            version="v1",
                                            proj=p,
                                            plural="kongingresses",
                                            name= igr_name,
                                            body=kongingress_yaml)            
                sync_k8s_ingress_into_k8s(extensionsv1beta1api, p, igr_name, k8s_yaml)
            elif args.type[0] == "custom-resource":
                pattern = "%s/%s" % (os.path.join(CFG_ROOT, p, name), "custom-*.yaml")
                custom = glob.glob(pattern)
                if len(custom) != 0:
                    for f in custom:
                        cmd = "kubectl apply -n %s -f %s" % (p, f)
                        print cmd
                        s=subprocess.Popen(cmd,shell=True,
                            stdin = subprocess.PIPE, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
                        (output, err) = s.communicate()
                        print ("%s%s" % (output, err))
                    
            else:
                parser.print_help()
if __name__ == '__main__':
    main()
