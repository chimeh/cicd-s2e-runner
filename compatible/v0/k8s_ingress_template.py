#!/usr/bin/env python
# -*- coding: utf-8 -*-
# author jimin.huang@nx-engine.com


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
import traceback

    

def load_yaml_file(path):
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
def gen_kongingress_from_file(fpath, name):
    template = load_yaml_file(os.path.realpath(fpath))
    template['metadata']['name'] = name
    template['metadata']['labels']['qcloud-app'] = name
    template['metadata']['annotations']['description'] = "auto gen kongingress yaml for %s" % (name)
    template['metadata']['annotations']['yaml-genarate-by'] =  os.environ.get("NXE-GENARATE-BY", 'none')
    template['metadata']['annotations']['yaml-genarate-date'] =  time.strftime('%Y%m%d%H%M%S',time.localtime(time.time()))
    template['metadata']['annotations']['yaml-genarate-from'] =  fpath
    return template
    
def gen_kongingress_default( name):
    template = load_yaml_file("%s/%s" % (os.path.dirname(os.path.realpath(__file__)), "kongingress.template.yaml"))
    template['metadata']['name'] = name
    template['metadata']['labels']['qcloud-app'] = name
    template['metadata']['annotations']['description'] = "auto gen kongingress yaml for %s" % (name)
    template['metadata']['annotations']['yaml-genarate-by'] =  os.environ.get("NXE-GENARATE-BY", 'none')
    template['metadata']['annotations']['yaml-genarate-date'] =  time.strftime('%Y%m%d%H%M%S',time.localtime(time.time()))
    return template
    
def gen_k8singress_from_file(fpath, name, ingress_class):
    template = load_yaml_file(os.path.realpath(fpath))
    template['metadata']['name'] = name
    template['metadata']['labels']['qcloud-app'] = name
    template['metadata']['annotations']['description'] = "auto gen ingress yaml for %s" % (name)
    template['metadata']['annotations']['yaml-genarate-by'] =  os.environ.get("NXE-GENARATE-BY", 'none')
    template['metadata']['annotations']['yaml-genarate-date'] =  time.strftime('%Y%m%d%H%M%S',time.localtime(time.time()))
    template['metadata']['annotations']['yaml-genarate-from'] =  fpath
    template['metadata']['annotations']['kubernetes.io/ingress.class'] =  ingress_class
    return template

def gen_k8singress_from_image(image_info, name, ingress_class, dns_suffix):
    template = load_yaml_file("%s/%s" % (os.path.dirname(os.path.realpath(__file__)), "ingress.template.yaml"))
    template['metadata']['name'] = name
    template['metadata']['labels']['qcloud-app'] = name
    template['metadata']['annotations']['kubernetes.io/ingress.class'] = ingress_class
    template['metadata']['annotations']['description'] = "auto gen k8singress yaml for %s" % (name)
    template['metadata']['annotations']['yaml-genarate-by'] =  os.environ.get("NXE-GENARATE-BY", 'none')
    template['metadata']['annotations']['yaml-genarate-date'] =  time.strftime('%Y%m%d%H%M%S',time.localtime(time.time()))
    template['spec']['rules'] = []
    for p in image_info['Config']['ExposedPorts']:
        (port, proto) = p.split('/')
        #print(port, proto)
        entry = {}
        entry['host'] = "port-%s-%s" % (port, dns_suffix)
#        entry['http'] = p.translate(string.maketrans('/','-'))
        entry['http'] = {}
        entry['http']['paths'] = []
        path={}
        path['path'] = "/"
        path['backend'] = {}
        path['backend']['serviceName'] = name
        path['backend']['servicePort'] = int(port)
        entry['http']['paths'].append(path)
        template['spec']['rules'].append(entry)
        template['metadata']['annotations'][ingress_class] = "http://%s" % (entry['host'])
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
    deploy =  yaml.load(rv)[0]
    return deploy
    
def main():
    
    parser = argparse.ArgumentParser(description='Generate a kubernetes resources yaml from docker image.')
    
    parser.add_argument("-n", "--name", action="store", nargs=1, dest="name", required=True, 
                        help="the name of the k8singress or k8singress.")
    parser.add_argument("-t", "--type", action="store", nargs=1, choices=['k8singress', 'kongingress'],
                        dest="type",  
                        required=True,
                        default="ingress",
                        help="the TYPE of kubernetesingress.")
    parser.add_argument("-c", "--expose-ingress-class", action="store", nargs=1, dest="ingress_class", required=False, 
                        help="the ingress class of when gen k8singress.")
    parser.add_argument("-f", "--rawfile", action="store", nargs=1, dest="rawfile", required=False, 
                        help="the ingress yaml when gen ingress from k8singress or kongingress.")
    parser.add_argument("-i", "--image-url", action="store", nargs=1, dest="image_url", required=False, 
                        help="the docker IMAGE when gen k8singress from image.")
    parser.add_argument("-d", "--dns-suffix", action="store", nargs=1, dest="dns_suffix", required=False, 
                        help="the suffix dns when gen k8singress from image.")
    args = parser.parse_args()
    
    
    name = args.name[0]  
    if args.type[0] == "k8singress":
        if args.ingress_class is  None:
            print "--expose-ingress-class is required when gen %s" % (args.type[0])
            raise ValueError('param need ')
        if args.rawfile is None and args.image_url is None:
            print "--image-url or --rawfile must provided only one when gen %s" % (args.type[0])
            raise ValueError('param need ')
        if (args.rawfile is not None) and (args.image_url is not None):
            print "--image-url or --rawfile must provided when gen %s" % (args.type[0])
            raise ValueError('param need ')
        if args.rawfile is not None:
            ingr = gen_k8singress_from_file(args.rawfile[0], name, args.ingress_class[0])
            yaml.dump(ingr, os.sys.stdout, default_flow_style=False)
            return
        if args.image_url is not None:
            if args.dns_suffix is None:
                print"--dns-suffix must provided when gen %s"
                raise ValueError('param need ')
            image_info = docker_image_inspect(args.image_url[0])
            ingr = gen_k8singress_from_image(image_info, name, args.ingress_class[0], args.dns_suffix[0])
            yaml.dump(ingr, os.sys.stdout, default_flow_style=False)
    elif args.type[0] == "kongingress":
        if args.rawfile is not None:
            ingr = gen_kongingress_from_file(args.rawfile[0], name)
            yaml.dump(ingr, os.sys.stdout, default_flow_style=False)
            return
        if args.rawfile is None: 
            ingr = gen_kongingress_default(name)
            yaml.dump(ingr, os.sys.stdout, default_flow_style=False)     
    else:
        parser.print_help()
if __name__ == '__main__':
    main()


