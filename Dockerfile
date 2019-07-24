FROM  dtzar/helm-kubectl:2.12.2 AS kubectl
#ARG SHELL_IMG_BASE=nginx:alpine-perl
#FROM ${SHELL_IMG_BASE}

RUN  cat /etc/apk/repositories \
    && echo "https://mirrors.ustc.edu.cn/alpine/v3.8/main/" > /etc/apk/repositories \
    && apk update \
    && apk add --no-cache bash nginx  bash-completion  perl wget curl ca-certificates tzdata jq git python3\
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && rm -rf /var/cache/apk/*

RUN pip3 install kubernetes python-gitlab


COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY helm-maker /helm-maker

#https://hub.docker.com/r/dtzar/helm-kubectl/tags
#COPY --from=kubectl /usr/local/bin/kubectl /helm-maker/cicd
#COPY --from=kubectl /usr/local/bin/helm /helm-maker/cicd

ENV PATH=/helm-maker/cicd:/helm-maker/script/helm-gen:/helm-maker/script/k8s-exporter:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN chmod -R +x /helm-maker/cicd/ /helm-maker/script/helm-gen /helm-maker/script/k8s-exporter\
    && echo "${SHELL_IMG_BASE} "

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
