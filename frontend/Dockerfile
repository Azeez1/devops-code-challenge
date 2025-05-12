# 1. Build stage: installs code and produces static files
FROM node:16-alpine AS build

# ▶︎ accept a build‑arg and expose it as an env var for CRA
ARG REACT_APP_API_URL
ENV REACT_APP_API_URL=${REACT_APP_API_URL}

WORKDIR /app
COPY package*.json ./
RUN npm ci

# copy all your source in; CRA will pick up process.env.REACT_APP_API_URL
COPY . .
RUN npm run build

# 2. Serve stage: uses Nginx to serve your built site
FROM nginx:stable-alpine

# copy in the built static files (with correct API URL baked in)
COPY --from=build /app/build /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
