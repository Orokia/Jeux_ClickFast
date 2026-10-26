
# Étape 1 : installer les dépendances
FROM node:24-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm install

# Étape 2 : image de production
FROM node:24-alpine AS production

ENV NODE_ENV=production

WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev && npm cache clean --force

COPY server.js ./

USER node

EXPOSE 3000

CMD ["npm", "start"]
