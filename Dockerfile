# Version: 1.0.0
# Node.js LTS: 22.x (EOL: April 2027)
# Debian: bookworm (EOL: ~2028)
FROM debian:bookworm-slim

LABEL org.opencontainers.image.source="https://github.com/shommey/dockerized-quartz"
LABEL org.opencontainers.image.description="Dockerized Quartz static site generator"
LABEL org.opencontainers.image.licenses="ISC"

WORKDIR /usr/src/app

# Install Node.js, Nginx, git, and inotify-tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl apprise gnupg2 ca-certificates lsb-release inotify-tools nginx git apache2-utils && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY /scripts /usr/src/app/scripts
RUN chmod +x /usr/src/app/scripts/*

# Copy node server
COPY server.js /usr/src/app/
COPY package.json /usr/src/app/
COPY package-lock.json /usr/src/app/

RUN npm ci --omit=dev

# Copy docs that will serve as an example vault content if no vault volume provided
COPY /docs /vault

# Expose port 80 for Nginx
EXPOSE 80

# Create Nginx config for serving the static files
RUN rm /etc/nginx/sites-enabled/default
COPY nginx.conf /etc/nginx/nginx.conf
RUN cp -R /etc/nginx/ /etc/nginx_default/

# Ensure directories exist for Nginx to serve static files and logs
RUN mkdir -p /usr/share/nginx/html /var/log/nginx && chown -R www-data:www-data /usr/share/nginx/html

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

CMD ["/bin/sh", "-c", "/usr/src/app/scripts/bootstrap.sh"]
