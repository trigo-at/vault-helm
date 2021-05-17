FROM centos
RUN yum install jq -y
RUN mkdir /app
COPY oc-bin /app/oc-bin
RUN chmod +x /app/oc-bin
COPY renew-token.sh /app/renew-token.sh
RUN chmod +x /app/renew-token.sh
COPY vault-unsealer.yaml /app/vault-unsealer.yaml
WORKDIR /app
CMD ["/bin/bash", "-c", "/app/renew-token.sh" ]