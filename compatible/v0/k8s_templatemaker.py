#!/usr/bin/env python
# -*- coding: utf-8 -*-
# author jimin.huang@benload.com


import os
import re
import string
#import kubernetes
#from kubernetes.client.rest import ApiException
import yaml
import json
import subprocess
import time
import argparse
    

def makeconfigmap_from_2file(image, rawfile1, rawfile2):
    name1 =  rawfile1.split('/')[-1]
    name2 =  rawfile2.split('/')[-1]
    cmd = " oc create configmap %s --from-file=%s=%s --from-file=%s=%s --dry-run -o yaml" % (image, name1, rawfile1, name2, rawfile2)
    rv = os.popen(cmd).read()
    configmap =  yaml.load(rv, Loader=yaml.FullLoader)
    #yaml.dump(configmap, os.sys.stdout, default_flow_style=False)
    return configmap    
def makeconfigmap_from_file(image, rawfile):
    cmd = " oc create configmap %s --from-file %s --dry-run -o yaml" % (image, rawfile)
    rv = os.popen(cmd).read()
    configmap =  yaml.load(rv, Loader=yaml.FullLoader)
    #yaml.dump(configmap, os.sys.stdout, default_flow_style=False)
    return configmap
    
def load_deployment_template(path):
    with open(path, 'r') as s:
        try:
            template = yaml.load(s, Loader=yaml.FullLoader)
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
            template = yaml.load(s, Loader=yaml.FullLoader)
            #print(template)
            #yaml.dump(template, os.sys.stdout)
        except yaml.YAMLError as e:
            print(e)
        finally:
            s.close()
    return template
    
def gen_deployment_yaml( image_info, name, entrypoint_override): 
    template = load_deployment_template("%s/%s" % (os.path.dirname(os.path.realpath(__file__)), "deployment.template.yaml"))
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
    template['spec']['template']['spec']['volumes'][0]['configMap']["defaultMode"] = 421
    template['spec']['template']['spec']['volumes'][0]['configMap']["items"][0]["name"] = "%s" % (name)
    template['spec']['template']['spec']['volumes'][0]['configMap']["items"][0]["key"] = "env.txt"
    template['spec']['template']['spec']['volumes'][0]['configMap']["items"][0]["path"] = "env.txt"
    if entrypoint_override == True:
        template['spec']['template']['spec']['containers'][0]['command'] = ["/cfg/default-entrypoint.sh"]
        template['spec']['template']['spec']['containers'][0]['args'] = image_info['Config']['Cmd']
        ep = {}
        ep["name"] = "%s-ep" % (name)
        ep["key"] = "default-entrypoint.sh"
        ep["path"] = "default-entrypoint.sh"
        template['spec']['template']['spec']['volumes'][0]['configMap']["items"].append(ep)
    #yaml.dump(template, os.sys.stdout, default_flow_style=False)
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
    return template


def gen_service_yaml(image_info, name):
    template = load_service_template("%s/%s" % (os.path.dirname(os.path.realpath(__file__)), "service.template.yaml"))
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
        
    template['spec']['selector']['qcloud-app'] = name
    #yaml.dump(template, os.sys.stdout, default_flow_style=False)
    return template
    
def docker_image_inspect(image):
    cmd = "docker image inspect %s" % (image)
    p=subprocess.Popen(cmd,shell=True,
                        stdin = subprocess.PIPE, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
    p.communicate() 
    if p.returncode != 0:
        print "info: image %s not exist, pull first, wail" % (image)
        cmd = "docker pull %s" % (image)
        p=subprocess.Popen(cmd,shell=True,
                            stdin = subprocess.PIPE, stdout = subprocess.PIPE, stderr = subprocess.PIPE) 
        time.sleep(1) 
        (output, err) = p.communicate()
#        print output, err
    
    cmd = "docker image inspect %s" % (image)
    p=subprocess.Popen(cmd,shell=True,
                        stdin = subprocess.PIPE, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
    (output, err) = p.communicate()
#    print output, err
    rv = output
#    rv = p.stdout.read()
    deploy =  yaml.load(rv, Loader=yaml.FullLoader)[0]
    return deploy
    
def main():
    
    parser = argparse.ArgumentParser(description='Generate a kubernetes resources yaml from docker image.')
    
    parser.add_argument("-i", "--image", action="store", nargs=1, dest="image", required=True, 
                        help="the docker IMAGE to be deploy into kubernetes.")
    parser.add_argument("-n", "--name", action="store", nargs=1, dest="name", required=False, 
                        help="the name to be deploy into kubernetes.")
    parser.add_argument("-e", "--entrypoint-override", action="store_true",
                        dest="entrypoint_override",  
                        required=False,
                        default=False,
                        help="override the entrypoint of the image on deplyment of the image.")
    parser.add_argument("-t", "--type", action="store", nargs=1, choices=['deployment', 'service', 'configmap'], dest="type",  
                         required=True,
                        default="deployment",
                        help="the yaml TYPE of kubernetes to generate.")
    parser.add_argument("-c", "--configmap-raw-file", action="store", nargs=1, dest="configmap_rawfile", required=False, 
                        help="the rawfile to genarate configmap.")
    args = parser.parse_args()
    if args.name is None:
       name = args.image[0].split('/')[-1].split(':')[0]
    else:
        name = args.name[0]
    
    if args.configmap_rawfile is None:
        subprocess.Popen('ln -sf /dev/null /tmp/env.txt', shell=True,
                            stdin = subprocess.PIPE, stdout = subprocess.PIPE, stderr = subprocess.PIPE).communicate() 
        configmap_rawfile = "/tmp/env.txt"
    else:
        configmap_rawfile = os.path.realpath(args.configmap_rawfile[0])
    
    name = "%s" % (name)
    #print "###args.image"  
    #print "###args.type"  
    #print "###name"
    
    #print "###gen %s %s yaml file for image %s" % (name, args.type[0], args.image[0])
    #yaml.dump(image_info, os.sys.stdout, default_flow_style=False)
    if args.type[0] == "deployment":
        #print "### load template"
        #print "### gen deploy yaml"
        image_info = docker_image_inspect(args.image[0])
        deploy = gen_deployment_yaml(image_info = image_info, name = name, entrypoint_override=args.entrypoint_override)
        yaml.dump(deploy, os.sys.stdout, default_flow_style=False)
    elif args.type[0] == "service":
        image_info = docker_image_inspect(args.image[0])
        service = gen_service_yaml(image_info = image_info, name = name)
        yaml.dump(service, os.sys.stdout, default_flow_style=False)
    elif args.type[0] == "configmap":
        configmap = makeconfigmap_from_file(args.image[0], configmap_rawfile);
        yaml.dump(configmap, os.sys.stdout, default_flow_style=False)
    else:
        parser.print_help()



if __name__ == '__main__':
    main()


