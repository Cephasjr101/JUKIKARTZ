# --- Dependencies stage (cached layer) ---
FROM node:20-slim AS deps
WORKDIR /app
ENV NODE_ENV=development
RUN npm install -g npm@11 --silent
COPY package.json package-lock.json ./
# npm install (not ci) uses less memory; prefer-offline reuses layer cache.
RUN npm install --include=dev --no-audit --no-fund --loglevel=error --prefer-offline

# --- Build stage ---
FROM node:20-slim AS build
WORKDIR /app
ENV NODE_ENV=development
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

# --- Runtime stage ---
FROM node:20-slim
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3000
COPY package.json ./
# runtime.env holds the platform credentials (same content as .env, which is
# excluded from Docker build contexts as a hidden file — copied in as .env).
COPY runtime.env ./.env
COPY --from=build /app/dist ./dist
EXPOSE 3000
CMD ["node", "dist/boot.js"]
