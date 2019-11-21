FROM gitlab/gitlab-runner:alpine
ARG KUBE_VERSION=v1.15.0
ARG HELM_VERSION=v2.12.2

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories \
   && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
   && apk update 

ENV PATH='/s2e:/s2e-default:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
RUN echo 'export PATH=/s2e:/s2e-default:${PATH}' > /etc/profile.d/0-path.sh 
# add {src,artifact build/container} toolchain   
RUN apk add --no-cache bash  bash-completion wget curl ca-certificates tzdata jq openssh-client vim \
    && apk add --no-cache git \
    && apk add --no-cache maven openjdk8 \
    && apk add --no-cache npm \
    && apk add --no-cache python3 python2 py2-pip \
    && pip3 install --index-url='https://mirrors.aliyun.com/pypi/simple' kubernetes python-gitlab PyYAML requests \
    && apk add --no-cache go \
    && apk add --no-cache perl \
    && apk add --no-cache coreutils gcc g++ make \
    && apk add --no-cache docker \
    && rm -rf /var/cache/apk/*



# add offical deploy tools, k8s relate
RUN mkdir -pv /root/.m2 /root/.docker /root/.kube /s2e-default

RUN  wget -q https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && wget -q https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm

COPY s2e    /s2e-default

COPY default-secrets/gitlab-runner/config.toml /etc/gitlab-runner/config.toml
COPY default-secrets/gitlab-runner/profile.d/env.sh /etc/profile.d/env.sh
COPY default-secrets/maven/settings.xml /root/.m2/settings.xml
COPY default-secrets/docker/config.json /root/.docker/config.json
COPY default-secrets/k8s/               /root/.kube
