#!/usr/bin/env python
# -*- coding: utf-8 -*-
# author jimin.huang@benload.com


import os
import re
import string
import kubernetes
from kubernetes.client.rest import ApiException
import yaml
import json
import subprocess
import time
        
import argparse
    
def load_deployment_template(path):
    with open(path, 'r') as s:
        try:
            template = yaml.load(s)
            #print(template)
            #yaml.dump(template, os.sys.stdout, default_flow_style=False)
        except yaml.YAMLError as e:
            print(e)
            
        finally:
            s.close()
    return template
def load_service_template(path):
    with open(path, 'r') as s:
        try:
            template = yaml.load(s)
            #print(template)
            #yaml.dump(template, os.sys.stdout)
        except yaml.YAMLError as e:
            print(e)
        finally:
            s.close()
    return template
    
def gen_deployment_yaml(template, image_info, name): 
    template['metadata']['name'] = name
    template['metadata']['annotations']['description'] = "auto gen service yaml for %s" % (name)
    template['metadata']['annotations']['yaml-genarate-by'] =  os.environ.get("NXE-GENARATE-BY", 'none')
    template['metadata']['annotations']['yaml-genarate-date'] =  time.strftime('%Y%m%d%H%M%S',time.localtime(time.time()))
    template['metadata']['annotations']['yaml-template-vcs'] =  os.environ.get("NXE-TEMPLATE-VCS", 'none')
    template['metadata']['labels']['qcloud-app'] = name
    template['spec']['selector']['matchLabels']['qcloud-app'] = name
    template['spec']['template']['metadata']['labels']['qcloud-app']  = name
    #template['spec']['template']['spec']['containers'][0]['image']  = image_info['RepoDigests'][0]
    template['spec']['template']['spec']['containers'][0]['image']  = image_info['RepoTags'][-1]
    template['spec']['template']['spec']['containers'][0]['name']  = name  
    template['spec']['template']['spec']['containers'][0]['ports'] = []
    for p in image_info['Config']['ExposedPorts']:
        (port, proto) = p.split('/')
        #print(port, proto)
        entry = {}
        entry['name'] = p.translate(string.maketrans('/','-'))
        entry['containerPort'] = int(port)
        entry['protocol'] = proto.upper()
        template['spec']['template']['spec']['containers'][0]['ports'].append(entry)
        
    template['spec']['template']['spec']['containers'][0]['volumeMounts'][0]["name"] = name
    template['spec']['template']['spec']['containers'][0]['volumeMounts'][0]["mountPath"] = "/cfg/"
    
    template['spec']['template']['spec']['volumes'][0]['name'] = name
    template['spec']['template']['spec']['volumes'][0]['configMap']["name"] = name
    template['spec']['template']['spec']['volumes'][0]['configMap']["defaultMode"] = 420
    template['spec']['template']['spec']['volumes'][0]['configMap']["items"][0]["name"] = "%s" % (name)
    template['spec']['template']['spec']['volumes'][0]['configMap']["items"][0]["key"] = "env.txt"
    template['spec']['template']['spec']['volumes'][0]['configMap']["items"][0]["path"] = "env.txt"
    
    resources = template['spec']['template']['spec']['containers'][0]['resources']
    
    labels = image_info['Config']['Labels']
    if labels is not None:
        if 'spec.template.spec.containers.resources.limits.cpu' in labels:
            resources['limits']['cpu'] = labels['spec.template.spec.containers.resources.limits.cpu']
        if labels.has_key('spec.template.spec.containers.resources.limits.memory'):
            resources['limits']['memory'] = labels['spec.template.spec.containers.resources.limits.memory']
        if labels.has_key('spec.template.spec.containers.resources.requests.cpu'):
            resources['requests']['cpu'] = labels['spec.template.spec.containers.resources.requests.cpu']
        if labels.has_key('spec.template.spec.containers.resources.requests.memory'):
            resources['requests']['memory'] = labels['spec.template.spec.containers.resources.requests.memory']
        template['spec']['template']['spec']['containers'][0]['resources'] = resources
    yaml.dump(template, os.sys.stdout, default_flow_style=False)
    


def gen_service_yaml(template, image_info, name):
    template['metadata']['name'] = name
    template['metadata']['annotations']['description'] = "auto gen service yaml for %s" % (name)
    template['metadata']['annotations']['yaml-genarate-by'] =  os.environ.get("NXE-GENARATE-BY", 'none')
    template['metadata']['annotations']['yaml-genarate-date'] =  time.strftime('%Y%m%d%H%M%S',time.localtime(time.time()))
    template['metadata']['annotations']['yaml-template-vcs'] =  os.environ.get("NXE-TEMPLATE-VCS", 'none')
    template['metadata']['labels']['qcloud-app'] = name
    
    template['spec']['ports'] = []
    for p in image_info['Config']['ExposedPorts']:
        (port, proto) = p.split('/')
        entry = {}
        entry['name'] = p.translate(string.maketrans('/','-')).lower()
        entry['protocol'] = proto.upper()
        entry['port'] = int(port)
        template['spec']['ports'].append(entry)
    template['spec']['type'] = "ClusterIP"    
    template['spec']['selector']['qcloud-app'] = name
    yaml.dump(template, os.sys.stdout, default_flow_style=False)
    
def docker_image_inspect(image):
    cmd = "docker image inspect %s" % (image)
    p=subprocess.Popen(cmd,shell=True,
                        stdin = subprocess.PIPE, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
    p.wait()
    if p.returncode != 0:
        cmd = "docker pull %s" % (image)
        p=subprocess.Popen(cmd,shell=True,
                            stdin = subprocess.PIPE, stdout = subprocess.PIPE, stderr = subprocess.PIPE) 
        
    cmd = "docker image inspect %s" % (image)
    p=subprocess.Popen(cmd,shell=True,
                        stdin = subprocess.PIPE, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
    p.wait()                   
    rv = p.stdout.read()
    deploy =  yaml.load(rv)[0]
    return deploy
    
def main():
    parser = argparse.ArgumentParser(description='Generate a kubernetes resources yaml from docker image.')
    
    parser.add_argument("-i", "--image", action="store", nargs=1, dest="image", required=True, 
                        help="the docker IMAGE to be deploy into kubernetes.")
    parser.add_argument("-n", "--name", action="store", nargs=1, dest="name", required=False, 
                        help="the name to be deploy into kubernetes.")
    parser.add_argument("-t", "--type", action="store", nargs=1, choices=['deployment', 'service'], dest="type",  
                        default="deployment",
                        help="the yaml TYPE of kubernetes to generate.")
    args = parser.parse_args()
    if args.name is None:
       name = args.image[0].split('/')[-1].split(':')[0]
    else:
        name = args.name[0]
    #print "###args.image"  
    #print "###args.type"  
    #print "###name"
    
    #print "###gen %s %s yaml file for image %s" % (name, args.type[0], args.image[0])
    image_info = docker_image_inspect(args.image[0])
    #yaml.dump(image_info, os.sys.stdout, default_flow_style=False)
    if args.type[0] == "deployment":
        #print "### load template"
        t = load_deployment_template("%s/%s" % (os.path.dirname(os.path.realpath(__file__)), "deployment.template.yaml"))
        #print "### gen deploy yaml"
        gen_deployment_yaml(t, image_info = image_info, name = name)
    elif args.type[0] == "service":
        t = load_service_template("%s/%s" % (os.path.dirname(os.path.realpath(__file__)), "service.template.yaml"))
        gen_service_yaml(t, image_info = image_info, name = name)
    else:
        parser.print_help()




    
if __name__ == '__main__':
    main()


