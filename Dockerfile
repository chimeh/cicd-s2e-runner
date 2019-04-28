ARG SHELL_IMG_BASE=alpine:3.8
FROM ${SHELL_IMG_BASE}

RUN  cat /etc/apk/repositories \
    && echo "https://mirrors.ustc.edu.cn/alpine/v3.8/main/" > /etc/apk/repositories \
    && apk update \
    && apk add --no-cache bash  bash-completion  perl wget curl ca-certificates tzdata jq\
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
        && rm -rf /var/cache/apk/* 

    
COPY helm-maker /helm-maker


RUN chmod +x /helm-maker/cicd/* \
    && echo "${SHELL_IMG_BASE} "
    
ENTRYPOINT ["/helm-maker/cicd/s2i"]

