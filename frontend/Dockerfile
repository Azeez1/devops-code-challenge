# 1. Build stage: installs code and produces static files
FROM node:16-alpine AS build

# ─── Inject API URL at build time ───────────────────────────────────────────
ARG REACT_APP_API_URL
# Expose the build‐arg as an env var so CRA will inline it
ENV REACT_APP_API_URL=${REACT_APP_API_URL}

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
# CRA will read process.env.REACT_APP_API_URL here
RUN npm run build

# 2. Serve stage: uses Nginx to serve your built site
FROM nginx:stable-alpine
COPY --from=build /app/build /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
