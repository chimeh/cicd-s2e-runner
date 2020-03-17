0.0.1

  - This reverts commit 0a388b66a0462a680bb58c958a7d52f02b273cb7

Fri, Mar 13 2020 11:37:43  

## 特性

开发人员特性
* 开发人员零配置，使用简单，快速上手；
* 自动构建artifact，提交触发；
* 自动部署一个或多个环境；
* 一键跨环境流转；
* 自动生成域名；
* 自动RELEASE版本管理；
* 自动通知；
* 自动汇总测试报告；
devops 人员特性


## 设计指导原则
简单
评价标准，一句话说清楚CICD的流程
* 针对开发人员使用简单
* 针对devops人员维护简单
快速
* 新建项目能快速建立CICD

## 思路
提供默认
*  源码没有Dockerfile，使用默认Dockerfile
*  源码没有entrypoint 提供默认entrypoint

* CICD 过程检测分支模型规范
* CICD 一键merge 代码
## 编译自动化
提交代码后自动检测源码语言类型，并构建

## artifact 入库自动化【可选】

## 静态检查自动化
提交代码后自动检测源码类型，并构建

## docker 镜像构建自动化

## docker 镜像入库自动化

## 部署自动化


##设计思路
### 项目仓库与环境组织设计
一个项目的代码全部组织在一个【源码namespace】gitlab group  
一个项目分配一个专属【执行器namespace】gitlab runner
一个项目分配一个专属【镜像namespace】harbor namespace
一个项目分配一个专属【k8s namespace】kubernetes namespace

### 一个gitlab project 需要部署到多个项目环境问题

#### 对应成单个kubernetes集群多个namespaces

#### 对应成多个kubernetes集群的多个namespaces



### 一个

类似于阿里巴巴aone的
多特性分支集成，CICD 实现设计
.gitlab-ci include localhost ci yaml
stage1~stage2~stage3
在stage1 检测说有feature/分支，生成所有这些分支的merge manual按钮，
用helm渲染成呈现成job yaml，
通过stage2 include 去触发复负责人选择哪些feature分支要merge到一起并做CI，并CD到开发环境


单分支模型
生产环境必须从master分支部署；master分支不全是随时可部署的，部署进过生产环境的在master上打一个tag；

用 tag latest/prod 始终追踪生产环境部署状态
用 tag latest/uat 始终追踪 UAT 环境状态，该tag 在master上打
用 tag latest/test 始终追踪测试环境状态，该tag 可在非master上打
用 tag latest/dev  始终追踪开发环境状态，该tag 可在非master上打
tags 集合 release/20200302-1809-${CI_PROJECT_NAME} 跟踪进去过生产环境的集合；


测试环境：
1.  runner里配置测试负责人邮件，有开发CD到测试环境，通知测试人员；



生产环境：
1. 运行环境配置 env.txt 
2. 部署进UAT环境时，merge进master，之后有一个manual 进PRD过程，确认后，会对源码打tag，同时会把docker image的url 推送进PRD的对应的configmap，该configmap
记录所有进去过生产环境的docker image
3. author.txt 记录部署到生产环境镜像的提交人；可以写一个服务，自动检测该服务健康，不健康则向
该负责人发送邮件



需要的gitlab 特性，在gitlab-runner 里对git repotories进行write操作（如git push）
https://gitlab.com/gitlab-org/gitlab/issues/35067 Make pipeline permissions more controllable and flexible
https://stackoverflow.com/questions/40122780/push-files-to-gitlab-ci-via-ci-runner


自动通知：
代码提交者邮件GITLAB_USER_EMAIL 在环境中流转，并且对服务一一映射，监控系统可以利用这个信息通知；

构件报告、测试报告汇总；充分利用CI_PAGES_URL 功能；

充分利用gitlab page 功能测试报告

统计生产次数
统计测试次数


runner 弄一个WEB页面，
把配置过程放到WEB，配置数据可以放到数据库里或者K8S的secrets里；
弄成一键部署；
docker run
然后就可以通过WEB配置