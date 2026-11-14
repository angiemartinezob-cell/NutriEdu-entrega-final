# Etapa 1: compilar TypeScript
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY tsconfig*.json ./
COPY src ./src
RUN npm run build

# Etapa 2: imagen de ejecución (solo dependencias de producción)
FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --omit=dev
COPY --from=build /app/dist ./dist
COPY db ./db
COPY docs ./docs
COPY public ./public
USER node
EXPOSE 3000
# Aplica migraciones, carga la semilla (si la base está vacía) e inicia la API.
CMD ["sh", "-c", "node dist/infrastructure/adapters/output/persistence/postgres/migrate.js && node dist/infrastructure/adapters/output/persistence/postgres/seed.js && node dist/main.js"]
