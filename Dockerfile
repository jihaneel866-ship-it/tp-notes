
FROM node:16-alpine AS deps

# Mise à jour des paquets Alpine
RUN apk update && apk upgrade --no-cache

# Mise à jour de npm pour corriger les vulnérabilités
RUN npm install -g npm@12.2.2

WORKDIR /app

COPY package.json package-lock.json ./

# Installation des dépendances de production uniquement
RUN npm ci --omit=dev


FROM node:16-alpine

# Mise à jour des paquets Alpine
RUN apk update && apk upgrade --no-cache

# Mise à jour de npm
RUN npm install -g npm@12.2.2

ENV NODE_ENV=production

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY server.js ./

# Exécution avec un utilisateur non-root
USER node

EXPOSE 3000

# Vérification de l'état de l'application
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "server.js"]

