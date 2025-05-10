# 1. Build & test stage: installs code and (optionally) tests it
FROM node:16-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
# If you have any tests, you can run: RUN npm test

# 2. Runtime stage: copy only what’s needed to run the app
FROM node:16-alpine
WORKDIR /app
COPY --from=build /app ./
EXPOSE 8080
CMD ["node", "dist/index.js"]  # adjust path if your entry is different
