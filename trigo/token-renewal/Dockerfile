FROM centos
RUN yum install jq -y
RUN mkdir /app
COPY renew-token.sh /app/renew-token.sh
COPY vault-unsealer.yaml /app/vault-unsealer.yaml
COPY oc-bin /app/oc-bin
WORKDIR /app
RUN chmod +x /app/renew-token.sh
RUN chmod +x /app/oc-bin
CMD ["/bin/bash", "-c", "/app/renew-token.sh" ]