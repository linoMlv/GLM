FROM golang:1.26-bookworm

WORKDIR /app

# Copie du code source
COPY . .

# Compilation des binaires Go et création du fichier SQLite initial
RUN go mod init zai-api 2>/dev/null || true && \
    go mod tidy && \
    go build -o zai-api -trimpath -ldflags="-s -w" . && \
    go build -o token-collector -trimpath -ldflags="-s -w" ./cmd/token-collector && \
    touch tokens.sqlite

# Installation automatique du driver Playwright, de Chromium et des dépendances système
RUN go run github.com/mxschmitt/playwright-go/cmd/playwright@v0.6201.1 install --with-deps

EXPOSE 3001

CMD ["/app/zai-api"]
