FROM ghcr.io/cirruslabs/flutter:3.44.0 AS build

WORKDIR /app

ARG API_BASE_URL=""

# Dependency metadata is copied first so Docker can reuse the pub cache layer.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web --release --no-web-resources-cdn \
    --dart-define=API_BASE_URL=${API_BASE_URL}

FROM caddy:2-alpine AS runtime

COPY Caddyfile /etc/caddy/Caddyfile
COPY --from=build /app/build/web /srv

EXPOSE 8080

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
