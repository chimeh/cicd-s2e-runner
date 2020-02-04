## 设计指导原则
简单
评价标准，一句话说清楚CICD的流程
* 针对开发人员使用简单
* 针对devops人员维护简单
快速
* 新建项目能快速建立CICD


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

