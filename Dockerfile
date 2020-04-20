FROM centos:7
ARG KUBE_VERSION=v1.15.7
ARG HELM2_VERSION=v2.12.2
ARG HELM3_VERSION=v3.0.2
ARG GIT_VERSION=2.24.1
ARG NODE_VERSION=v10.16.2
ARG MAVEN_VERSION=3.6.3
ARG GO_VERSION=1.14.1

RUN sed -i 's/enabled=1/enabled=0/' /etc/yum/pluginconf.d/fastestmirror.conf \
 && sed -i 's/mirrorlist/#mirrorlist/' /etc/yum.repos.d/*.repo \
 && sed -i 's|#\(baseurl.*\)mirror.centos.org/centos/$releasever|\1mirrors.ustc.edu.cn/centos/$releasever|' /etc/yum.repos.d/*.repo

# add {src,artifact build/container} toolchain
#gitlab runner
#RUN curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh | bash \
# && yum install -y --nogpgcheck gitlab-runner
COPY s2erunner/runner/secrets/gitlab-runner/gitlab-runner.repo /etc/yum.repos.d/gitlab-runner.repo
RUN yum install -y --nogpgcheck gitlab-runner epel-release \
 && sed -e 's|^metalink=|#metalink=|g' \
         -e 's|^#baseurl=https\?://download.fedoraproject.org/pub/epel/|baseurl=https://mirrors.ustc.edu.cn/epel/|g' \
         -i.bak /etc/yum.repos.d/epel.repo \
 && yum install -y ansible \
 && yum install -y sudo \
 && echo "gitlab-runner ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

VOLUME ["/etc/gitlab-runner", "/home/gitlab-runner"]
## native C/C++ toolchain
RUN yum install -y vim bash  bash-completion wget unzip curl ca-certificates tzdata jq openssh-client \
  && yum groupinstall -y 'Development Tools' 'Legacy UNIX Compatibility' \
  && yum install -y  openssl-devel zlib-devel
# jdk
RUN yum install -y java-1.8.0-openjdk-devel
# maven
RUN mkdir -p /root/ts \
 && wget  -P /root/ts https://mirror.azure.cn/apache/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
 && tar -xvf /root/ts/apache-maven-${MAVEN_VERSION}-bin.tar.gz -C /opt \
 && mkdir -p /root/.m2 \
 && cp /opt/apache-maven-${MAVEN_VERSION}/conf/settings.xml /root/.m2/settings.xml \
 && ln -sf /root/.m2/settings.xml /opt/apache-maven-${MAVEN_VERSION}/conf/settings.xml \
 && rm -rf /root/ts
# npm https://github.com/nodesource/distributions
RUN mkdir -p /root/ts \
 && wget  -P /root/ts https://npm.taobao.org/mirrors/node/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.gz\
 && tar -xvf /root/ts/node-${NODE_VERSION}-linux-x64.tar.gz -C /opt \
 && rm -rf /root/ts

# python3
RUN yum install -y python3-devel python3-pip python3-setuptools  yamllint
# golang
RUN wget -P /root/ts https://mirror.azure.cn/go/go${GO_VERSION}.linux-amd64.tar.gz \
 && tar -xvzf /root/ts/go${GO_VERSION}.linux-amd64.tar.gz -C /opt \
 && rm -rf /root/ts
# docker
RUN yum install -y yum-utils device-mapper-persistent-data lvm2 \
 && yum-config-manager --add-repo  https://download.docker.com/linux/centos/docker-ce.repo \
 && yum install -y docker-ce docker-compose
# git
RUN mkdir -p /root/ts \
 && yum install -y  openssl-devel zlib-devel curl-devel expat-devel gettext-devel \
 && wget  -P /root/ts "http://mirrors.ustc.edu.cn/kernel.org/software/scm/git/git-${GIT_VERSION}.tar.gz" \
 && tar -xvzf /root/ts/git-${GIT_VERSION}.tar.gz -C /root/ts \
 && make -j2 prefix=/usr/local install -C /root/ts/git-${GIT_VERSION} \
 && rm -rf /root/ts

# add offical deploy tools, k8s relate
RUN mkdir -pv /root/.m2 /root/.docker /root/.kube /s2e

# kubernetes client
RUN wget http://mirror.azure.cn/kubernetes/kubectl/${KUBE_VERSION}/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && wget  http://mirror.azure.cn/kubernetes/helm/helm-${HELM2_VERSION}-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm2 \
    && chmod +x /usr/local/bin/helm2 \
    && wget  http://mirror.azure.cn/kubernetes/helm/helm-dev-v3-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm3 \
    && chmod +x /usr/local/bin/helm3 \
    && ln -sf /usr/local/bin/helm2 /usr/local/bin/helm \
    && yum install -y nginx \
    && sed -i 's@/usr/share/nginx/html;@/s2e;@' /etc/nginx/nginx.conf

# andriod
RUN mkdir -p /root/ts  \
    &&  wget  -P /root/ts  https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip \
    && cd /root/ts \
    && mkdir -p /opt/android \
    && unzip  -qq sdk-tools-linux-4333796.zip -d /opt/android \
    && echo 'Y'|/opt/android/tools/bin/sdkmanager  "build-tools;29.0.3" > sdkmanager.log\
    && echo 'Y'|/opt/android/tools/bin/sdkmanager "platform-tools" "platforms;android-29" >> sdkmanager.log \
    && rm -rf /root/ts
# gradle
RUN mkdir -p /root/ts \
    &&  wget  -P /root/ts  https://downloads.gradle-dn.com/distributions/gradle-6.2.2-all.zip \
    && cd /root/ts \
    && mkdir -p /opt/gradle \
    && unzip  -qq gradle-6.2.2-all.zip -d /opt/gradle \
    && rm -rf /root/ts

# gitlab cli
RUN  pip3 install --index-url https://mirrors.aliyun.com/pypi/simple/ --upgrade python-gitlab

#metricd server
COPY s2erunner/metricbeat/secrets/filebeat/elastic.repo                 /etc/yum.repos.d/elastic.repo
RUN yum install -y elasticsearch-7.6.2 kibana-7.6.2 logstash-7.6.2 filebeat-7.6.2 \
 && perl -ni -e 's/sysctl/echo sysctl/g;print' /etc/init.d/elasticsearch
# jira ... atlassian cli
# atlassian cli https://marketplace.atlassian.com/search?query=bob%20swift%20cli
# https://bobswift.atlassian.net/wiki/spaces/ACLI/pages/710705369/Docker+Image+for+CLI
ARG ACLI=atlassian-cli-9.1.1
RUN mkdir -p /root/ts \
 &&  wget  -q -O /opt/${ACLI}.zip  https://marketplace.atlassian.com/download/plugins/org.swift.atlassian.cli/version/9110 \
 && unzip /opt/${ACLI}.zip -d /opt \
 && rm /opt/${ACLI}.zip \
 && ln -sf  /root/jira/acli.properties /opt/${ACLI}/acli.properties \
 && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash

# cloud cli aliyun, tencent cloud
ADD https://aliyuncli.alicdn.com/aliyun-cli-linux-latest-amd64.tgz /opt/aliyun-cli-linux-latest-amd64.tgz
RUN tar -xvf /opt/aliyun-cli-linux-latest-amd64.tgz -C /usr/local/bin && rm -f /opt/aliyun-cli-linux-latest-amd64.tgz \
 && pip3 install --index-url https://mirrors.cloud.tencent.com/pypi/simple  coscmd tccli

#rancher cli
ARG RANCHER_VER=v2.3.1
ADD https://releases.rancher.com/cli2/${RANCHER_VER}/rancher-linux-amd64-${RANCHER_VER}.tar.gz  /opt/rancher-linux-amd64-${RANCHER_VER}.tar.gz
RUN tar -xvf /opt/rancher-linux-amd64-${RANCHER_VER}.tar.gz -C /opt \
 && rm /opt/rancher-linux-amd64-${RANCHER_VER}.tar.gz

 # redis
 RUN mkdir -p /root/ts \
     &&  wget  -P /root/ts  http://mirror.azure.cn/redis/releases/redis-5.0.8.tar.gz \
     && cd /root/ts \
     && tar -xf redis-5.0.8.tar.gz \
     && cd redis-5.0.8 \
     && make install && rm -rf /root/ts

# mail cli, font, 
RUN yum install -y wqy-microhei-fonts mailx expect initscripts

# let fetch ci/cd template via http://localhost
COPY nginx/default.conf                       /etc/nginx/default.d/
COPY s2erunner/runner/secrets/gitlab-runner/config.toml /etc/gitlab-runner/config.toml
COPY s2erunner/runner/secrets/profile.d/env.sh /etc/profile.d/env.sh
COPY s2erunner/runner/secrets/maven/settings.xml        /root/.m2/settings.xml
COPY s2erunner/runner/secrets/docker/config.json        /root/.docker/config.json
COPY s2erunner/runner/secrets/k8s/                      /root/.kube
COPY s2erunner/runner/secrets/email/mail.rc             /etc/mail.rc
COPY s2erunner/runner/secrets/jira/acli.properties      /root/jira/acli.properties
COPY s2erunner/runner/secrets/rancher/cli2.json           /root/.rancher/cli2.json
COPY s2erunner/runner/secrets/s2ectl/config.yaml         /root/.s2ectl/config.yaml

COPY s2erunner/metricbeat/secrets/filebeat/filebeat.yml      /etc/filebeat/filebeat.yml
COPY s2emetricd/secrets/elasticsearch/elasticsearch.yml      /etc/elasticsearch/elasticsearch.yml
COPY s2emetricd/secrets/kibana/kibana.yml                    /etc/kibana/kibana.yml
COPY s2emetricd/secrets/logstash                             /etc/logstash

# cicd logic
COPY s2ectl /s2ectl
COPY s2e    /s2e
COPY docker /docker

RUN cd /s2ectl;bash build.sh
RUN yum -y update \
 && yum clean all \
 && rm -rf /var/cache/yum \
 && rm -rf /root/ts \
 && chmod -R +x /docker/ /s2e/


ENV PATH="/s2e/custom/tools:/s2e:/opt/andriod/tools/bin:/opt/${ACLI}:/opt/rancher-${RANCHER_VER}:/opt/apache-maven-${MAVEN_VERSION}/bin:/opt/node-${NODE_VERSION}-linux-x64/bin:/opt/gradle/gradle-6.2.2/bin:/opt/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ENV LANG=en_US.UTF-8
ENV RUNNER_S2I_VERSION=2
RUN echo "PATH=${PATH}" >> /etc/profile.d/env.sh
EXPOSE 8888
ENTRYPOINT ["/docker/docker-entrypoint.sh"]
