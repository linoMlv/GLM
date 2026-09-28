# --- Étape 1 : Build des binaires Go & génération de la base ---
FROM golang:1.26-alpine AS builder

ENV GOTOOLCHAIN=auto
WORKDIR /app

# Copie des sources
COPY . .

# 1. Initialisation du module et installation des dépendances
# 2. Compilation de l'outil token-collector
# 3. Compilation du serveur zai-api
# 4. Exécution initiale de token-collector pour créer tokens.sqlite
RUN go mod init zai-api && \
    go mod tidy && \
    CGO_ENABLED=0 GOOS=linux go build -o token-collector -trimpath -ldflags="-s -w" ./cmd/token-collector && \
    CGO_ENABLED=0 GOOS=linux go build -o zai-api -trimpath -ldflags="-s -w" . && \
    ./token-collector

# --- Étape 2 : Image d'exécution minimale ---
FROM alpine:latest

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

# Copie des binaires et de la base de données générée
COPY --from=builder /app/zai-api /app/zai-api
COPY --from=builder /app/token-collector /app/token-collector
COPY --from=builder /app/tokens.sqlite /app/tokens.sqlite

EXPOSE 3001

# Lancement sécurisé : régénère la BDD si elle est absente puis lance zai-api
CMD ["/bin/sh", "-c", "if [ ! -f /app/tokens.sqlite ]; then /app/token-collector; fi && /app/zai-api"]
