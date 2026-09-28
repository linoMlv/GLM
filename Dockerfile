FROM golang:1.26-bookworm

# Installation des utilitaires système (util-linux fournit la commande 'script' pour le TTY)
RUN apt-get update && apt-get install -y --no-install-recommends \
    util-linux \
    ca-certificates \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copie du code source
COPY . .

# Compilation des deux binaires Go
RUN go mod init zai-api 2>/dev/null || true && \
    go mod tidy && \
    go build -o zai-api -trimpath -ldflags="-s -w" . && \
    go build -o token-collector -trimpath -ldflags="-s -w" ./cmd/token-collector

# Installation de Playwright, Chromium et des dépendances
RUN go run github.com/mxschmitt/playwright-go/cmd/playwright@v0.6201.1 install --with-deps

# Création du script d'entrée avec injection automatique des réponses
RUN echo '#!/bin/sh' > /app/entrypoint.sh && \
    echo 'echo "=== 1/2 : Génération des jetons (1500/batch, 9 batches, parallel=3) ==="' >> /app/entrypoint.sh && \
    echo 'printf "1500\n9\ny\n3\n" | script -q -c "/app/token-collector" /dev/null || true' >> /app/entrypoint.sh && \
    echo 'echo "=== 2/2 : Démarrage de ZAI API ==="' >> /app/entrypoint.sh && \
    echo 'exec /app/zai-api' >> /app/entrypoint.sh && \
    chmod +x /app/entrypoint.sh

EXPOSE 3001

ENTRYPOINT ["/app/entrypoint.sh"]
