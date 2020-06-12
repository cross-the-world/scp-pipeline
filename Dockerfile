FROM alpine:latest

LABEL "maintainer"="Scott Ng <thuongnht@gmail.com>"
LABEL "repository"="https://github.com/cross-the-world/scp-pipeline"
LABEL "version"="1.0.0"

LABEL "com.github.actions.name"="scp-pipeline"
LABEL "com.github.actions.description"="Pipeline: scp"
LABEL "com.github.actions.icon"="copy"
LABEL "com.github.actions.color"="gray-dark"

RUN apk update && \
  apk add ca-certificates && \
  apk add --no-cache openssh-client openssl openssh sshpass && \
  apk add --no-cache --upgrade bash openssh sshpass && \
  rm -rf /var/cache/apk/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]