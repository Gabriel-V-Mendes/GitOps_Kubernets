FROM nginx:alpine

# Copia o código da aplicação para o NGINX
COPY src/ /usr/share/nginx/html/

# Healthcheck para Kubernetes probes
HEALTHCHECK --interval=30s --timeout=3s \
    CMD wget -qO- http://localhost/ || exit 1

EXPOSE 80
