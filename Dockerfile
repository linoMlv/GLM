FROM golang:1.26-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . .

RUN go mod init zai-api 2>/dev/null || true && \
    go mod tidy && \
    go build -o zai-api -trimpath -ldflags="-s -w" . && \
    go build -o token-collector -trimpath -ldflags="-s -w" ./cmd/token-collector

RUN go run github.com/mxschmitt/playwright-go/cmd/playwright@v0.6201.1 install --with-deps

EXPOSE 3001

# Garde le conteneur actif indéfiniment
CMD ["tail", "-f", "/dev/null"]
