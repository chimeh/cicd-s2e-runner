FROM  dtzar/helm-kubectl:2.12.2 AS kubectl
#ARG SHELL_IMG_BASE=nginx:alpine-perl
#FROM ${SHELL_IMG_BASE}

RUN  cat /etc/apk/repositories \
    && echo "https://mirrors.ustc.edu.cn/alpine/v3.8/main/" > /etc/apk/repositories \
    && apk update \
    && apk add --no-cache bash nginx  bash-completion  perl wget curl ca-certificates tzdata jq git python3\
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && rm -rf /var/cache/apk/*

RUN pip3 install --index-url='https://mirrors.aliyun.com/pypi/simple' kubernetes python-gitlab


COPY s2e /s2e
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf /etc/nginx/conf.d/default.conf


ENV PATH=/s2e:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
WORKDIR /

RUN chmod -R +x /s2e \
    && echo "${SHELL_IMG_BASE} "

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
