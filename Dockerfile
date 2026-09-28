# --- Étape 1 : Compilation ---
FROM golang:1.26-alpine AS builder

ENV GOTOOLCHAIN=auto
WORKDIR /app

# Copie du code source
COPY . .

# Compilation de zai-api et création du fichier tokens.sqlite vide
RUN go mod init zai-api 2>/dev/null || true && \
    go mod tidy && \
    CGO_ENABLED=0 GOOS=linux go build -o zai-api -trimpath -ldflags="-s -w" . && \
    CGO_ENABLED=0 GOOS=linux go build -o token-collector -trimpath -ldflags="-s -w" ./cmd/token-collector && \
    touch tokens.sqlite

# --- Étape 2 : Image d'exécution ---
FROM alpine:latest

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

# Copie des fichiers compilés et du fichier SQLite
COPY --from=builder /app/zai-api /app/
COPY --from=builder /app/token-collector /app/
COPY --from=builder /app/tokens.sqlite /app/

EXPOSE 3001

CMD ["/app/zai-api"]
