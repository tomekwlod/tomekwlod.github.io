# REMEMBER TO ENABLE BUILDKIT!
# DOCKER_BUILDKIT=1

FROM golang:1.17-alpine as go
WORKDIR /app
LABEL maintainer="Tomasz Wlodarczyk <tomek.wlod@gmail.com>"
COPY go.mod .
COPY go.sum .
RUN apk --no-cache add ca-certificates
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o go-do
ENTRYPOINT echo "'go' entrypoint Dockerfile (you should not be seing this)"


FROM ubuntu:18.04 as mysql
WORKDIR /root/
COPY --from=go /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=go /app/go-do .
RUN apt-get update && apt-get install -y mysql-client curl
COPY . .
CMD [ "/bin/bash", "exit.sh" ]


FROM postgres:15 as postgres
WORKDIR /root/
COPY --from=go /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=go /app/go-do .
COPY . .
CMD [ "/bin/bash", "exit.sh" ]
