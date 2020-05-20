ARG IMG_BASE=openjdk:8-jre-alpine
FROM ${IMG_BASE}

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.cloud.tencent.com/g' /etc/apk/repositories \
    && apk add --no-cache bash wget curl ca-certificates tzdata jq\
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    
COPY docker /docker
COPY target/*.jar /



RUN chmod +x /docker/docker-entrypoint.sh \
    && echo "${IMG_BASE} "
    
ENTRYPOINT ["/docker/docker-entrypoint.sh"]

EXPOSE 8080
