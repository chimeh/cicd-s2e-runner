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
