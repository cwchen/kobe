FROM golang:1.14-alpine as stage-build
LABEL stage=stage-build
WORKDIR /build/kobe
ARG GOARCH

ENV GO111MODULE=on
ENV GOOS=linux
ENV GOARCH=$GOARCH
ENV CGO_ENABLED=0

RUN  apk update \
  && apk add git \
  && apk add make
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN make build_server_linux GOARCH=$GOARCH

FROM alpine:3.13.4

RUN echo > /etc/apk/repositories && echo -e "https://dl-cdn.alpinelinux.org/alpine/latest-stable/main\nhttps://dl-cdn.alpinelinux.org/alpine/latest-stable/community" >> /etc/apk/repositories && apk update && apk upgrade

RUN apk add sshpass \
    && apk add ansible \
    && apk add py3-pip \
    && apk add rsync \
    && apk add openssl \
    && pip3 install netaddr \
    && pip3 install pywinrm

RUN rm -rf /usr/lib/libzstd.so.1.4.5

RUN mkdir /root/.ssh  \
    && touch /root/.ssh/config \
    && echo -e "Host *\n\tStrictHostKeyChecking no\n\tUserKnownHostsFile /dev/null" > /root/.ssh/config

COPY --from=stage-build /build/kobe/dist/etc /etc/
COPY --from=stage-build /build/kobe/dist/usr /usr/
COPY --from=stage-build /build/kobe/dist/var /var/

RUN echo 'kobe-server' >> /root/entrypoint.sh

VOLUME ["/var/kobe/data"]

EXPOSE 8080

CMD ["sh","/root/entrypoint.sh"]
