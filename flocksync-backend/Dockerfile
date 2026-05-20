FROM node:26-slim
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
# write service account from env at container start (see entrypoint script)
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
EXPOSE 5050
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["node", "server.js"]