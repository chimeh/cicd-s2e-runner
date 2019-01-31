# helm-release-tool
helm-release-tool 是一个K8S的服务导出工具，及 helm chart 自动化生成工具。

通过Kubernetes API, 获取K8S一个Namespace的各微服务的 `image版本, image 环境变量配置, container port`等信息生成一个目录。
根据这个目录，自动生成各个微服务的helm chart 。用于快速重建一个项目

helm-release-tool 有以下特点:
* 支持外部中间件
* 支持服务覆盖原有的entrypoint
* 支持服务具备默认的环境变量
* 支持服务环境变量覆盖与新增加
* 所有微服务的部署配置放在统一的单个valuesfile `values-release-apps.yaml`
* 每个服务的镜像环境变量拆分两部分, 可配置的`values-release-apps.yaml`与固定的`charts/{XXX}/files/env.txt`

# NS 导出成helm chart 命令
```aidl
# 确认 helm 工具可以连接K8S
helm init
# 删除 k8s-ns-apps-export.sh 导出的NS的 TXT树
rm -rf export-*
# 删除 mk-rc-txt2helm.sh  生成的helm chart
rm -rf icev3-*
#利用工具导出NS的TXT树,包含了每个服务的img/env/服务名等关键信息
bash  ./helm-maker/script/k8s-exporter/k8s-ns-apps-export.sh  ice-v3-demo
# 根据需要修改导出的TXT树, 比如修改某些服务的env配置/mg版本
# 获取NS的TXT树的目录名
export_tree=`find . -maxdepth 1  -name export*`
# 将NS的TXT树转换成单个helm chart
bash  ./helm-maker/script/helm-gen/mk-rc-txt2helm.sh ${export_tree} icev3
```

# 目录结构
```
.
├── helm-maker             K8S一个NameSpace的helm 生成工具目录
│   ├── generic            微服务的基础generic helm chart
│   ├── infra-middleware   中间件的helm
│   └── script             工具脚本, script/
└── README.md
```

# generic chart, 派生helm chart 文件说明
以下是
```aidl
.
└── my-nginx
    ├── Chart.yaml
    ├── files
    │   ├── env.txt 该文件提供my-nginx的Docker image的环境变量配置
    │   ├── override-entrypoint.sh <可选> 该文件存在会变成deployment的command 覆盖默认ENTRYPOINT
    │   └── initdata/ 该目录下存在的文件都将以volume挂入容器/cfg/initdata 
    ├── OWNERS
    ├── templates 来源于generic/xxx-generic-chart/templates的generic templates
    │   ├── configmap.yaml
    │   ├── deployment.yaml
    │   ├── _helpers.tpl
    │   ├── ingress-kong-internal.yaml
    │   ├── ingress-kong-public.yaml
    │   ├── initialization-configmap.yaml
    │   ├── NOTES.txt
    │   └── service.yaml
    └── values-single.yaml 本服务单独部署的valuesfile
```
#  配置注入的ENTRYPOINT要求
每个镜像的Dockerfile里指定的entrypoint需要包含以下脚本，支持环境变量注入
```aidl
mkdir -p /cfg/
mkdir -p /logs/
if [ -f /cfg/env.txt ]; then
    echo "###/cfg/env.txt mounted"
    set -a # automatically export all variables
    . /cfg/env.txt
    set +a
    echo "###import  $(wc -l /cfg/env.txt) env vars from /cfg/env.txt done"
else
    echo "###/cfg/env.txt not found!"
fi

if [ -z ${HOSTNAME} ];then
    HOSTNAME=no-name-service
fi


K8S_NS_FILE="/var/run/secrets/kubernetes.io/serviceaccount/namespace"
if [ -f ${K8S_NS_FILE} ];then
K8S_NS=`head -n 1 ${K8S_NS_FILE}`
else
K8S_NS="cant-get-ns"
fi
SVC_NAME=`echo ${K8S_NS}.${HOSTNAME} | rev | cut -d'-'  -f 3- | rev`

PPAGENT=`find /pp-agent/pinpoint-bootstra* |head -n 1`
if [[ -n ${PPAGENT} ]];then
  PINPOINT_OPTS="-javaagent:${PPAGENT} -Dpinpoint.agentId=${HOSTNAME:0:23} -Dpinpoint.applicationName=${SVC_NAME}"
fi

JAVA_OPTS=""
JAVA_OPTS="${JAVA_OPTS} ${PINPOINT_OPTS} -XX:+UseG1GC -XX:G1ReservePercent=20 -Xloggc:/logs/gc.log -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=5 -XX:GCLogFileSize=2M -XX:-PrintGCDetails -XX:+PrintGCDateStamps -XX:-PrintTenuringDistribution "

# default JAVA_OPTS, you can RESET its value, use JAVA_OPTS="YOU-NEW-VALUE" in /cfg/env.txt" 
# default JAVA_OPTS, you can APPEND its value, use JAVA_OPTS="${JAVA_OPTS} YOU-APPEND-VALUE" in /cfg/env.txt" 
echo "###default JAVA_OPTS=${JAVA_OPTS}"
echo '###JAVA_OPTS, you can RESET its value, use JAVA_OPTS="YOU-NEW-VALUE" in /cfg/env.txt"'
echo '###JAVA_OPTS, you can APPEND its value, use JAVA_OPTS="${JAVA_OPTS} YOU-APPEND-VALUE" in /cfg/env.txt" '
```
