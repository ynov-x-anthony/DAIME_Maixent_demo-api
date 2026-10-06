FROM node:22-alpine

COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY server.js db.js ./

EXPOSE 3000

CMD ["node", "server.js"]