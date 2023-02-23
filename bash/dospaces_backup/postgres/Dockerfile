FROM docker-registry.phaseiilabs.com/go-do:1.0.0 as godo
COPY . .

FROM postgres:15
WORKDIR /root/
COPY --from=godo /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=godo /root/go-do .
COPY . .
RUN apt-get update && apt-get install -y curl
CMD [ "/bin/bash", "exit.sh" ]
