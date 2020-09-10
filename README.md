# 简介

cicd-s2e-runner 是二次封装的容器化gitlab-runner/action-runner/jenkins-agent镜像，集成一系列命令行工具，包括原生 CI 工具，原生CD工具，云平台工具，以及s2i CD 工具。

# 特性
- 基于CentOS；
- 原生 CI 命令行工具；
  - 集成了主流编译运行环境，支持c/c++(make/gcc/binutils), java(openjdk, maven), go, python2（pip2）, python3（pip3）等
- 原生 CD 命令行工具；
    - 集成了容器化编译部署cli，docker，kubernetes(kubectl/helm)。
- 公有云 命令行工具；
    - 集成了阿里云命令行 aliyun;
    - 集成了腾讯云命令行 tccli coscmd；
- 源码 命令行工具;
    - git 命令行；
    - gitlab 命令行；
- s2i CD 命令行工具；
    - 集成了环境变量注入工具 s2ectl;
    - 集成了开箱即用的cicd命令行工具 s2i;
    
# runner 设计思路
![cicd-s2e-runner-composition](https://gitee.com/chimeh/jim-lfs/raw/master/pic/cicd-s2e-runner-composition.png)
## ci 自动构建设计思路
根据源码，提取语言特征，判断 java，go，nodejs等，调用对应构建命令，存在Dockerfile则调用docker build
## cd 自动部署设计思路
根据源码，取name，解析Dockerfile等，以及注入进runner的环境变量，自动生成 helm value.yaml 
部署目的地由kubectl配置决定；
参考 [s2i 实现](./s2e/s2i)
参考 [helm chart 模板实现](./s2e/generic/xxx-generic-chart/templates)
参考 [value.yaml 自动生成实现 k8s-app-import ](./s2e/k8s-app-import)
## cd 自动访问设计思路
根据源码，取name，解析Dockerfile等，以及注入进runner的环境变量，自动生成 helm value.yaml 
参考 [s2i 实现](./s2e/generic/xxx-generic-chart/templates/ingress-public.yaml)
* s2i 的 usage
```shell
  usage:
  A cicd tool, from src to artifact, to docker img, deploy into kubernetes:
  I. default do all action(artifact,docker,deploy):
  s2i /path/to/srctop

  II. only do specify action:
  s2i /path/to/srctop [ analysis|artifact|docker|deploy|deploy-update-blue ]

    1. only do artifact
    s2i /path/to/srctop artifact

    2. only do docker build push
    export DOCKER_REPO=harbor.benload.com
    export DOCKER_NS=bu5
    s2i /path/to/srctop docker

    3. only do kubernetes deploy
    export K8S_KUBECONFIG=/root/.kube/config
    export K8S_NS_SUFFIX=-dev
    export K8S_NS=default
    export K8S_DOMAIN_INTERNAL=benload.cn
    export K8S_DOMAIN_PUBLIC=bu5-dev.tx
    export INGRESS_INTERNAL_ENABLED=1
    export INGRESS_PUBLIC_ENABLED=1
    export INGRESS_CLASS_INTERNAL=nginx
    export INGRESS_CLASS_PUBLIC=nginx
    s2i /path/to/srctop deploy

  III. do exec cmd:
  s2i /path/to/rundir exec wrappercmd [...]
    1. do ls on /root directory
    s2i /root ls
```
# 使用
* 下载 cicd-s2e-runner，解压

* 启动runner
```shell
docker-compose up -d 
```
* 登陆runner容器 shell
```shell
docker-compose exec runner /bin/bash
```
* java CI demo：生成 jar, Docker Img
```shell
cd /root/democode/cicd-java-refer
s2i . 
```
* nodejs CI demo，生成 jar, Docker Img
```shell
cd /root/democode/cicd-nodejs-refer
s2i . 
```
## 跟gitlab 一起使用
* [注册runner](https://git.nx-code.com/help/ci/runners/README#registering-a-shared-runner)到 gitlab server

```shell
gitlab-runner register --non-interactive --name s2erunner --executor shell --url https://git.gitlab.com --registration-token 123123dafeafeQ-ZyXgLmb
```
* 使用简单版流水线 .gitlab-ci.yml

只支持单kubernetes部署，复制以下内容到 .gitlab-ci.yml
```cookie
#s2i:1
stages:
  - s2i
s2i:
  stage: s2i
  script:
     - s2i .
```
* 使用进阶版流水线 .gitlab-ci.yml

支持多kubernetes部署，支持多kubernetes蓝绿部署
```cookie
# 请查看
```
## s2i 运行系统命令
s2i 可以
```shell
#例子
s2i . exec ls
```

# cicd-s2e-runner 安装包简要说明
1. docker-compose.yaml 本runner的容器部署文件，docker-compose 方式
2. runner/secrets 目录， runner里各个cmd 工具的配置，挂载进容器里
3. templates 目录， CI、CD过程中用到的默认模板
4. runner/tools 目录， cmd 目录挂载进容器，在容器里环境变量 PATH 最前
```text
s2erunner/
├── democode
│   └── cicd-java-refer
├── docker-compose.yaml
└── runner
    ├── secrets
    │   ├── acli
    │   │   └── acli.properties
    │   ├── cloud-aliyun
    │   │   └── README.md
    │   ├── cloud-tencent
    │   │   └── README.md
    │   ├── docker
    │   │   └── config.json
    │   ├── email
    │   │   └── mail.rc
    │   ├── gitlab
    │   ├── gitlab-runner
    │   │   ├── config.toml
    │   │   └── gitlab-runner.repo
    │   ├── jira
    │   │   ├── acli.properties
    │   │   └── README.md
    │   ├── k8s/.kube
    │   ├── maven
    │   │   └── settings.xml
    │   ├── profile.d
    │   │   └── env.sh
    │   ├── rancher
    │   │   └── cli2.json
    │   └── s2ectl
    │       └── config.yaml
    ├── templates
    │   ├── dockerfile
    │   │   └── Dockerfile
    │   └── gitlab
    │       └── merge-request-template.md
    └── tools
        └── your-tool.sh
```
