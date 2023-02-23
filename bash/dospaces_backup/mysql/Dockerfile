FROM docker-registry.phaseiilabs.com/go-do:1.0.0 as godo
COPY . .

FROM ubuntu:18.04
WORKDIR /root/
COPY --from=godo /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=godo /root/go-do .
RUN apt-get update && apt-get install -y mysql-client curl
COPY . .
CMD [ "/bin/bash", "exit.sh" ]
