# s2e
是基于Docker、Kubernetes 技术的 CICD 工具集
包括以下内容

| 变量                 |  默认值       建议       | 
| -----------------    |  ---------------------   | 
| s2i                  | 从一个 src 到 artfact、docker image 并部署到多个kubernetes的工具     | 
| k8s        | nexus 地址  建议用默认值 | 
| SONAR_ADDR           | SONAR 地址  建议用默认值 | 
| ENABLE_SONAR         | 1           建议用默认值 | 
| ARTIFACT_DEPLOY      | 0           建议用默认值 | 

## s2i
```shell
s2i /path/to/srctop [ analysis|artifact|docker|deploy ]
```
## 

# cicd-java-refer 示例
本示例给其他java微服务提供一个范例，
这个范例举例说明一个java工程
* 如何支持CICD(s2i)
* 如何支持健康检查


# s2i
## 什么是s2i
s2i 是source to image的缩写，是一段实现CICD逻辑的工具脚本。
s2i 可以完成以下工作：
* java 工程 artifact 构建
* deploy到 artifact 仓库
* 打docker image
* 推送进docker image 仓库
* 自动部署到 K8S 容器平台
* 给部署的服务生成域名

## s2i对java project 的要求
java project 需要满足以下条件，才能支持s2i
* project name（本工程project name为cicd-java-refer）要求要点：
 字母开头,不含点，全小写，即满足正则表达式：r'[a-z\d-]{,63}([a-z\d-]{,63})*'
* 规范的java源码目录结构
* pom.xml 只有一个，并且在第一级目录
* pom.xml jar包名<finalName>${project.artifactId}-app</finalName>
* Dockerfile 只有一个，并且在第一级目录
* .gitlab-ci.yml 只有一个，并且在第一级目录
* docker/ 目录只有一个，并且在第一级目录
* Dockerfile 里EXPOSE的端口与代码的LISTEN端口一致
```
cicd-java-refer/
├── docker
│   ├── docker-entrypoint.sh
│   ├── healthy.sh
│   ├── initdata
│   │   ├── init.sh
│   │   └── readme.txt
│   └── ready.sh
├── Dockerfile
├── pom.xml
├── README.md
├── ReleaseNote.md
├── src
│   └── main
│       ├── java
│       └── test
│       └── resources
```

## 我的java project 如何支持s2i
假设java project 工程名称叫 xxx，完成以下步骤支持s2i
1. 拷贝 docker/ 整个目录，到 xxx 第一级目录
2. 拷贝 .gitlab-ci.yml，到 xxx 第一级目录
3. 拷贝 Dockerfile，到 xxx 第一级目录，可能需要修改里面EXPOSE
4. java 源代码组织 src/main/java，src/main/resource, src/main/resource 规范
5. master 分支默认CI生成docker img，并且会自动部署
6. bugfix hotfix feature 只会CI生成docker img，不会自动部署
7. 不需要自动部署 请在.gitlab-ci.yml 设置 export K8S_AUTOCD=0

## s2i 做了什么事情，对java程序的处理过程
### s2i 的build 过程
1. s2i 在第一级目录检测pom.xml;
2. pom.xm 存在, 判定为java 工程，执行java project的CICD逻辑;
3. 在第一级目录, 运行 mvn clean package，构建出jar包
4. s2i 在第一级目录检测Dockerfile, 
5. 检测到Dockerfile，在第一级目录执行 docker build
6. docker build 的 image name使用 project name
7. docker build 的tag 使用{分支名称，commit hash, pom.xml里的project.version } 组成
### s2i 的 deploy 过程
* s2i 默认不会把 jar 包 deploy 到 nexus 仓库
* s2i 默认会把 docker image 推送到 docker 仓库
* s2i 默认会把 docker image 部署到 K8S 容器平台
* s2i deploy 的nexus仓库/docker仓库/K8S 容器平台位置由执行s2i的gitlab-runner指定
##  我要控制 s2i 执行的过程 
可以通过环境变量影响 s2i 的执行过程
### s2i 提供的控制接口
| 变量              |  默认值   |   建议 | 变量说明                  | 
| ----------------- |  ---      |  ---   | --------------------------- |
| NEXUS_REPO        | nexus 地址 | 建议用默认值 | nexus 地址 `mvn build deploy 用到` | 
| NEXUS_RELEASE     | nexus 地址 | 建议用默认值 | nexus 地址 `mvn build deploy 用到` | 
| SONAR_ADDR        | SONAR 地址 | 建议用默认值 | sonar 扫描结果存放地址 | 
| ENABLE_SONAR      | 1          | 建议用默认值 | 非零时会进行静态源码分析 扫描 | 
| ARTIFACT_DEPLOY   | 0          | 建议用默认值 | 控制artifact是否入库，非零时s2i 会`mvn deploy` | 
| DOCKER_BUILD      | 1          | 建议用默认值 | 控制是否进行docker img build | 
| DOCKER_REPO       | docker image 仓库地址     | 建议用默认值 | docker 仓库地址，docker push的地址 | 
| DOCKER_NS         | docker image 的命名空间   | 建议用默认值 |  docker 仓库命名空间， docker push到的命名空间 | 
| K8S_AUTOCD        | 1          | 建议用默认值 | 非零时 s2i 会自动部署到K8S | 
| K8S_NS            | 项目 k8s namespace | 建议用默认值     | 非零时 s2i 会自动部署到K8S | 
| K8S_SVCNAMES      | 服务名列表 | 建议用默认值     | 一个IMAGE 部署多个服务份时使用 |
| K8S_DOMAIN_INTERNAL  | 服务名列表 | 建议用默认值     | 自动生成内网域名的域 |
| K8S_DOMAIN_PUBLIC    | 服务名列表 | 建议用默认值     | 自动生成公网域名的域 |


### 控制 s2i 执行的例子1
以下.gitlab-ci.yaml 完成java 构建，并且mvn deploy 推送进NEXUS仓库，不部署
```yaml
stages:
  - s2i
s2i:
  stage: s2i
  script:
     - env
     - export ARTIFACT_DEPLOY=1 # 1 进行mvn deploy
     - export ENABLE_SONAR=1 # 0 不启用SONAR，1 启用SONAR
     - export K8S_AUTOCD=0   # 0 不自动部署，1 自动部署
     - s2i .
  only:
    - master           # master 会出image，自动部署
    - /^rc.*$/         # 构建，会出image，不部署
    - /^bugfix.*$/     # 构建，会出image，不部署
    - /^hotfix.*$/     # 构建，会出image，不部署
    - /^feature.*$/    # 构建，会出image，不部署
  except:
    - /^dev.*$/        # 不构建，不会出image，不部署
```
### 控制 s2i 执行的例子2
   以下.gitlab-ci.yaml 完成java 构建，打成docker image，推送进docker仓库，并自动部署
   ```yaml
   stages:
     - s2i
   s2i:
     stage: s2i
     script:
        - env
        - s2i .
  only:
    - master           # master 会出image，自动部署
    - /^rc.*$/         # 构建，会出image，不部署
    - /^bugfix.*$/     # 构建，会出image，不部署
    - /^hotfix.*$/     # 构建，会出image，不部署
    - /^feature.*$/    # 构建，会出image，不部署
  except:
    - /^dev.*$/        # 不构建，不会出image，不部署
   ```
### 控制 s2i 执行的例子3
以下.gitlab-ci.yaml 完成java 构建，打成docker image，推送进docker仓库，并自动部署，服务名为xxx
```yaml
stages:
  - s2i
s2i:
  stage: s2i
  script:
     - env
     - export K8S_SVCNAMES=xxx
     - s2i .
  only:
    - master           # master 会出image，自动部署
    - /^rc.*$/         # 构建，会出image，不部署
    - /^bugfix.*$/     # 构建，会出image，不部署
    - /^hotfix.*$/     # 构建，会出image，不部署
    - /^feature.*$/    # 构建，会出image，不部署
  except:
    - /^dev.*$/        # 不构建，不会出image，不部署
```
### 控制 s2i 执行的例子4
以下.gitlab-ci.yaml 完成java 构建，打成docker image，推送进docker仓库，并自动部署，部署两份 服务名分别为 xxx  yyy
```yaml
stages:
  - s2i
s2i:
  stage: s2i
  script:
     - env
     - export K8S_SVCNAMES=xxx yyy
     - s2i .
  only:
    - master           # master 会出image，自动部署
    - /^rc.*$/         # 构建，会出image，不部署
    - /^bugfix.*$/     # 构建，会出image，不部署
    - /^hotfix.*$/     # 构建，会出image，不部署
    - /^feature.*$/    # 构建，会出image，不部署
  except:
    - /^dev.*$/        # 不构建，不会出image，不部署
```
## s2i 的工作原理
s2i 是source to image的缩写，是一段实现CICD逻辑的工具脚本，
s2i 的实现的原理是，自动检测源码语言类型，利用多种信息，把源码构建，打docker，推送仓库，部署到K8S等做到自动化。
信息来源于以下方面：
* gitlab里有project的信息，比如project name, commit hash，等
* gitlab-runner 里有nexus仓库/docker仓库/K8S 容器平台 信息和构建工具
* project 仓库里有一些特征信息，比如java程序有pom.xml，nodejs有package.json 
* 人为对project 源代码的组织做一些规范
比如，
project name可以用于docker image 的image name，还可以用于 k8s里部署的service name，还可以用于生成域名
Dockerfile 里的 EXPOSE 可以用于生成 k8s里部署的service，用于生成服务域名
## s2i 什么时候执行?
s2i 会在代码有提交的时候触发执行，或者手动使用gitlab的pipline触发执行

# 健康检查
一个应用启动后，就有健康与不健康
健康检查可能是
* 进程在运行
* 自身
## 健康检查的维度
* 就绪状态检查(readiness)
  已就绪，表示可以接受流量了
* 存活状态检查(liveness)
多次存活状态检查失败会导致该服务重启
## 健康检查接口实现

| 健康检查的维度    |  实现接口   |  接口返回值   | 不健康动作 |
| ----------------- |  ---        |  ---          |  -------- |
| 就绪检查        | /docker/ready.sh  | exit 0 表示健康, 否则不健康    | 关闭访问流量 |
| 存活检查        | /docker/liveness.sh   | exit 0 表示健康, 否则不健康    | 重启该服务   |

### 使用 spring-boot-starter-actuator 实现健康检查举例
### /docker/liveness.sh 
```bash
#!/bin/sh
# liveness.sh checker

# checkout port is open
nc -zv localhost 8080
rv=$?
exit ${rv}
```

### /docker/ready.sh
```bash
#!/bin/sh
# readiness checker

curl -f localhost:8080/actuator/health
rv=$?
exit ${rv}
```

###
 * s2i 支持从cicd 页面自助点击推送到test,推送到prod, test 和 prod，只做第一次deploy
 * s2i 对进入生产的image 进行retag
 * 支持rancher cli 命令行式部署
 * 如何支持 kubectl和helm等版本的演进，尤其是template的对kubernetes版本的兼容
