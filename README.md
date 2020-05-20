# 简介

cicd-s2e-runner 是二次封装的容器化gitlab runner镜像，集成一系列命令行工具，包括原生 CI 工具，原生CD工具，云平台工具，以及s2i CD 工具。

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
##

# cicd-s2e-runner 安装包说明