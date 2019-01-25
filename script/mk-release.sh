#!/bin/bash
THIS_SCRIPT=$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0})

RCNAME=release-$(date +%Y%m%d-%H.%M.%S)
vaule_filename=value-release-${RCNAME}.yaml
requirement_filename=requirements.yaml
defaultversion=$(date +%Y.%m.%d%H%M%S)
if [ $# -lt 1 ];then
  echo "useage: $0 namespace"
  exit 1;
fi
kubectl cluster-info
SRC_NS=$1
kubectl get ns ${SRC_NS}
if [ $? -ne 0 ];then
  echo "NS ${SRC_NS} no exist"
  exit 2;
fi
mkdir -p ${RCNAME}/charts
cat >> ${RCNAME}/Chart.yaml <<EOF
name: icev3-depend
version: ${RCNAME}
appVersion: 0.1
description: all icev3-dependcies
keywords:
- nextengine
- icev3-dependcies
home: https://www.nx-engine.com/
icon: https://bitnami.com/assets/stacks/postgresql/img/postgresql-stack-110x117.png
sources:
- https://www.nx-engine.com/
maintainers:
- name: Jimmy Huang
  email: jimagile@gmail.com
engine: gotpl
EOF
MWARE="redis|kafka|solr|elasticsearch|hbase|mongo|mysql|strimzi-cluster-operator|pvc|zookeeper"

echo "##########################gen charts, and depencies"
echo  'dependencies:' > ${RCNAME}/${requirement_filename}
kubectl get -n ${SRC_NS} deployment  --no-headers |  awk '{print $1}' | egrep -v "${MWARE}" | \
while read i; do 
    name=$i
    echo "auto gen charts for ${SRC_NS}/${name}"
    img=`kubectl get -n ${SRC_NS} deployment $i  -o=jsonpath='{.spec.template.spec.containers[0].image}'`
    cp -rf  $(dirname ${THIS_SCRIPT} )/../icev3-xxx-generic ${RCNAME}/charts/$name
    kubectl get -n ${SRC_NS} cm $name -o=jsonpath='{.data.env\.txt}' >${RCNAME}/charts/$name/files/env.txt
    perl -ni -e "s/^name:.+/name: ${name}/g;print" ${RCNAME}/charts/$name/Chart.yaml
    perl -ni -e "s/^version:.+/version: ${defaultversion}/g;print" ${RCNAME}/charts/$name/Chart.yaml
    perl -ni -e "s/^icev3-xxx-generic/$name/g;print" ${RCNAME}/charts/$name/values.yaml 
    perl -ni -e "s@image:.+@image: $img@g;print"  ${RCNAME}/charts/$name/values.yaml 
    echo "dependcies"
cat >> ${RCNAME}/${requirement_filename} <<EOF
- name: ${name}
  version: ~${defaultversion}
  repository: "file://charts/${name}"
EOF
done

echo "##########################gen value file"
echo 'global:
  rc-fullname: false
  ingress:
    internal:
      annotations-ingress-class: kong-ingress-internal
      domain: okd.cd
    public:
      annotations-ingress-class: kong-ingress-public
      domain: nx-code.com' > ${RCNAME}/${vaule_filename}
      
MWARE="redis|kafka|solr|elasticsearch|hbase|mongo|mysql|strimzi-cluster-operator|pvc|zookeeper"

kubectl get -n ${SRC_NS} deployment  --no-headers |  awk '{print $1}' | egrep -v "${MWARE}" | \
while read i; do 
    name=$i
    img=`kubectl get -n ${SRC_NS} deployment $i  -o=jsonpath='{.spec.template.spec.containers[0].image}'`
cat >> ${RCNAME}/${vaule_filename} <<EOF
${name}:
  replicaCount: 1
  ingress:
    internal: 
      host: {}
    public: 
      enabled: true
      host: {}
  service:
    type: LoadBalancer
    ports:
      - 80
      - 8080
  image: $img
  env.txt: |
    
EOF
done
